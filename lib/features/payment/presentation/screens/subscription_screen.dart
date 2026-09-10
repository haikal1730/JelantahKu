import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/security/secure_storage_service.dart';
import '../../../auth/presentation/providers/user_provider.dart';
import '../../../warga/presentation/providers/persistent_storage_provider.dart';
import '../../domain/payment_service.dart';

final paymentServiceProvider = Provider<PaymentService>((ref) => PaymentServiceFactory.create());

final subscriptionNotifierProvider =
    StateNotifierProvider<SubscriptionNotifier, AsyncValue<PaymentResult?>>((ref) {
  return SubscriptionNotifier(
    payment: ref.watch(paymentServiceProvider),
    storage: ref.watch(secureStorageServiceProvider),
  );
});

class SubscriptionNotifier extends StateNotifier<AsyncValue<PaymentResult?>> {
  SubscriptionNotifier({required this.payment, required this.storage})
      : super(const AsyncValue.data(null));

  final PaymentService payment;
  final SecureStorageService storage;

  Future<PaymentResult?> subscribe(String userId) async {
    state = const AsyncValue.loading();
    try {
      final result = await payment.createSubscription(userId: userId, amount: 25000);
      state = AsyncValue.data(result);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<PaymentResult?> refreshStatus(String orderId) async {
    try {
      final result = await payment.getPaymentStatus(orderId);
      state = AsyncValue.data(result);
      if (result.isPaid) await storage.saveSubscriptionStatus(true);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  Timer? _pollTimer;
  String? _orderId;
  bool _openingPayment = false;

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      final orderId = _orderId;
      if (orderId == null) return;
      final result = await ref.read(subscriptionNotifierProvider.notifier).refreshStatus(orderId);
      if (!mounted || result == null) return;
      if (result.isPaid) {
        _pollTimer?.cancel();
        _showMessage('Pembayaran berhasil. Premium aktif.');
      } else if (!result.isPending) {
        _pollTimer?.cancel();
        _showMessage('Pembayaran berstatus ${result.status}.');
      }
    });
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pay(String userId) async {
    setState(() => _openingPayment = true);
    final result = await ref.read(subscriptionNotifierProvider.notifier).subscribe(userId);
    if (!mounted) return;
    setState(() => _openingPayment = false);
    if (result == null) {
      final error = ref.read(subscriptionNotifierProvider).error;
      _showMessage(
        error?.toString() ?? 'Gagal membuat pembayaran. Periksa API backend.',
      );
      return;
    }

    _orderId = result.orderId;
    _showMessage('Order ${result.orderId} dibuat. Membuka Midtrans Sandbox...');

    final service = ref.read(paymentServiceProvider);
    final opened = await service.openRedirectUrl(result.redirectUrl);
    if (!opened && result.redirectUrl != null) {
      _showMessage('Tidak dapat membuka halaman pembayaran. Buka URL dari backend.');
    }
    _startPolling();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userNotifierProvider);
    final state = ref.watch(subscriptionNotifierProvider);
    final isReal = AppConfig.paymentMode == 'real' && AppConfig.hasPaymentApi;

    return Scaffold(
      appBar: AppBar(title: const Text('JelantahKu Premium')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Icon(Icons.workspace_premium_rounded, size: 42),
                  SizedBox(height: 12),
                  Text('Premium Warga', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('Rp25.000/bulan • pembayaran aman melalui Midtrans Sandbox.'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(isReal ? 'Mode: Midtrans Sandbox' : 'Mode: simulasi lokal'),
          if (_orderId != null) ...[
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.sync),
                title: const Text('Menunggu konfirmasi pembayaran'),
                subtitle: Text('Order: $_orderId\nStatus diperbarui dari webhook Midtrans.'),
                trailing: state.valueOrNull?.isPaid == true
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : const CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: (!isReal || _openingPayment || state.isLoading) ? null : () => _pay(user.id),
            icon: const Icon(Icons.payment_rounded),
            label: Text(_openingPayment ? 'Membuka pembayaran...' : 'Berlangganan Rp25.000'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _showHistory(context, user.id),
            icon: const Icon(Icons.receipt_long),
            label: const Text('Lihat riwayat pembayaran'),
          ),
          const SizedBox(height: 24),
          const Text(
            'Setelah pembayaran selesai di halaman Midtrans, kembali ke aplikasi. Status Premium hanya diaktifkan oleh webhook backend setelah Midtrans mengonfirmasi pembayaran.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Future<void> _showHistory(BuildContext context, String userId) async {
    final history = await ref.read(paymentServiceProvider).getHistory(userId);
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .7,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text('Riwayat Pembayaran', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              if (history.isEmpty) const Text('Belum ada pembayaran.'),
              ...history.map((item) => ListTile(
                    leading: Icon(item.status == 'paid' ? Icons.check_circle : Icons.schedule),
                    title: Text('Rp${item.amount.toStringAsFixed(0)}'),
                    subtitle: Text('${item.orderId}\n${item.createdAt.toLocal()}'),
                    trailing: Text(item.status),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
