import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';

import '../error/failure.dart';

/// Handles Firebase Cloud Messaging when Firebase is configured.
/// Supabase remains the primary backend/auth/database.
class PushNotificationService {
  PushNotificationService({FirebaseMessaging? messaging})
      : _messaging = messaging;

  final FirebaseMessaging? _messaging;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;

  bool get isAvailable => _messaging != null;

  Future<String?> initialize({
    required Future<void> Function(String token) onToken,
    void Function(RemoteMessage message)? onMessage,
    void Function(RemoteMessage message)? onMessageOpenedApp,
  }) async {
    if (_messaging == null) return null;

    try {
      final settings = await _messaging!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return null;
      }

      final token = await _messaging!.getToken();
      if (token != null && token.isNotEmpty) {
        await onToken(token);
      }

      await _foregroundSubscription?.cancel();
      _foregroundSubscription = FirebaseMessaging.onMessage.listen(
        onMessage ?? (_) {},
      );

      await _tokenSubscription?.cancel();
      _tokenSubscription = _messaging!.onTokenRefresh.listen((token) async {
        if (token.isNotEmpty) await onToken(token);
      });

      await _openedSubscription?.cancel();
      _openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
        onMessageOpenedApp ?? (_) {},
      );

      // Handles a notification that opened the app from a terminated state.
      final initialMessage = await _messaging!.getInitialMessage();
      if (initialMessage != null) {
        onMessageOpenedApp?.call(initialMessage);
      }

      return token;
    } catch (e) {
      throw NetworkFailure('Push notification gagal diinisialisasi: $e');
    }
  }

  Future<void> dispose() async {
    await _foregroundSubscription?.cancel();
    await _tokenSubscription?.cancel();
    await _openedSubscription?.cancel();
    _foregroundSubscription = null;
    _tokenSubscription = null;
    _openedSubscription = null;
  }
}

/// Required top-level FCM background handler.
/// It must not depend on widgets or Riverpod state.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // For notification messages, Android/iOS displays the notification
  // automatically while the app is in the background.
  // Data-only messages can be processed here in a future iteration.
}
