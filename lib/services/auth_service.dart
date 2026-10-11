import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';

/// Menyimpan & memverifikasi ADMIN_API_KEY. Key diketik pengguna dan
/// disimpan di perangkat — tidak pernah ditulis di kode aplikasi.
class AuthService {
  static const _prefKey = 'admin_api_key';

  Future<String?> loadKey() async => (await SharedPreferences.getInstance()).getString(_prefKey);

  Future<void> saveKey(String? key) async {
    final prefs = await SharedPreferences.getInstance();
    key == null ? await prefs.remove(_prefKey) : await prefs.setString(_prefKey, key);
  }

  /// Menghapus komentar yang pasti tidak ada: API mengecek key lebih dulu,
  /// jadi 401 = key salah, 404 = key benar. Tidak ada data yang berubah.
  Future<bool> verify(String key) async {
    try {
      await ApiClient.instance.delete('/comments/999999999', apiKey: key);
      return true;
    } on ApiException catch (e) {
      if (e.statusCode == 401) return false;
      if (e.statusCode == 404) return true;
      rethrow;
    }
  }
}
