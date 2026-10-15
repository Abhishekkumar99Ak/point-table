import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class AccountSettingsStore {
  static const _fileName = 'point_table_account.json';

  static Future<Map<String, String>> load() async {
    try {
      final file = await _file();
      if (!await file.exists()) return {};
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<String, dynamic>) return {};
      return decoded
          .map((key, value) => MapEntry(key, value is String ? value : ''));
    } catch (_) {
      return {};
    }
  }

  static Future<void> save(Map<String, String> values) async {
    final file = await _file();
    await file.writeAsString(jsonEncode(values), flush: true);
  }

  static Future<File> _file() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_fileName');
  }
}
