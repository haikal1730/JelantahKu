import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jelantah_ku/features/warga/presentation/providers/persistent_storage_provider.dart';

class OfflineStatusBanner extends ConsumerWidget {
  const OfflineStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivity = ref.watch(connectivityServiceProvider);
    final local = ref.watch(transactionLocalDataSourceProvider);

    return StreamBuilder<bool>(
      stream: connectivity.onStatusChanged,
      initialData: true,
      builder: (context, snapshot) {
        final online = snapshot.data ?? true;
        return FutureBuilder<int>(
          future: local.pendingCount(),
          builder: (context, pendingSnapshot) {
            final pending = pendingSnapshot.data ?? 0;
            if (online && pending == 0) return const SizedBox.shrink();

            return Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: online ? Colors.orange.shade50 : Colors.amber.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: online ? Colors.orange.shade200 : Colors.amber.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    online ? Icons.sync_rounded : Icons.cloud_off_rounded,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      online
                          ? '$pending transaksi menunggu sinkronisasi.'
                          : 'Mode offline aktif. Data tersimpan di perangkat.',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
