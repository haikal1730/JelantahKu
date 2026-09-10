import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';

class SupabaseService {
  static Future<bool> initialize() async {
    if (!AppConfig.hasSupabaseConfig) return false;
    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        publishableKey: AppConfig.supabasePublishableKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  static SupabaseClient get client => Supabase.instance.client;
  static bool get isInitialized {
    try {
      return Supabase.instance.client.auth.currentSession != null ||
          Supabase.instance.client.auth.currentUser != null;
    } catch (_) {
      return false;
    }
  }
}
