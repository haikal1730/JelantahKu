import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_theme.dart';
import 'core/security/secure_storage_service.dart';
import 'features/warga/presentation/providers/persistent_storage_provider.dart';
import 'features/warga/presentation/providers/transaction_provider.dart';
import 'presentation/screens/main_navigation_screen.dart';

void main() {
  runApp(
    const ProviderScope(
      child: JelantahKuApp(),
    ),
  );
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
    // Memulai listener koneksi untuk automatic sync.
    ref.read(syncManagerProvider);
    _initializeSecureSession();
  }

  Future<void> _initializeSecureSession() async {
    final storage = ref.read(secureStorageServiceProvider);
    final userId = await storage.readUserId();
    if (userId == null) {
      await storage.saveSession(
        userId: 'USR-8821',
        token: 'demo-session-token',
      );
      await storage.saveSubscriptionStatus(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jelantah-Ku',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MainNavigationScreen(),
    );
  }
}
