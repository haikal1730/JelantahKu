import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_theme.dart';
import 'core/notifications/push_notification_service.dart';
import 'core/config/app_config.dart';
import 'core/supabase/supabase_client.dart';
import 'features/auth/presentation/screens/auth_gate.dart';
import 'features/warga/presentation/providers/transaction_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load compile-time configuration supplied through --dart-define.
  await AppConfig.load();

  // Supabase adalah backend utama aplikasi.
  await SupabaseService.initialize();

  // Firebase hanya opsional untuk FCM push notification. Auth/DB tidak lagi bergantung pada Firebase.
  if (AppConfig.hasFirebaseConfig) {
    try {
      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: AppConfig.firebaseApiKey,
          appId: AppConfig.firebaseAppId,
          messagingSenderId: AppConfig.firebaseMessagingSenderId,
          projectId: AppConfig.firebaseProjectId,
        ),
      );
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    } catch (_) {}
  }

  runApp(const ProviderScope(child: JelantahKuApp()));
}

class JelantahKuApp extends ConsumerStatefulWidget {
  const JelantahKuApp({super.key});
  @override
  ConsumerState<JelantahKuApp> createState() => _JelantahKuAppState();
}

class _JelantahKuAppState extends ConsumerState<JelantahKuApp> {
  @override
  void initState() {
    super.initState();
    ref.read(syncManagerProvider);
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Jelantah-Ku',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.lightTheme,
    home: const AuthGate(),
  );
}
