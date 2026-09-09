import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_theme.dart';
import 'presentation/screens/main_navigation_screen.dart';

void main() {
  runApp(
    const ProviderScope(
      child: JelantahKuApp(),
    ),
  );
}

class JelantahKuApp extends StatelessWidget {
  const JelantahKuApp({super.key});

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
