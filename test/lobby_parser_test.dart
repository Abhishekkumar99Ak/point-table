import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pointcalc_clone/models/pointcalc_models.dart';
import 'package:pointcalc_clone/services/lobby_parser.dart';
import 'package:pointcalc_clone/services/bulk_team_parser.dart';
import 'package:pointcalc_clone/services/scoreboard_parser.dart';
import 'package:pointcalc_clone/services/tournament_codec.dart';
import 'package:pointcalc_clone/services/spreadsheet_tournament_importer.dart';

void main() {
  test('lobby parser fills numbered slots with team and four player names', () {
    final slots = LobbyParser.parse('''
      SLOT 01
      Nova Five
      Ace
      Blaze
      Frost
      Wisp
      SLOT 02: Lunar Wolves
      Echo
      Rune
      Vale
      Kairo
    ''');

    expect(slots, hasLength(12));
    expect(slots[0].teamName, 'Nova Five');
    expect(slots[0].playerNames, ['Ace', 'Blaze', 'Frost', 'Wisp']);
    expect(slots[1].teamName, 'Lunar Wolves');
    expect(slots[1].playerNames, ['Echo', 'Rune', 'Vale', 'Kairo']);
    expect(slots[11].slotNumber, 12);
  });

  test('lobby parser maps slot allocations to registered team rosters', () {
    final mapped = LobbyParser.mapToRegisteredTeams(
      LobbyParser.parse('SLOT 03\nUnclear name'),
      const [
        TeamCard(
          name: 'Known Squad',
          slotNumber: 3,
          players: [TeamPlayer(name: 'Player A'), TeamPlayer(name: 'Player B')],
        ),
      ],
    );

    expect(mapped[2].teamName, 'Known Squad');
    expect(mapped[2].playerNames, ['Player A', 'Player B']);
  });

  test('bulk team parser assigns free slots and rejects slot/name collisions',
      () {
    final teams = BulkTeamParser.parse(
      'Occupied Slot\n01 Collision\n03: Nova Five\nNova Five\nslot 13 Invalid',
      existingTeams: const [
        TeamCard(name: 'Existing', slotNumber: 1, players: []),
      ],
    );

    expect(teams.map((team) => (team.slotNumber, team.name)).toList(), [
      (2, 'Occupied Slot'),
      (3, 'Nova Five'),
    ]);
  });

  test('scoreboard parser reads labeled elimination rows and maps team names',
      () {
    final rows = ScoreboardParser.parse(
      'RANK TEAM ELIMINATIONS\n#1 Nova 8 kills\n2nd Lunar Wolves Finishes: 6',
      knownTeams: const ['Nova Five', 'Lunar Wolves'],
      matchNumber: 3,
    );

    expect(rows.map((row) => row.teamName).toList(),
        ['Nova Five', 'Lunar Wolves']);
    expect(rows[0].teamName, 'Nova Five');
    expect(rows[0].kills, 8);
    expect(rows[0].matchNumber, 3);
    expect(rows[1].placement, 2);
    expect(rows[1].kills, 6);
  });

  test('codec persists lobby, slot and per-match player-kill corrections', () {
    const tournament = Tournament(
      id: 'persisted-id',
      name: 'Saved Lobby Cup',
      pointSystem: PointSystem(),
      rememberLobby: true,
      lobbySlots: [
        LobbySlot(slotNumber: 1, teamName: 'Nova', playerNames: ['Ace']),
      ],
      teams: [
        TeamCard(
          name: 'Nova',
          slotNumber: 1,
          logoPath: '/tmp/nova.png',
          tags: ['invited'],
          players: [TeamPlayer(name: 'Ace')],
        ),
      ],
      standings: [
        ScoreEntry(
          teamName: 'Nova',
          placement: 1,
          kills: 4,
          matchNumber: 2,
          slotNumber: 1,
          playerKills: [PlayerKill(playerName: 'Ace', kills: 4)],
        ),
      ],
    );

    final decoded = TournamentCodec.fromJson(
      TournamentCodec.toJson(tournament),
      preserveId: true,
    );

    expect(decoded.id, tournament.id);
    expect(decoded.rememberLobby, isTrue);
    expect(decoded.lobbySlots.single.playerNames, ['Ace']);
    expect(decoded.teams.single.slotNumber, 1);
    expect(decoded.teams.single.logoPath, '/tmp/nova.png');
    expect(decoded.teams.single.tags, ['invited']);
    expect(decoded.standings.single.matchNumber, 2);
    expect(decoded.standings.single.playerKills.single.kills, 4);
  });

  test('tournament store supports recoverable and permanent deletion', () {
    final store = TournamentStore();
    const event = Tournament(
        id: 'trash-me', name: 'Trash Cup', pointSystem: PointSystem());
    store.add(event);
    store.delete(event.id);
    expect(store.tournaments, isEmpty);
    expect(store.trash.single.id, event.id);
    store.restore(event.id);
    expect(store.tournaments.single.id, event.id);
    expect(store.trash, isEmpty);
    store.delete(event.id);
    store.permanentlyDelete(event.id);
    expect(store.trash, isEmpty);
  });

  test(
      'CSV importer maps team, slot, player, placement, kills and match columns',
      () {
    final tournament = SpreadsheetTournamentImporter.fromCsv(
      utf8.encode(
          'Team,Slot,Player1,Player2,Placement,Kills,Match\nNova Five,4,Ace,Blaze,1,8,2'),
      name: 'Imported Cup',
    );

    expect(tournament.name, 'Imported Cup');
    expect(tournament.teams.single.slotNumber, 4);
    expect(tournament.teams.single.players.map((player) => player.name),
        ['Ace', 'Blaze']);
    expect(tournament.standings.single.matchNumber, 2);
    expect(tournament.standings.single.totalPoints, 20);
  });

  test('XLSX importer reads inline-string worksheet cells', () {
    final archive = Archive()
      ..addFile(ArchiveFile.string(
        'xl/worksheets/sheet1.xml',
        '''<?xml version="1.0"?><worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><sheetData>
        <row r="1"><c r="A1" t="inlineStr"><is><t>Team</t></is></c><c r="B1" t="inlineStr"><is><t>Placement</t></is></c><c r="C1" t="inlineStr"><is><t>Kills</t></is></c></row>
        <row r="2"><c r="A2" t="inlineStr"><is><t>Nova Five</t></is></c><c r="B2"><v>1</v></c><c r="C2"><v>8</v></c></row>
        </sheetData></worksheet>''',
      ));
    final bytes = ZipEncoder().encode(archive);
    final tournament =
        SpreadsheetTournamentImporter.fromXlsx(bytes, name: 'XLSX Cup');

    expect(tournament.teams.single.name, 'Nova Five');
    expect(tournament.standings.single.placement, 1);
    expect(tournament.standings.single.kills, 8);
  });
}
