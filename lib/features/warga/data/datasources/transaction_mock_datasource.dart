import '../models/transaction_model.dart';
import '../../domain/entities/transaction.dart';
import '../../../../core/error/failure.dart';

abstract class TransactionDataSource {
  Future<List<TransactionModel>> getTransactions(String userId);
  Future<TransactionModel?> getTransactionById(String id);
  Future<TransactionModel> createTransaction(TransactionModel transaction);
  Future<double> getUserBalance(String userId);
}

class TransactionMockDataSource implements TransactionDataSource {
  bool shouldSimulateError = false;

  final List<TransactionModel> _mockStore = [
    TransactionModel(
      id: 'TRX-1001',
      userId: 'USR-8821',
      tubeId: 'TAB-001',
      weightKg: 5.0,
      pricePerKg: 5000.0,
      totalValue: 25000.0,
      type: TransactionType.deposit,
      status: TransactionStatus.success,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    TransactionModel(
      id: 'TRX-1002',
      userId: 'USR-8821',
      tubeId: 'TAB-002',
      weightKg: 3.0,
      pricePerKg: 5000.0,
      totalValue: 15000.0,
      type: TransactionType.deposit,
      status: TransactionStatus.success,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    TransactionModel(
      id: 'TRX-1003',
      userId: 'USR-8821',
      tubeId: 'TAB-001',
      weightKg: 8.0,
      pricePerKg: 5000.0,
      totalValue: 40000.0,
      type: TransactionType.deposit,
      status: TransactionStatus.success,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    TransactionModel(
      id: 'TRX-1004',
      userId: 'USR-8821',
      tubeId: 'TAB-SYSTEM',
      weightKg: 0.0,
      pricePerKg: 0.0,
      totalValue: 20000.0,
      type: TransactionType.withdrawal,
      status: TransactionStatus.success,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    TransactionModel(
      id: 'TRX-1005',
      userId: 'USR-8821',
      tubeId: 'TAB-003',
      weightKg: 2.5,
      pricePerKg: 5000.0,
      totalValue: 12500.0,
      type: TransactionType.deposit,
      status: TransactionStatus.pending,
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
    ),
    TransactionModel(
      id: 'TRX-1006',
      userId: 'USR-8821',
      tubeId: 'TAB-002',
      weightKg: 10.0,
      pricePerKg: 5000.0,
      totalValue: 50000.0,
      type: TransactionType.deposit,
      status: TransactionStatus.failed,
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
  ];

  double _userBalance = 125000.0;

  @override
  Future<List<TransactionModel>> getTransactions(String userId) async {
    // Artificial latency for realistic UI state loading simulation
    await Future.delayed(const Duration(milliseconds: 600));

    if (shouldSimulateError) {
      throw const ServerFailure('Gagal memuat riwayat transaksi. Network error.');
    }

    return _mockStore
        .where((trx) => trx.userId == userId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<TransactionModel?> getTransactionById(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (shouldSimulateError) {
      throw const ServerFailure('Gagal memuat detail transaksi.');
    }
    try {
      return _mockStore.firstWhere((element) => element.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<TransactionModel> createTransaction(TransactionModel transaction) async {
    await Future.delayed(const Duration(milliseconds: 800));

    if (shouldSimulateError) {
      throw const ServerFailure('Gagal menyimpan setoran. Sensor tabung tidak merespon.');
    }

    _mockStore.insert(0, transaction);

    // Update dynamic balance
    if (transaction.type == TransactionType.deposit &&
        transaction.status == TransactionStatus.success) {
      _userBalance += transaction.totalValue;
    } else if (transaction.type == TransactionType.withdrawal &&
        transaction.status == TransactionStatus.success) {
      _userBalance -= transaction.totalValue;
    }

    return transaction;
  }

  @override
  Future<double> getUserBalance(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (shouldSimulateError) {
      throw const ServerFailure('Gagal mengambil data saldo.');
    }
    return _userBalance;
  }
}
