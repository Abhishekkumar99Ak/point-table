import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class AdminAccessController extends ChangeNotifier {
  String? _passcodeDigest;
  String _salt = '';
  bool _authenticated = false;

  bool get isConfigured => _passcodeDigest != null;
  bool get isAuthenticated => _authenticated;
  bool get cloudConnected => false;

  Future<void> load() async {
    try {
      final file = await _settingsFile();
      if (!await file.exists()) return;
      final contents = jsonDecode(await file.readAsString());
      if (contents is Map<String, dynamic> &&
          contents['adminDigest'] is String) {
        _passcodeDigest = contents['adminDigest'] as String;
        _salt = contents['adminSalt'] is String
            ? contents['adminSalt'] as String
            : '';
        notifyListeners();
      }
    } catch (_) {
      // A missing or unreadable local settings file starts in setup mode.
    }
  }

  Future<void> configure(String passcode) async {
    if (passcode.trim().length < 8) {
      throw ArgumentError('Use at least 8 characters for the admin passcode.');
    }
    final salt = _newSalt();
    final digest = _digest(passcode, salt);
    await _save(digest, salt);
    _passcodeDigest = digest;
    _salt = salt;
    _authenticated = true;
    notifyListeners();
  }

  bool authenticate(String passcode) {
    final valid =
        _passcodeDigest != null && _digest(passcode, _salt) == _passcodeDigest;
    if (valid) {
      _authenticated = true;
      notifyListeners();
    }
    return valid;
  }

  Future<void> changePasscode(String current, String next) async {
    if (!authenticate(current))
      throw StateError('Current passcode is incorrect.');
    if (next.trim().length < 8) {
      throw ArgumentError('Use at least 8 characters for the admin passcode.');
    }
    final salt = _newSalt();
    final digest = _digest(next, salt);
    await _save(digest, salt);
    _passcodeDigest = digest;
    _salt = salt;
    notifyListeners();
  }

  void lock() {
    _authenticated = false;
    notifyListeners();
  }

  Future<void> _save(String digest, String salt) async {
    final file = await _settingsFile();
    await file.writeAsString(
        jsonEncode({'adminDigest': digest, 'adminSalt': salt}),
        flush: true);
  }

  Future<File> _settingsFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/point_table_admin.json');
  }

  String _newSalt() => base64Url
      .encode(List<int>.generate(16, (_) => Random.secure().nextInt(256)));

  String _digest(String value, String salt) =>
      sha256.convert(utf8.encode('$salt:$value')).toString();
}
