import 'package:shared_preferences/shared_preferences.dart';

/// Wrapper sederhana untuk penyimpanan lokal berbasis SharedPreferences.
/// Dipakai untuk cache data non-rahasia dan antrean sinkronisasi.
class LocalStorage {
  LocalStorage._();

  static final LocalStorage instance = LocalStorage._();

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<String?> getString(String key) async {
    return (await _prefs).getString(key);
  }

  Future<void> setString(String key, String value) async {
    await (await _prefs).setString(key, value);
  }

  Future<bool> remove(String key) async {
    return (await _prefs).remove(key);
  }
}
