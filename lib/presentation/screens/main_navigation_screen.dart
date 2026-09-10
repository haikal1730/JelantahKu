import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jelantah_ku/core/constants/app_theme.dart';
import 'package:jelantah_ku/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:jelantah_ku/features/auth/domain/entities/user_role.dart';
import 'package:jelantah_ku/features/auth/presentation/providers/user_provider.dart';
import 'package:jelantah_ku/features/auth/presentation/providers/auth_provider.dart';
import 'package:jelantah_ku/features/owner/presentation/screens/owner_dashboard_screen.dart';
import 'package:jelantah_ku/features/warga/presentation/screens/deposit_confirmation_screen.dart';
import 'package:jelantah_ku/features/warga/presentation/screens/transaction_history_screen.dart';
import 'package:jelantah_ku/features/warga/presentation/screens/warga_home_screen.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userNotifierProvider);

    return Scaffold(
      body: _buildScreenForRole(user.role),
      bottomNavigationBar: _buildBottomNav(user.role),
      floatingActionButton: user.role == UserRole.warga
          ? FloatingActionButton.extended(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan Tabung'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DepositConfirmationScreen(),
                  ),
                );
              },
            )
          : null,
      drawer: _buildRoleDrawer(context, ref, user),
    );
  }

  Widget _buildScreenForRole(UserRole role) {
    switch (role) {
      case UserRole.warga:
        if (_selectedIndex == 0) {
          return WargaHomeScreen(
            onNavigateToHistory: () {
              setState(() {
                _selectedIndex = 1;
              });
            },
          );
        } else if (_selectedIndex == 1) {
          return const TransactionHistoryScreen();
        } else {
          return _buildProfileScreen();
        }

      case UserRole.admin:
        if (_selectedIndex == 0) {
          return const AdminDashboardScreen();
        } else if (_selectedIndex == 1) {
          return const TransactionHistoryScreen();
        } else {
          return _buildProfileScreen();
        }

      case UserRole.owner:
        if (_selectedIndex == 0) {
          return const OwnerDashboardScreen();
        } else if (_selectedIndex == 1) {
          return const TransactionHistoryScreen();
        } else {
          return _buildProfileScreen();
        }
    }
  }

  Widget _buildBottomNav(UserRole role) {
    final items = <BottomNavigationBarItem>[];

    switch (role) {
      case UserRole.warga:
        items.addAll([
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Beranda',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.history_rounded),
            label: 'Riwayat',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ]);
        break;

      case UserRole.admin:
        items.addAll([
          const BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Sensor Tabung',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_rounded),
            label: 'Transaksi Desa',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profil Admin',
          ),
        ]);
        break;

      case UserRole.owner:
        items.addAll([
          const BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_rounded),
            label: 'Monitoring',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.history_edu_rounded),
            label: 'Laporan',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profil Owner',
          ),
        ]);
        break;
    }

    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      selectedItemColor: AppTheme.primaryGreen,
      unselectedItemColor: Colors.grey,
      onTap: (index) {
        setState(() {
          _selectedIndex = index;
        });
      },
      items: items,
    );
  }

  Widget _buildProfileScreen() {
    final user = ref.watch(userNotifierProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Profil Pengguna')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 40,
              backgroundColor: AppTheme.primaryGreen,
              child: Icon(Icons.person, size: 40, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              user.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              'ID: ${user.id} • ${user.village}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Card(
              child: ListTile(
                leading: const Icon(Icons.verified_user, color: AppTheme.primaryGreen),
                title: const Text('Role Akun'),
                subtitle: Text('${user.role.label} — ${user.role.description}'),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text(
                  'Keluar',
                  style: TextStyle(color: Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () async {
                  await ref.read(authNotifierProvider.notifier).signOut();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleDrawer(BuildContext context, WidgetRef ref, UserProfile user) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: AppTheme.primaryGreen),
            accountName: Text(user.name),
            accountEmail: Text('Role: ${user.role.label}'),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.eco, color: AppTheme.primaryGreen, size: 32),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.verified_user, color: AppTheme.primaryGreen),
            title: const Text('Role akun'),
            subtitle: Text(user.role.description),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Keluar'),
            onTap: () async {
              Navigator.pop(context);
              await ref.read(authNotifierProvider.notifier).signOut();
            },
          ),
        ],
      ),
    );
  }

}
