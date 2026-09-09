import '../datasources/transaction_local_datasource.dart';
import '../datasources/transaction_mock_datasource.dart';
import '../models/transaction_model.dart';
import '../../domain/entities/transaction.dart';

/// Mengirim antrean transaksi lokal ke sumber data remote ketika online.
class TransactionSyncService {
  TransactionSyncService({
    required this.localDataSource,
    required this.remoteDataSource,
  });

  final TransactionLocalDataSource localDataSource;
  final TransactionMockDataSource remoteDataSource;

  Future<int> syncPendingTransactions() async {
    final pending = await localDataSource.getPendingTransactions();
    var synced = 0;

    for (final transaction in pending) {
      try {
        final remoteTransaction = transaction.status == TransactionStatus.pending
            ? TransactionModel(
                id: transaction.id,
                userId: transaction.userId,
                tubeId: transaction.tubeId,
                weightKg: transaction.weightKg,
                pricePerKg: transaction.pricePerKg,
                totalValue: transaction.totalValue,
                type: transaction.type,
                status: TransactionStatus.success,
                createdAt: transaction.createdAt,
              )
            : transaction;

        final saved = await remoteDataSource.createTransaction(remoteTransaction);
        await localDataSource.upsertCachedTransaction(saved);
        await localDataSource.removePendingTransaction(transaction.id);
        synced++;
      } catch (_) {
        // Tetap berada di queue agar bisa dicoba lagi saat koneksi berikutnya.
      }
    }

    return synced;
  }
}
