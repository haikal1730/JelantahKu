import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jelantah_ku/core/constants/app_theme.dart';
import 'package:jelantah_ku/core/utils/currency_formatter.dart';
import 'package:jelantah_ku/core/utils/date_formatter.dart';
import 'package:jelantah_ku/features/auth/presentation/providers/user_provider.dart';
import 'package:jelantah_ku/features/warga/domain/entities/transaction.dart';
import 'package:jelantah_ku/features/warga/presentation/providers/transaction_provider.dart';
import 'package:jelantah_ku/features/warga/presentation/providers/transaction_state.dart';
import 'package:jelantah_ku/features/warga/presentation/widgets/transaction_detail_modal.dart';
import 'package:jelantah_ku/features/warga/presentation/widgets/offline_status_banner.dart';

class TransactionHistoryScreen extends ConsumerStatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  ConsumerState<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState
    extends ConsumerState<TransactionHistoryScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final user = ref.read(userNotifierProvider);
      ref.read(transactionNotifierProvider.notifier).loadTransactions(user.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userNotifierProvider);
    final trxState = ref.watch(transactionNotifierProvider);
    final isErrorSimulated =
        ref.read(transactionNotifierProvider.notifier).isErrorSimulated;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Transaksi'),
        actions: [
          IconButton(
            icon: Icon(
              isErrorSimulated
                  ? Icons.bug_report
                  : Icons.bug_report_outlined,
              color: isErrorSimulated ? Colors.amberAccent : Colors.white,
            ),
            tooltip: 'Toggle Error Simulation',
            onPressed: () {
              ref
                  .read(transactionNotifierProvider.notifier)
                  .toggleErrorSimulation(user.id);
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              ref
                  .read(transactionNotifierProvider.notifier)
                  .loadTransactions(user.id);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineStatusBanner(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await ref
                    .read(transactionNotifierProvider.notifier)
                    .loadTransactions(user.id);
              },
              child: _buildBody(context, ref, trxState, user.id),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    TransactionState state,
    String userId,
  ) {
    return switch (state) {
      // 1. INITIAL STATE
      TransactionInitial() => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.hourglass_empty_rounded, size: 48, color: Colors.grey),
              SizedBox(height: 12),
              Text(
                'Memulai data transaksi...',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),

      // 2. LOADING STATE
      TransactionLoading() => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Memuat riwayat transaksi...',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),

      // 3. SUCCESS STATE (LIST OR EMPTY)
      TransactionSuccess(:final transactions) => transactions.isEmpty
          ? Center(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Belum ada transaksi.',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Setor minyak jelantah Anda ke tabung komunal.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: transactions.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = transactions[index];
                return _buildTransactionCard(context, item);
              },
            ),

      // 4. ERROR STATE
      TransactionError(:final message) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEE2E2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    color: AppTheme.errorRed,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Gagal memuat riwayat transaksi.',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    ref
                        .read(transactionNotifierProvider.notifier)
                        .loadTransactions(userId);
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
    };
  }

  Widget _buildTransactionCard(BuildContext context, Transaction item) {
    final isDeposit = item.type == TransactionType.deposit;
    final statusColor = item.status == TransactionStatus.success
        ? AppTheme.successGreen
        : (item.status == TransactionStatus.pending
            ? AppTheme.pendingOrange
            : AppTheme.errorRed);

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: isDeposit
              ? AppTheme.primaryGreen.withOpacity(0.1)
              : AppTheme.accentAmber.withOpacity(0.1),
          child: Icon(
            isDeposit ? Icons.opacity : Icons.account_balance_wallet,
            color: isDeposit ? AppTheme.primaryGreen : AppTheme.accentAmber,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                item.type.label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                item.status.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            children: [
              Text(
                DateFormatter.formatDateTime(item.createdAt),
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              if (isDeposit) ...[
                const Spacer(),
                Text(
                  CurrencyFormatter.formatKg(item.weightKg),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ],
          ),
        ),
        trailing: Text(
          '${isDeposit ? '+' : '-'}${CurrencyFormatter.format(item.totalValue)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: isDeposit ? AppTheme.primaryGreen : Colors.red,
          ),
        ),
        onTap: () {
          TransactionDetailModal.show(context, item);
        },
      ),
    );
  }
}
