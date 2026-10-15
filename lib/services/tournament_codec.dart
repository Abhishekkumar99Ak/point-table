import 'dart:convert';

import '../models/pointcalc_models.dart';

abstract final class TournamentCodec {
  static Map<String, Object?> encode(Tournament tournament) => {
        'format': 'pointtable.tournament.v2',
        'id': tournament.id,
        'name': tournament.name,
        'pointSystem': {
          'game': tournament.pointSystem.game,
          'killPoints': tournament.pointSystem.killPoints,
          'positionPoints': tournament.pointSystem.positionPoints,
          'roundRobin': tournament.pointSystem.roundRobin,
        },
        'teams': tournament.teams
            .map((team) => {
                  'name': team.name,
                  'slotNumber': team.slotNumber,
                  'logoPath': team.logoPath,
                  'tags': team.tags,
                  'players': team.players
                      .map((player) => {
                            'name': player.name,
                            'photoPath': player.photoPath,
                          })
                      .toList(),
                })
            .toList(),
        'rememberLobby': tournament.rememberLobby,
        'lobbySlots': tournament.lobbySlots
            .map((slot) => {
                  'slotNumber': slot.slotNumber,
                  'teamName': slot.teamName,
                  'playerNames': slot.playerNames,
                })
            .toList(),
        'standings': tournament.standings
            .map((entry) => {
                  'teamName': entry.teamName,
                  'placement': entry.placement,
                  'kills': entry.kills,
                  'totalPoints': entry.totalPoints,
                  'matchNumber': entry.matchNumber,
                  'slotNumber': entry.slotNumber,
                  'playerKills': entry.playerKills
                      .map((player) => {
                            'playerName': player.playerName,
                            'kills': player.kills,
                          })
                      .toList(),
                })
            .toList(),
      };

  static String toJson(Tournament tournament) =>
      const JsonEncoder.withIndent('  ').convert(encode(tournament));

  static Tournament fromJson(String source, {bool preserveId = false}) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Expected a tournament object.');
    }
    final rawPoints = decoded['pointSystem'];
    if (rawPoints is! Map<String, dynamic>) {
      throw const FormatException('Tournament is missing its point system.');
    }
    final positions = rawPoints['positionPoints'];
    final rawTeams = decoded['teams'];
    final rawStandings = decoded['standings'];
    final rawLobbySlots = decoded['lobbySlots'];
    return Tournament(
      id: preserveId && decoded['id'] is String
          ? decoded['id'] as String
          : DateTime.now().microsecondsSinceEpoch.toString(),
      name: _string(decoded['name'], 'Imported tournament'),
      pointSystem: PointSystem(
        game: _string(rawPoints['game'], 'BGMI'),
        killPoints: _integer(rawPoints['killPoints'], 1),
        positionPoints: positions is List
            ? positions.map((value) => _integer(value, 0)).toList()
            : const [12, 9, 8, 7, 6, 5, 4, 3, 2, 1],
        roundRobin: rawPoints['roundRobin'] == true,
      ),
      teams: rawTeams is List
          ? rawTeams.whereType<Map<String, dynamic>>().map((team) {
              final rawPlayers = team['players'];
              return TeamCard(
                name: _string(team['name'], 'Team'),
                slotNumber: _integerOrNull(team['slotNumber']),
                logoPath: team['logoPath'] is String
                    ? team['logoPath'] as String
                    : null,
                tags: team['tags'] is List
                    ? (team['tags'] as List).whereType<String>().toList()
                    : const [],
                players: rawPlayers is List
                    ? rawPlayers
                        .whereType<Map<String, dynamic>>()
                        .map((player) => TeamPlayer(
                              name: _string(player['name'], 'Player'),
                              photoPath: player['photoPath'] is String
                                  ? player['photoPath'] as String
                                  : null,
                            ))
                        .toList()
                    : const [],
              );
            }).toList()
          : const [],
      standings: rawStandings is List
          ? rawStandings
              .whereType<Map<String, dynamic>>()
              .map((entry) => ScoreEntry(
                    teamName: _string(entry['teamName'], 'Team'),
                    placement: _integer(entry['placement'], 1),
                    kills: _integer(entry['kills'], 0),
                    totalPoints: _integer(entry['totalPoints'], 0),
                    matchNumber: _integer(entry['matchNumber'], 1),
                    slotNumber: _integerOrNull(entry['slotNumber']),
                    playerKills: entry['playerKills'] is List
                        ? (entry['playerKills'] as List)
                            .whereType<Map<String, dynamic>>()
                            .map((player) => PlayerKill(
                                  playerName:
                                      _string(player['playerName'], 'Player'),
                                  kills: _integer(player['kills'], 0),
                                ))
                            .toList()
                        : const [],
                  ))
              .toList()
          : const [],
      rememberLobby: decoded['rememberLobby'] == true,
      lobbySlots: rawLobbySlots is List
          ? rawLobbySlots.whereType<Map<String, dynamic>>().map((slot) {
              final rawNames = slot['playerNames'];
              return LobbySlot(
                slotNumber: _integer(slot['slotNumber'], 0),
                teamName: _string(slot['teamName'], ''),
                playerNames: rawNames is List
                    ? rawNames.whereType<String>().toList()
                    : const [],
              );
            }).toList()
          : const [],
    );
  }

  static String _string(Object? value, String fallback) =>
      value is String && value.trim().isNotEmpty ? value.trim() : fallback;

  static int _integer(Object? value, int fallback) =>
      value is int ? value : int.tryParse('$value') ?? fallback;

  static int? _integerOrNull(Object? value) =>
      value is int ? value : int.tryParse('$value');
}
