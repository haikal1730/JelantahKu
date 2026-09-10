import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jelantah_ku/core/constants/app_theme.dart';
import 'package:jelantah_ku/core/utils/currency_formatter.dart';
import 'package:jelantah_ku/core/utils/date_formatter.dart';
import 'package:jelantah_ku/features/auth/presentation/providers/user_provider.dart';
import 'package:jelantah_ku/features/warga/domain/entities/transaction.dart';
import 'package:jelantah_ku/features/warga/presentation/providers/balance_provider.dart';
import 'package:jelantah_ku/features/warga/presentation/providers/transaction_provider.dart';
import 'package:jelantah_ku/features/warga/presentation/providers/transaction_state.dart';
import 'package:jelantah_ku/features/warga/presentation/widgets/transaction_detail_modal.dart';
import 'package:jelantah_ku/features/warga/presentation/screens/deposit_confirmation_screen.dart';
import 'package:jelantah_ku/features/payment/presentation/screens/subscription_screen.dart';

class WargaHomeScreen extends ConsumerStatefulWidget {
  final VoidCallback onNavigateToHistory;

  const WargaHomeScreen({
    super.key,
    required this.onNavigateToHistory,
  });

  @override
  ConsumerState<WargaHomeScreen> createState() => _WargaHomeScreenState();
}

class _WargaHomeScreenState extends ConsumerState<WargaHomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final user = ref.read(userNotifierProvider);
      ref.read(balanceNotifierProvider.notifier).loadBalance(user.id);
      ref.read(transactionNotifierProvider.notifier).loadTransactions(user.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userNotifierProvider);
    final balanceState = ref.watch(balanceNotifierProvider);
    final trxState = ref.watch(transactionNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.eco_rounded, size: 24),
            SizedBox(width: 8),
            Text('Jelantah-Ku'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Data',
            onPressed: () {
              ref.read(balanceNotifierProvider.notifier).loadBalance(user.id);
              ref.read(transactionNotifierProvider.notifier).loadTransactions(user.id);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(balanceNotifierProvider.notifier).loadBalance(user.id);
          await ref.read(transactionNotifierProvider.notifier).loadTransactions(user.id);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Greeting Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppTheme.primaryGreenLight.withOpacity(0.2),
                    child: const Icon(
                      Icons.person,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Halo, ${user.name} 👋',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${user.village} • Role: Warga',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Dynamic Balance Card with Gradient
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      AppTheme.primaryGreenDark,
                      AppTheme.primaryGreen,
                      AppTheme.primaryGreenLight,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryGreen.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Saldo Minyak Jelantah',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.shield, color: Colors.white, size: 12),
                              SizedBox(width: 4),
                              Text(
                                'Terverifikasi',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Balance Display
                    if (balanceState.isLoading)
                      const SizedBox(
                        height: 36,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          ),
                        ),
                      )
                    else
                      Text(
                        CurrencyFormatter.format(balanceState.balance),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),

                    const SizedBox(height: 20),

                    // Quick Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppTheme.primaryGreenDark,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.qr_code_scanner_rounded),
                            label: const Text(
                              'Scan Tabung',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const DepositConfirmationScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white, width: 1.5),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.account_balance_wallet_rounded),
                            label: const Text(
                              'Tarik Saldo',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Fitur Tarik Saldo via E-Wallet/Bank.'),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Error Simulation Switch Card for Testing State Flow
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.bug_report_rounded, color: Colors.amber),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Simulasi Error State',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            'Uji coba error state secara deterministik',
                            style: TextStyle(fontSize: 11, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: ref.read(transactionNotifierProvider.notifier).isErrorSimulated,
                      activeColor: AppTheme.errorRed,
                      onChanged: (value) {
                        ref.read(transactionNotifierProvider.notifier).toggleErrorSimulation(user.id);
                      },
                    ),
                  ],
                ),
              ),

              Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.workspace_premium_rounded),
                  ),
                  title: const Text(
                    'JelantahKu Premium',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Langganan Rp25.000/bulan • pembayaran sandbox',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SubscriptionScreen(),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Recent Transactions Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Transaksi Terbaru',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: widget.onNavigateToHistory,
                    child: const Text('Lihat Semua'),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Recent Transactions List handling riverpod state
              switch (trxState) {
                TransactionInitial() => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('Mempersiapkan data...'),
                    ),
                  ),
                TransactionLoading() => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                TransactionSuccess(:final transactions) => transactions.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(24),
                        width: double.infinity,
                        alignment: Alignment.center,
                        child: const Text('Belum ada transaksi.'),
                      )
                    : Column(
                        children: transactions.take(3).map((trx) {
                          final isDeposit = trx.type == TransactionType.deposit;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isDeposit
                                    ? AppTheme.primaryGreen.withOpacity(0.1)
                                    : AppTheme.accentAmber.withOpacity(0.1),
                                child: Icon(
                                  isDeposit ? Icons.opacity : Icons.account_balance_wallet,
                                  color: isDeposit ? AppTheme.primaryGreen : AppTheme.accentAmber,
                                ),
                              ),
                              title: Text(
                                trx.type.label,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(DateFormatter.formatDate(trx.createdAt)),
                              trailing: Text(
                                '${isDeposit ? '+' : '-'}${CurrencyFormatter.format(trx.totalValue)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isDeposit ? AppTheme.primaryGreen : Colors.red,
                                  fontSize: 14,
                                ),
                              ),
                              onTap: () {
                                TransactionDetailModal.show(context, trx);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                TransactionError(:final message) => Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: AppTheme.errorRed),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            message,
                            style: const TextStyle(color: AppTheme.errorRed, fontSize: 13),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            ref.read(transactionNotifierProvider.notifier).loadTransactions(user.id);
                          },
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
              },
            ],
          ),
        ),
      ),
    );
  }
}
