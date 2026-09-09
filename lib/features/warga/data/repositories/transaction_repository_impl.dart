import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../datasources/transaction_mock_datasource.dart';
import '../models/transaction_model.dart';
import '../../../../core/error/failure.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionDataSource dataSource;

  TransactionRepositoryImpl({required this.dataSource});

  @override
  Future<List<Transaction>> getTransactions(String userId) async {
    try {
      final models = await dataSource.getTransactions(userId);
      return models;
    } on Failure {
      rethrow;
    } catch (e) {
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
      throw ServerFailure('Gagal mengambil data transaksi: $e');
    }
  }

  @override
  Future<Transaction> createTransaction(Transaction transaction) async {
    try {
      final model = TransactionModel.fromEntity(transaction);
      final resultModel = await dataSource.createTransaction(model);
      return resultModel;
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure('Gagal memproses transaksi: $e');
    }
  }

  @override
  Future<double> getUserBalance(String userId) async {
    try {
      return await dataSource.getUserBalance(userId);
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure('Gagal mendapatkan saldo user: $e');
    }
  }
}
