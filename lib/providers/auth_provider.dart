import 'package:flutter/foundation.dart';

import '../services/auth_service.dart';

/// Status admin. Endpoint tulis (CRUD) hanya bisa dipakai saat [isAdmin].
class AuthProvider extends ChangeNotifier {
  final _service = AuthService();

  String? _apiKey;
  String? get apiKey => _apiKey;
  bool get isAdmin => _apiKey != null;

  Future<void> load() async {
    _apiKey = await _service.loadKey();
    notifyListeners();
  }

  /// `true` bila key diterima server.
  Future<bool> login(String key) async {
    final ok = await _service.verify(key.trim());
    if (ok) {
      _apiKey = key.trim();
      await _service.saveKey(_apiKey);
      notifyListeners();
    }
    return ok;
  }

  Future<void> logout() async {
    _apiKey = null;
    await _service.saveKey(null);
    notifyListeners();
  }
}
