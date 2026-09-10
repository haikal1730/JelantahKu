import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Penyimpanan terenkripsi untuk data sesi dan status monetisasi.
class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _userIdKey = 'session_user_id';
  static const _tokenKey = 'session_token';
  static const _subscriptionKey = 'subscription_active';
  static const _demoEmailKey = 'demo_email';
  static const _demoNameKey = 'demo_name';

  Future<void> saveSession({required String userId, required String token}) async {
    await _storage.write(key: _userIdKey, value: userId);
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> readUserId() => _storage.read(key: _userIdKey);

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<void> saveDemoProfile({
    required String email,
    required String name,
  }) async {
    await _storage.write(key: _demoEmailKey, value: email);
    await _storage.write(key: _demoNameKey, value: name);
  }

  Future<String?> readDemoEmail() => _storage.read(key: _demoEmailKey);

  Future<String?> readDemoName() => _storage.read(key: _demoNameKey);

  Future<void> saveSubscriptionStatus(bool active) async {
    await _storage.write(
      key: _subscriptionKey,
      value: active ? 'true' : 'false',
    );
  }

  Future<bool> readSubscriptionStatus() async {
    return (await _storage.read(key: _subscriptionKey)) == 'true';
  }

  Future<void> clearSession() async {
    await _storage.delete(key: _userIdKey);
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _demoEmailKey);
    await _storage.delete(key: _demoNameKey);
  }
}
