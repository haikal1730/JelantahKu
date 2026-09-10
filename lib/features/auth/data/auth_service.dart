import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_config.dart';
import '../../../core/error/failure.dart';
import '../../../core/security/secure_storage_service.dart';
import '../domain/entities/user_role.dart';

class AuthResult {
  const AuthResult({
    required this.userId,
    required this.email,
    required this.name,
    required this.role,
    required this.isDemo,
  });

  final String userId;
  final String email;
  final String name;
  final UserRole role;
  final bool isDemo;
}

class AuthService {
  AuthService({SecureStorageService? secureStorage})
      : _storage = secureStorage ?? SecureStorageService();

  final SecureStorageService _storage;

  bool get supabaseAvailable => AppConfig.hasSupabaseConfig;
  SupabaseClient get _client => Supabase.instance.client;

  Future<AuthResult?> restoreSession() async {
    if (supabaseAvailable) {
      final user = _client.auth.currentUser;
      if (user != null) return _saveSupabaseUser(user);
    }

    // Never restore a local demo session in the real Supabase build.
    // If Supabase is not configured, the app must show login rather than
    // silently switching to a fake Warga account.
    return null;
  }

  Future<AuthResult> fromSupabaseUser(User user) => _saveSupabaseUser(user);

  Future<AuthResult> signInEmail({required String email, required String password}) async {
    _validate(email, password);
    if (!supabaseAvailable) {
      throw const ServerFailure(
        'Supabase belum dikonfigurasi. Pastikan konfigurasi --dart-define tersedia lalu jalankan ulang aplikasi.',
      );
    }
    try {
      final response = await _client.auth.signInWithPassword(
        email: email.trim(), password: password,
      );
      final user = response.user;
      if (user == null) throw const ValidationFailure('Login gagal.');
      return _saveSupabaseUser(user);
    } on AuthException catch (e) {
      throw ValidationFailure(_authMessage(e));
    }
  }

  Future<AuthResult> registerEmail({
    required String name, required String email, required String password,
  }) async {
    if (name.trim().length < 2) {
      throw const ValidationFailure('Nama minimal 2 karakter.');
    }
    _validate(email, password);
    if (!supabaseAvailable) {
      throw const ServerFailure(
        'Supabase belum dikonfigurasi. Pastikan konfigurasi --dart-define tersedia lalu jalankan ulang aplikasi.',
      );
    }
    try {
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'name': name.trim()},
      );
      final user = response.user;
      if (user == null) throw const ValidationFailure('Registrasi gagal.');
      return _saveSupabaseUser(user, fallbackName: name.trim());
    } on AuthException catch (e) {
      throw ValidationFailure(_authMessage(e));
    }
  }

  Future<AuthResult> signInGoogle() async {
    if (!supabaseAvailable) {
      throw const ServerFailure(
        'Supabase belum dikonfigurasi. Pastikan konfigurasi --dart-define tersedia lalu jalankan ulang aplikasi.',
      );
    }
    try {
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : AppConfig.supabaseRedirectUrl,
        authScreenLaunchMode: kIsWeb
            ? LaunchMode.platformDefault
            : LaunchMode.externalApplication,
      );
      // On mobile PKCE, the callback restores the session asynchronously.
      final session = _client.auth.currentSession;
      if (session?.user != null) return _saveSupabaseUser(session!.user);
      final user = _client.auth.currentUser;
      if (user != null) return _saveSupabaseUser(user);
      throw const ValidationFailure(
        'Browser Google dibuka. Selesaikan login lalu kembali ke aplikasi.',
      );
    } on AuthException catch (e) {
      throw ValidationFailure(_authMessage(e));
    } catch (e) {
      if (e is Failure) rethrow;
      throw ServerFailure('Login Google gagal: $e');
    }
  }

  Future<void> signOut() async {
    if (supabaseAvailable) await _client.auth.signOut();
    await _storage.clearSession();
  }

  Future<String?> getAccessToken() async {
    if (supabaseAvailable) return _client.auth.currentSession?.accessToken;
    return _storage.readToken();
  }

  Future<AuthResult> _saveSupabaseUser(User user, {String? fallbackName}) async {
    final name = (user.userMetadata?['name'] ??
            user.userMetadata?['full_name'] ??
            user.userMetadata?['display_name'] ??
            fallbackName ??
            user.email?.split('@').first ??
            'Pengguna JelantahKu')
        .toString();
    final token = _client.auth.currentSession?.accessToken ?? '';

    // Keep Supabase profiles.role as the single source of truth.
    // Never write a hard-coded role here, otherwise admin/owner accounts
    // would be downgraded to warga during login/session restore.
    await _client.from('profiles').upsert({
      'id': user.id,
      'name': name,
      'email': user.email,
    });

    final profile = await _client
        .from('profiles')
        .select('role, village, name')
        .eq('id', user.id)
        .maybeSingle();

    final role = UserRole.fromDatabase(profile?['role']);
    final profileName = (profile?['name'] ?? name).toString();

    await _storage.saveSession(userId: user.id, token: token);
    await _storage.saveDemoProfile(email: user.email ?? '', name: profileName);
    return AuthResult(
      userId: user.id,
      email: user.email ?? '',
      name: profileName,
      role: role,
      isDemo: false,
    );
  }

  void _validate(String email, String password) {
    final normalizedEmail = email.trim();
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

    if (normalizedEmail.isEmpty || !emailRegex.hasMatch(normalizedEmail)) {
      throw const ValidationFailure('Format email tidak valid.');
    }
    if (password.length < 6) {
      throw const ValidationFailure('Password minimal 6 karakter.');
    }
  }

  String _authMessage(AuthException e) {
    final msg = e.message.toLowerCase();

    if (msg.contains('invalid login credentials')) {
      return 'Email atau password salah.';
    }
    if (msg.contains('already registered') || msg.contains('already exists')) {
      return 'Email sudah terdaftar.';
    }
    if (msg.contains('password')) {
      return 'Password tidak memenuhi ketentuan. Detail: ${e.message}';
    }
    if (msg.contains('rate limit') || msg.contains('too many requests')) {
      return 'Terlalu banyak percobaan. Tunggu beberapa saat lalu coba lagi. Detail: ${e.message}';
    }
    if (msg.contains('signup') && (msg.contains('disabled') || msg.contains('not allowed'))) {
      return 'Registrasi Supabase sedang dinonaktifkan. Cek Authentication > Providers > Email.';
    }

    // Jangan menganggap semua error yang mengandung kata "email" sebagai
    // format email. Supabase juga memakai kata email untuk error SMTP, rate
    // limit, provider, dan konfigurasi lainnya. Tampilkan pesan aslinya agar
    // penyebab sebenarnya bisa diketahui.
    return 'Supabase: ${e.message}';
  }
}
