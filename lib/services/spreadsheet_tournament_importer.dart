import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:csv/csv.dart';
import 'package:xml/xml.dart';

import '../models/pointcalc_models.dart';

abstract final class SpreadsheetTournamentImporter {
  static Tournament fromCsv(List<int> bytes, {required String name}) {
    final source = utf8.decode(bytes, allowMalformed: true);
    final rows = const CsvToListConverter(
      shouldParseNumbers: false,
      eol: '\n',
    ).convert(source);
    return fromRows(rows, name: name);
  }

  static Tournament fromXlsx(List<int> bytes, {required String name}) {
    final archive = ZipDecoder().decodeBytes(bytes);
    final worksheet = archive.findFile('xl/worksheets/sheet1.xml');
    if (worksheet == null) {
      throw const FormatException(
          'Workbook does not contain a first worksheet.');
    }
    final sharedStringsFile = archive.findFile('xl/sharedStrings.xml');
    final sharedStrings = sharedStringsFile == null
        ? const <String>[]
        : XmlDocument.parse(utf8.decode(sharedStringsFile.content as List<int>))
            .findAllElements('si')
            .map((item) =>
                item.findAllElements('t').map((text) => text.innerText).join())
            .toList();
    final document =
        XmlDocument.parse(utf8.decode(worksheet.content as List<int>));
    final rows = <List<String>>[];
    for (final row in document.findAllElements('row')) {
      final values = <int, String>{};
      var largestColumn = -1;
      for (final cell in row.findElements('c')) {
        final reference = cell.getAttribute('r') ?? '';
        final column = _columnIndex(reference);
        if (column < 0) continue;
        largestColumn = column > largestColumn ? column : largestColumn;
        final type = cell.getAttribute('t');
        final raw = cell.findElements('v').firstOrNull?.innerText ??
            cell.findAllElements('t').map((text) => text.innerText).join();
        if (type == 's') {
          final index = int.tryParse(raw);
          values[column] =
              index != null && index >= 0 && index < sharedStrings.length
                  ? sharedStrings[index]
                  : '';
        } else if (type == 'inlineStr') {
          values[column] =
              cell.findAllElements('t').map((text) => text.innerText).join();
        } else {
          values[column] = raw;
        }
      }
      rows.add(
          List.generate(largestColumn + 1, (index) => values[index] ?? ''));
    }
    return fromRows(rows, name: name);
  }

  static Tournament fromRows(List<List<Object?>> source,
      {required String name}) {
    final rows = source
        .map((row) =>
            row.map((value) => value?.toString().trim() ?? '').toList())
        .where((row) => row.any((cell) => cell.isNotEmpty))
        .toList();
    if (rows.isEmpty) throw const FormatException('The spreadsheet is empty.');

    final normalizedHeader = rows.first.map(_normalize).toList();
    final hasHeader = normalizedHeader
        .any((cell) => const {'team', 'teamname', 'squad'}.contains(cell));
    final headers = hasHeader ? normalizedHeader : const <String>[];
    final teamColumn = hasHeader
        ? _findColumn(headers, const ['team', 'teamname', 'squad'])
        : 0;
    final placementColumn = hasHeader
        ? _findColumn(headers, const ['placement', 'rank', 'position'])
        : 1;
    final killsColumn = hasHeader
        ? _findColumn(headers, const ['kills', 'finishes', 'eliminations'])
        : 2;
    final slotColumn =
        hasHeader ? _findColumn(headers, const ['slot', 'slotnumber']) : -1;
    final matchColumn = hasHeader
        ? _findColumn(headers, const ['match', 'matchnumber', 'round'])
        : -1;
    final playerColumns = <int>[
      for (var index = 0; index < headers.length; index++)
        if (RegExp(r'^player\d*$').hasMatch(headers[index])) index,
    ];
    if (teamColumn < 0)
      throw const FormatException('A Team or Squad column is required.');

    final teams = <String, TeamCard>{};
    final scores = <ScoreEntry>[];
    final rowsToRead = hasHeader ? rows.skip(1) : rows;
    for (final row in rowsToRead) {
      final teamName = _cell(row, teamColumn);
      if (teamName.isEmpty) continue;
      final slot = _integer(_cell(row, slotColumn));
      teams.putIfAbsent(
          teamName.toLowerCase(),
          () => TeamCard(
                name: teamName,
                players: playerColumns
                    .map((column) => _cell(row, column))
                    .where((player) => player.isNotEmpty)
                    .map((player) => TeamPlayer(name: player))
                    .toList(),
                slotNumber: slot != null && slot >= 1 && slot <= 12
                    ? slot
                    : _nextSlot(teams.values),
              ));
      final placement = _integer(_cell(row, placementColumn));
      final kills = _integer(_cell(row, killsColumn));
      if (placement != null || kills != null) {
        scores.add(ScoreEntry(
          teamName: teamName,
          placement: placement ?? 0,
          kills: kills ?? 0,
          matchNumber: _integer(_cell(row, matchColumn)) ?? 1,
        ));
      }
    }
    if (teams.isEmpty) throw const FormatException('No team names were found.');

    const points = PointSystem();
    final standings = scores
        .map((score) => score.copyWith(
              totalPoints: points.pointsFor(score.placement, score.kills),
            ))
        .toList();
    return Tournament(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name.trim().isEmpty ? 'Imported tournament' : name.trim(),
      pointSystem: points,
      teams: teams.values.toList(),
      standings: standings,
    );
  }

  static String _normalize(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  static int _findColumn(List<String> headers, List<String> aliases) =>
      headers.indexWhere(aliases.contains);

  static String _cell(List<String> row, int column) =>
      column >= 0 && column < row.length ? row[column] : '';

  static int? _integer(String value) =>
      int.tryParse(value.replaceAll(',', '').trim());

  static int _nextSlot(Iterable<TeamCard> teams) {
    final used = teams.map((team) => team.slotNumber).whereType<int>().toSet();
    for (var slot = 1; slot <= 12; slot++) {
      if (!used.contains(slot)) return slot;
    }
    return 0;
  }

  static int _columnIndex(String reference) {
    final letters =
        reference.replaceAll(RegExp(r'[^A-Za-z]'), '').toUpperCase();
    var index = 0;
    for (final code in letters.codeUnits) {
      index = index * 26 + code - 64;
    }
    return letters.isEmpty ? -1 : index - 1;
  }
}
