import '../models/pointcalc_models.dart';

abstract final class BulkTeamParser {
  static final _slotPrefix = RegExp(
    r'^(?:(?:slot|team)\s*)?0?(\d{1,2})(?:[).:\-]|\s+)\s*(.+)$',
    caseSensitive: false,
  );

  static List<TeamCard> parse(
    String source, {
    List<TeamCard> existingTeams = const [],
  }) {
    final occupiedSlots =
        existingTeams.map((team) => team.slotNumber).whereType<int>().toSet();
    final knownNames =
        existingTeams.map((team) => team.name.toLowerCase()).toSet();
    final result = <TeamCard>[];
    for (final rawLine in source.split(RegExp(r'[\r\n]+'))) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;
      final match = _slotPrefix.firstMatch(line);
      final requested = int.tryParse(match?.group(1) ?? '');
      final name = (match?.group(2) ?? line).trim();
      var slot = requested;
      if (slot == null) {
        for (var candidate = 1; candidate <= 12; candidate++) {
          if (!occupiedSlots.contains(candidate)) {
            slot = candidate;
            break;
          }
        }
      }
      if (name.isEmpty ||
          slot == null ||
          slot < 1 ||
          slot > 12 ||
          occupiedSlots.contains(slot) ||
          knownNames.contains(name.toLowerCase())) {
        continue;
      }
      occupiedSlots.add(slot);
      knownNames.add(name.toLowerCase());
      result.add(TeamCard(name: name, players: const [], slotNumber: slot));
    }
    return result;
  }
}
