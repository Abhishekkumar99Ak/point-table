import '../models/pointcalc_models.dart';

abstract final class ScoreboardParser {
  static final _rankFirst = RegExp(
    r'^\s*(?:#\s*)?(\d{1,2})(?:st|nd|rd|th)?(?:[.)]|[\s:|\-])+(.+?)\s*$',
    caseSensitive: false,
  );
  static final _labelledKills = RegExp(
    r'(?:kill|finish|elimination)\w*\s*[:=x\-]?\s*(\d{1,3})\s*$',
    caseSensitive: false,
  );
  static final _trailingNumber = RegExp(r'\s+(\d{1,3})\s*$');
  static final _numberBeforeLabel = RegExp(
    r'(\d{1,3})\s*(?:kills?|finishes?|eliminations?)\s*$',
    caseSensitive: false,
  );
  static final _rankLabel = RegExp(
    r'^\s*(.+?)\s+(?:rank|place|position)\s*[:#]?\s*(\d{1,2})\D+(\d{1,3})\s*$',
    caseSensitive: false,
  );

  static List<ScoreEntry> parse(
    String recognizedText, {
    List<String> knownTeams = const [],
    int matchNumber = 1,
  }) {
    final entries = <ScoreEntry>[];
    final seen = <String>{};
    for (final rawLine in recognizedText.split(RegExp(r'[\r\n]+'))) {
      final line = rawLine.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (line.isEmpty) continue;
      final entry = _parseLine(line, matchNumber);
      if (entry == null || entry.placement > 12) continue;
      final team =
          _matchKnownTeam(entry.teamName, knownTeams) ?? entry.teamName;
      final key = team.trim().toLowerCase();
      if (!seen.add(key)) continue;
      entries.add(entry.copyWith(teamName: team));
    }
    entries.sort((left, right) => left.placement.compareTo(right.placement));
    return entries.take(12).toList();
  }

  static ScoreEntry? _parseLine(String line, int matchNumber) {
    final labelled = _rankLabel.firstMatch(line);
    if (labelled != null) {
      return _entry(
        labelled.group(1)!,
        labelled.group(2)!,
        labelled.group(3)!,
        matchNumber,
      );
    }
    final rank = _rankFirst.firstMatch(line);
    if (rank == null) return null;
    final placement = int.tryParse(rank.group(1)!);
    var remainder = rank.group(2)!.trim();
    if (placement == null || placement < 1 || placement > 12) return null;

    final labelledKills = _labelledKills.firstMatch(remainder);
    final int? kills;
    if (labelledKills != null) {
      kills = int.tryParse(labelledKills.group(1)!);
      remainder = remainder.substring(0, labelledKills.start).trim();
    } else {
      final numberBeforeLabel = _numberBeforeLabel.firstMatch(remainder);
      final trailing = numberBeforeLabel == null
          ? _trailingNumber.firstMatch(remainder)
          : null;
      final scoreMatch = numberBeforeLabel ?? trailing;
      if (scoreMatch == null) return null;
      kills = int.tryParse(scoreMatch.group(1)!);
      remainder = remainder.substring(0, scoreMatch.start).trim();
    }
    final team = remainder
        .replaceAll(RegExp(r'^(?:team|squad)\s+', caseSensitive: false), '')
        .replaceAll(RegExp(r'^[|:._-]+|[|:._-]+$'), '')
        .trim();
    if (team.length < 2 || kills == null) return null;
    return ScoreEntry(
      teamName: team,
      placement: placement,
      kills: kills,
      matchNumber: matchNumber,
    );
  }

  static ScoreEntry? _entry(
    String team,
    String rawPlacement,
    String rawKills,
    int matchNumber,
  ) {
    final placement = int.tryParse(rawPlacement);
    final kills = int.tryParse(rawKills);
    final cleanTeam = team.trim();
    if (placement == null ||
        placement < 1 ||
        placement > 12 ||
        kills == null ||
        cleanTeam.length < 2) {
      return null;
    }
    return ScoreEntry(
      teamName: cleanTeam,
      placement: placement,
      kills: kills,
      matchNumber: matchNumber,
    );
  }

  static String? _matchKnownTeam(String recognized, List<String> knownTeams) {
    final normalized = recognized.toLowerCase();
    for (final team in knownTeams) {
      final candidate = team.toLowerCase();
      if (candidate == normalized ||
          candidate.contains(normalized) ||
          normalized.contains(candidate)) {
        return team;
      }
    }
    return null;
  }
}
