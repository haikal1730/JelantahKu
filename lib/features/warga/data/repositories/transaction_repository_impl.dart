import '../../../../core/network/connectivity_service.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../datasources/transaction_local_datasource.dart';
import '../datasources/transaction_mock_datasource.dart';
import '../models/transaction_model.dart';
import '../../../../core/error/failure.dart';

/// Repository dengan strategi Offline-First:
/// 1) gunakan remote saat online;
/// 2) simpan hasil remote ke cache lokal;
/// 3) saat offline/error, baca cache;
/// 4) penulisan offline masuk antrean sinkronisasi.
class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionDataSource dataSource;
  final TransactionLocalDataSource? localDataSource;
  final ConnectivityService? connectivityService;

  TransactionRepositoryImpl({
    required this.dataSource,
    this.localDataSource,
    this.connectivityService,
  });

  Future<bool> _isOnline() async {
    if (connectivityService == null) return true;
    return connectivityService!.isOnline;
  }

  @override
  Future<List<Transaction>> getTransactions(String userId) async {
    final local = localDataSource;

    if (local != null && !(await _isOnline())) {
      return local.getCachedTransactions(userId);
    }

    try {
      final models = await dataSource.getTransactions(userId);
      if (local != null) {
        await local.cacheTransactions(userId, models);
      }
      return models;
    } on Failure {
      if (local != null) {
        final cached = await local.getCachedTransactions(userId);
        if (cached.isNotEmpty) return cached;
      }
      rethrow;
    } catch (e) {
      if (local != null) {
        final cached = await local.getCachedTransactions(userId);
        if (cached.isNotEmpty) return cached;
      }
      throw ServerFailure('Terjadi kesalahan tidak terduga: $e');
    }
  }

  @override
  Future<Transaction?> getTransactionById(String id) async {
    try {
      return await dataSource.getTransactionById(id);
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure('Gagal mengambil detail transaksi: $e');
    }
  }

  @override
  Future<Transaction> createTransaction(Transaction transaction) async {
    final local = localDataSource;
    final model = TransactionModel.fromEntity(transaction);

    if (local != null && !(await _isOnline())) {
      final pending = TransactionModel(
        id: model.id,
        userId: model.userId,
        tubeId: model.tubeId,
        weightKg: model.weightKg,
        pricePerKg: model.pricePerKg,
        totalValue: model.totalValue,
        type: model.type,
        status: TransactionStatus.pending,
        createdAt: model.createdAt,
      );
      await local.upsertCachedTransaction(pending);
      await local.savePendingTransaction(pending);
      return pending;
    }

    try {
      final resultModel = await dataSource.createTransaction(model);
      if (local != null) {
        await local.upsertCachedTransaction(resultModel);
      }
      return resultModel;
    } on Failure {
      if (local != null) {
        final pending = TransactionModel(
          id: model.id,
          userId: model.userId,
          tubeId: model.tubeId,
          weightKg: model.weightKg,
          pricePerKg: model.pricePerKg,
          totalValue: model.totalValue,
          type: model.type,
          status: TransactionStatus.pending,
          createdAt: model.createdAt,
        );
        await local.upsertCachedTransaction(pending);
        await local.savePendingTransaction(pending);
        return pending;
      }
      rethrow;
    } catch (e) {
      if (local != null) {
        final pending = TransactionModel(
          id: model.id,
          userId: model.userId,
          tubeId: model.tubeId,
          weightKg: model.weightKg,
          pricePerKg: model.pricePerKg,
          totalValue: model.totalValue,
          type: model.type,
          status: TransactionStatus.pending,
          createdAt: model.createdAt,
        );
        await local.upsertCachedTransaction(pending);
        await local.savePendingTransaction(pending);
        return pending;
      }
      throw ServerFailure('Gagal memproses transaksi: $e');
    }
  }

  @override
  Future<double> getUserBalance(String userId) async {
    final local = localDataSource;

    if (local != null && !(await _isOnline())) {
      return await local.getCachedBalance(userId) ?? 0;
    }

    try {
      final balance = await dataSource.getUserBalance(userId);
      if (local != null) await local.cacheBalance(userId, balance);
      return balance;
    } on Failure {
      if (local != null) {
        final cached = await local.getCachedBalance(userId);
        if (cached != null) return cached;
      }
      rethrow;
    }
  }
}
