import 'package:flutter/services.dart';

class AppConfig {
  // Supports normal `flutter run` via .env, with --dart-define as fallback.
  static const _defineApiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const _definePaymentApiUrl = String.fromEnvironment('PAYMENT_API_URL');
  static const _defineUseSupabase =
      String.fromEnvironment('USE_SUPABASE', defaultValue: 'true');
  static const _defineSupabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const _defineSupabasePublishableKey =
      String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  static const _defineSupabaseRedirectUrl =
      String.fromEnvironment('SUPABASE_REDIRECT_URL');
  static const _defineFirebaseApiKey =
      String.fromEnvironment('FIREBASE_API_KEY');
  static const _defineFirebaseAppId =
      String.fromEnvironment('FIREBASE_APP_ID');
  static const _defineFirebaseMessagingSenderId =
      String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  static const _defineFirebaseProjectId =
      String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const _definePaymentMode =
      String.fromEnvironment('PAYMENT_MODE');

  static String apiBaseUrl = '';
  static String paymentApiUrl = '';
  static bool useSupabase = true;
  static String supabaseUrl = '';
  static String supabasePublishableKey = '';
  static String supabaseRedirectUrl =
      'io.supabase.jelantahku://login-callback/';

  static String firebaseApiKey = '';
  static String firebaseAppId = '';
  static String firebaseMessagingSenderId = '';
  static String firebaseProjectId = '';
  static String paymentMode = 'mock';

  static Future<void> load() async {
    apiBaseUrl = _defineApiBaseUrl.trim();
    paymentApiUrl = _definePaymentApiUrl.trim();
    useSupabase = _parseBool(_defineUseSupabase);
    supabaseUrl = _defineSupabaseUrl.trim();
    supabasePublishableKey = _defineSupabasePublishableKey.trim();
    supabaseRedirectUrl = _defineSupabaseRedirectUrl.trim().isNotEmpty
        ? _defineSupabaseRedirectUrl.trim()
        : 'io.supabase.jelantahku://login-callback/';
    firebaseApiKey = _defineFirebaseApiKey.trim();
    firebaseAppId = _defineFirebaseAppId.trim();
    firebaseMessagingSenderId = _defineFirebaseMessagingSenderId.trim();
    firebaseProjectId = _defineFirebaseProjectId.trim();
    paymentMode = _definePaymentMode.trim().isNotEmpty
        ? _definePaymentMode.trim().toLowerCase()
        : 'mock';
  }

  static bool _parseBool(String value) =>
      value.toLowerCase() == 'true' ||
      value == '1' ||
      value.toLowerCase() == 'yes';

  static bool get hasFirebaseConfig =>
      firebaseApiKey.isNotEmpty &&
      firebaseAppId.isNotEmpty &&
      firebaseMessagingSenderId.isNotEmpty &&
      firebaseProjectId.isNotEmpty;

  static bool get hasSupabaseConfig =>
      useSupabase &&
      supabaseUrl.isNotEmpty &&
      supabasePublishableKey.isNotEmpty;

  static bool get hasApi => apiBaseUrl.trim().isNotEmpty;

  static bool get hasPaymentApi =>
      paymentApiUrl.trim().isNotEmpty || apiBaseUrl.trim().isNotEmpty;
}
