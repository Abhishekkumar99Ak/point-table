import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../services/tournament_codec.dart';

@immutable
class PointSystem {
  const PointSystem({
    this.game = 'BGMI',
    this.killPoints = 1,
    this.positionPoints = const [12, 9, 8, 7, 6, 5, 4, 3, 2, 1],
    this.roundRobin = false,
  });

  final String game;
  final int killPoints;
  final List<int> positionPoints;
  final bool roundRobin;

  int pointsFor(int placement, int kills) {
    final placementPoints = placement > 0 && placement <= positionPoints.length
        ? positionPoints[placement - 1]
        : 0;
    return placementPoints + kills * killPoints;
  }

  PointSystem copyWith({
    String? game,
    int? killPoints,
    List<int>? positionPoints,
    bool? roundRobin,
  }) =>
      PointSystem(
        game: game ?? this.game,
        killPoints: killPoints ?? this.killPoints,
        positionPoints: positionPoints ?? this.positionPoints,
        roundRobin: roundRobin ?? this.roundRobin,
      );
}

@immutable
class ScoreEntry {
  const ScoreEntry({
    required this.teamName,
    required this.placement,
    required this.kills,
    this.totalPoints = 0,
    this.matchNumber = 1,
    this.slotNumber,
    this.playerKills = const [],
  });

  final String teamName;
  final int placement;
  final int kills;
  final int totalPoints;
  final int matchNumber;
  final int? slotNumber;
  final List<PlayerKill> playerKills;

  ScoreEntry copyWith({
    String? teamName,
    int? placement,
    int? kills,
    int? totalPoints,
    int? matchNumber,
    int? slotNumber,
    List<PlayerKill>? playerKills,
  }) =>
      ScoreEntry(
        teamName: teamName ?? this.teamName,
        placement: placement ?? this.placement,
        kills: kills ?? this.kills,
        totalPoints: totalPoints ?? this.totalPoints,
        matchNumber: matchNumber ?? this.matchNumber,
        slotNumber: slotNumber ?? this.slotNumber,
        playerKills: playerKills ?? this.playerKills,
      );
}

@immutable
class PlayerKill {
  const PlayerKill({required this.playerName, required this.kills});

  final String playerName;
  final int kills;
}

@immutable
class LobbySlot {
  const LobbySlot({
    required this.slotNumber,
    this.teamName = '',
    this.playerNames = const [],
  });

  final int slotNumber;
  final String teamName;
  final List<String> playerNames;

  LobbySlot copyWith({String? teamName, List<String>? playerNames}) =>
      LobbySlot(
        slotNumber: slotNumber,
        teamName: teamName ?? this.teamName,
        playerNames: playerNames ?? this.playerNames,
      );
}

@immutable
class Tournament {
  const Tournament({
    required this.id,
    required this.name,
    required this.pointSystem,
    this.teams = const [],
    this.standings = const [],
    this.lobbySlots = const [],
    this.rememberLobby = false,
  });

  final String id;
  final String name;
  final PointSystem pointSystem;
  final List<TeamCard> teams;
  final List<ScoreEntry> standings;
  final List<LobbySlot> lobbySlots;
  final bool rememberLobby;

  Tournament copyWith({
    String? name,
    PointSystem? pointSystem,
    List<TeamCard>? teams,
    List<ScoreEntry>? standings,
    List<LobbySlot>? lobbySlots,
    bool? rememberLobby,
  }) =>
      Tournament(
        id: id,
        name: name ?? this.name,
        pointSystem: pointSystem ?? this.pointSystem,
        teams: teams ?? this.teams,
        standings: standings ?? this.standings,
        lobbySlots: lobbySlots ?? this.lobbySlots,
        rememberLobby: rememberLobby ?? this.rememberLobby,
      );
}

@immutable
class TeamCard {
  const TeamCard({
    required this.name,
    required this.players,
    this.slotNumber,
    this.logoPath,
    this.tags = const [],
  });

  final String name;
  final List<TeamPlayer> players;
  final int? slotNumber;
  final String? logoPath;
  final List<String> tags;
}

@immutable
class TeamPlayer {
  const TeamPlayer({required this.name, this.photoPath});

  final String name;
  final String? photoPath;
}

class TournamentStore extends ChangeNotifier {
  final List<Tournament> _tournaments = [];
  final List<Tournament> _trash = [];
  Future<void> _pendingWrite = Future<void>.value();
  List<Tournament> get tournaments => List.unmodifiable(_tournaments);
  List<Tournament> get trash => List.unmodifiable(_trash);

  Future<void> load() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/point_table_tournaments.json');
      if (!await file.exists()) return;
      final decoded = jsonDecode(await file.readAsString());
      final storedTournaments = decoded is List
          ? decoded
          : decoded is Map<String, dynamic>
              ? decoded['tournaments'] as List? ?? const []
              : const [];
      final storedTrash = decoded is Map<String, dynamic>
          ? decoded['trash'] as List? ?? const []
          : const [];
      _tournaments
        ..clear()
        ..addAll(_decodeStored(storedTournaments));
      _trash
        ..clear()
        ..addAll(_decodeStored(storedTrash));
      notifyListeners();
    } catch (_) {
      // Keep the app usable when local storage is unavailable or malformed.
    }
  }

  Future<void> _persist() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/point_table_tournaments.json');
      final content = jsonEncode({
        'format': 'pointtable.store.v2',
        'tournaments': _tournaments.map(TournamentCodec.encode).toList(),
        'trash': _trash.map(TournamentCodec.encode).toList(),
      });
      await file.writeAsString(content, flush: true);
    } catch (_) {
      // The in-memory store remains available if the platform has no file store.
    }
  }

  List<Tournament> _decodeStored(List<dynamic> items) => items
      .map((item) => item is String ? jsonDecode(item) : item)
      .whereType<Map<String, dynamic>>()
      .map((item) =>
          TournamentCodec.fromJson(jsonEncode(item), preserveId: true))
      .toList();

  void _schedulePersist() {
    _pendingWrite = _pendingWrite.then((_) => _persist());
  }

  void add(Tournament tournament) {
    _tournaments.insert(0, tournament);
    _schedulePersist();
    notifyListeners();
  }

  void update(Tournament tournament) {
    final index = _tournaments.indexWhere((item) => item.id == tournament.id);
    if (index == -1) return;
    _tournaments[index] = tournament;
    _schedulePersist();
    notifyListeners();
  }

  void merge(List<String> ids, String mergedName) {
    final selected =
        _tournaments.where((item) => ids.contains(item.id)).toList();
    if (selected.length < 2) return;
    final merged = Tournament(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: mergedName,
      pointSystem: selected.first.pointSystem,
      teams: selected.expand((item) => item.teams).toList(),
      standings: selected.expand((item) => item.standings).toList(),
    );
    _tournaments.insert(0, merged);
    _schedulePersist();
    notifyListeners();
  }

  void delete(String id) {
    final index = _tournaments.indexWhere((tournament) => tournament.id == id);
    if (index == -1) return;
    _trash.insert(0, _tournaments.removeAt(index));
    _schedulePersist();
    notifyListeners();
  }

  void restore(String id) {
    final index = _trash.indexWhere((tournament) => tournament.id == id);
    if (index == -1) return;
    _tournaments.insert(0, _trash.removeAt(index));
    _schedulePersist();
    notifyListeners();
  }

  void permanentlyDelete(String id) {
    _trash.removeWhere((tournament) => tournament.id == id);
    _schedulePersist();
    notifyListeners();
  }

  void emptyTrash() {
    _trash.clear();
    _schedulePersist();
    notifyListeners();
  }
}
