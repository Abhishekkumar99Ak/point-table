import '../models/pointcalc_models.dart';

abstract final class LobbyParser {
  static final _slotHeader = RegExp(
    r'^(?:slot|team|squad|group|#)\s*0?(\d{1,2})\s*[:.)\-–]?\s*(.*)$',
    caseSensitive: false,
  );
  static final _numberedHeader = RegExp(r'^0?(\d{1,2})[.)\-:]\s*(.*)$');
  static final _standaloneNumber = RegExp(r'^0?(\d{1,2})$');
  static final _noise = RegExp(
    r'^(?:lobby|team members?|players?|player names?|slot list|room id|spectators?|ready|invite|start|match|free fire|bgmi|pubg|booyah|elimination|kills?)\b',
    caseSensitive: false,
  );

  static List<LobbySlot> parse(String recognizedText) {
    final slots = <int, LobbySlot>{
      for (var slot = 1; slot <= 12; slot++) slot: LobbySlot(slotNumber: slot),
    };
    final lines = recognizedText
        .split(RegExp(r'[\r\n]+'))
        .map(_cleanLine)
        .where((line) => line.isNotEmpty && !_noise.hasMatch(line))
        .toList();
    var currentSlot = 0;
    var markersFound = false;

    for (final line in lines) {
      final header = _parseHeader(line);
      if (header != null) {
        currentSlot = header.$1;
        markersFound = true;
        if (currentSlot < 1 || currentSlot > 12) continue;
        final suffix = header.$2;
        if (suffix.isNotEmpty) _append(slots, currentSlot, suffix);
        continue;
      }
      if (currentSlot > 0 && currentSlot <= 12) {
        _append(slots, currentSlot, line);
      }
    }

    if (!markersFound) {
      final values =
          lines.where((line) => !_standaloneNumber.hasMatch(line)).toList();
      for (var index = 0; index < values.length && index < 60; index++) {
        _append(slots, index ~/ 5 + 1, values[index]);
      }
    }

    return List.generate(12, (index) => slots[index + 1]!);
  }

  static List<LobbySlot> mapToRegisteredTeams(
    List<LobbySlot> slots,
    List<TeamCard> registeredTeams,
  ) {
    final teamsBySlot = {
      for (final team in registeredTeams)
        if (team.slotNumber != null) team.slotNumber!: team,
    };
    return slots.map((slot) {
      final exactSlot = teamsBySlot[slot.slotNumber];
      final matched = exactSlot ?? _findByName(slot.teamName, registeredTeams);
      if (matched == null) return slot;
      return slot.copyWith(
        teamName: matched.name,
        playerNames: slot.playerNames.isEmpty
            ? matched.players.map((player) => player.name).toList()
            : slot.playerNames,
      );
    }).toList();
  }

  static (int, String)? _parseHeader(String line) {
    final marked = _slotHeader.firstMatch(line);
    final numbered = marked == null ? _numberedHeader.firstMatch(line) : null;
    final match = marked ?? numbered;
    final slot = int.tryParse(match?.group(1) ?? '');
    if (slot == null || slot < 1 || slot > 12) return null;
    return (slot, (match?.group(2) ?? '').trim());
  }

  static void _append(Map<int, LobbySlot> slots, int slotNumber, String value) {
    final slot = slots[slotNumber];
    if (slot == null) return;
    final clean = _cleanLine(value);
    if (clean.isEmpty || _noise.hasMatch(clean)) return;
    if (slot.teamName.isEmpty) {
      slots[slotNumber] = slot.copyWith(teamName: clean);
      return;
    }
    if (slot.playerNames.length < 4 &&
        !slot.playerNames
            .any((player) => player.toLowerCase() == clean.toLowerCase())) {
      slots[slotNumber] =
          slot.copyWith(playerNames: [...slot.playerNames, clean]);
    }
  }

  static TeamCard? _findByName(String name, List<TeamCard> teams) {
    final normalized = name.trim().toLowerCase();
    if (normalized.isEmpty) return null;
    for (final team in teams) {
      final candidate = team.name.trim().toLowerCase();
      if (candidate == normalized ||
          candidate.contains(normalized) ||
          normalized.contains(candidate)) {
        return team;
      }
    }
    return null;
  }

  static String _cleanLine(String line) => line
      .replaceAll(RegExp(r'[|•▪◦]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'^[\s:;,.\-–]+|[\s:;,.\-–]+$'), '')
      .trim();
}
