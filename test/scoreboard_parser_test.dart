import 'package:flutter_test/flutter_test.dart';
import 'package:pointcalc_clone/models/pointcalc_models.dart';
import 'package:pointcalc_clone/services/scoreboard_parser.dart';
import 'package:pointcalc_clone/services/tournament_codec.dart';

void main() {
  group('ScoreboardParser', () {
    test('extracts placement, team and kills while skipping headers', () {
      final entries = ScoreboardParser.parse('''
        RANK TEAM KILLS
        1. Lunar Wolves 8
        2 Neon Five 5
        Match ended
      ''');

      expect(entries, hasLength(2));
      expect(entries.first.teamName, 'Lunar Wolves');
      expect(entries.first.placement, 1);
      expect(entries.first.kills, 8);
      expect(entries.last.teamName, 'Neon Five');
    });

    test('ignores duplicate team rows and invalid placements', () {
      final entries = ScoreboardParser.parse('''
        0 Invalid Squad 4
        1 Nova Unit 7
        2 nova unit 2
        Team name only
      ''');

      expect(entries, hasLength(1));
      expect(entries.single.teamName, 'Nova Unit');
    });
  });

  test('tournament JSON round-trips scoring rules, teams and standings', () {
    const tournament = Tournament(
      id: 'source-id',
      name: 'Night Cup',
      pointSystem: PointSystem(game: 'FreeFire', killPoints: 2, positionPoints: [10, 8], roundRobin: true),
      teams: [TeamCard(name: 'Nova', players: [TeamPlayer(name: 'Ace')])],
      standings: [ScoreEntry(teamName: 'Nova', placement: 1, kills: 4, totalPoints: 18)],
    );

    final imported = TournamentCodec.fromJson(TournamentCodec.toJson(tournament));

    expect(imported.name, tournament.name);
    expect(imported.pointSystem.game, 'FreeFire');
    expect(imported.pointSystem.pointsFor(1, 4), 18);
    expect(imported.teams.single.players.single.name, 'Ace');
    expect(imported.standings.single.totalPoints, 18);
  });
}