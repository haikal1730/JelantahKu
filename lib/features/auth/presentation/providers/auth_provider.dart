import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../data/auth_service.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/security/secure_storage_service.dart';
import '../../../../core/notifications/push_notification_service.dart';
import '../../../../core/supabase/supabase_client.dart';
import '../../../warga/presentation/providers/persistent_storage_provider.dart';
import 'user_provider.dart';

final supabaseClientProvider = Provider<SupabaseClient?>((ref) {
  if (!AppConfig.hasSupabaseConfig) return null;
  try { return Supabase.instance.client; } catch (_) { return null; }
});

final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  try {
    if (Firebase.apps.isNotEmpty) {
      return PushNotificationService(messaging: FirebaseMessaging.instance);
    }
  } catch (_) {}
  return PushNotificationService();
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(secureStorage: ref.watch(secureStorageServiceProvider));
});

sealed class AuthState { const AuthState(); }
class AuthLoading extends AuthState { const AuthLoading(); }
class AuthUnauthenticated extends AuthState { const AuthUnauthenticated(); }
class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.result);
  final AuthResult result;
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier(ref));

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this.ref) : super(const AuthLoading()) {
    _listenAuth();
    restore();
  }

  final Ref ref;

  void _listenAuth() {
    final client = ref.read(supabaseClientProvider);
    client?.auth.onAuthStateChange.listen((data) async {
      final user = data.session?.user;
      if (user == null) {
        if (state is! AuthLoading) state = const AuthUnauthenticated();
        return;
      }
      setAuthenticated(await ref.read(authServiceProvider).restoreSession() ??
          await ref.read(authServiceProvider).fromSupabaseUser(user));
    });
  }

  Future<void> restore() async {
    try {
      final result = await ref.read(authServiceProvider).restoreSession();
      state = result == null ? const AuthUnauthenticated() : AuthAuthenticated(result);
      if (result != null) {
        ref.read(userNotifierProvider.notifier).setProfile(
          id: result.userId,
          name: result.name,
          role: result.role,
        );
        _syncProfile(result);
        _initializePush(result.userId);
      }
    } catch (_) {
      state = const AuthUnauthenticated();
    }
  }

  void setAuthenticated(AuthResult result) {
    ref.read(userNotifierProvider.notifier).setProfile(
          id: result.userId,
          name: result.name,
          role: result.role,
        );
    state = AuthAuthenticated(result);
    _syncProfile(result);
    _initializePush(result.userId);
  }

  Future<void> _initializePush(String userId) async {
    try {
      await ref.read(pushNotificationServiceProvider).initialize(onToken: (token) async {
        if (!AppConfig.hasSupabaseConfig) return;
        await SupabaseService.client.from('notification_tokens').upsert({
          'user_id': userId,
          'token': token,
          'platform': 'flutter',
        }, onConflict: 'user_id,token');
      });
    } catch (_) {}
  }

  Future<void> _syncProfile(AuthResult result) async {
    if (result.isDemo || !AppConfig.hasSupabaseConfig) return;
    try {
      // Do not send role here. The database owns role assignment.
      await SupabaseService.client.from('profiles').upsert({
        'id': result.userId,
        'name': result.name,
        'email': result.email,
      });
    } catch (_) {}
  }

  Future<void> signOut() async {
    await ref.read(authServiceProvider).signOut();
    state = const AuthUnauthenticated();
  }
}
