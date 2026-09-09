import '../entities/transaction.dart';

abstract class TransactionRepository {
  /// Fetch all transactions for a given user
  Future<List<Transaction>> getTransactions(String userId);

  /// Fetch a single transaction by ID
  Future<Transaction?> getTransactionById(String id);

  /// Create and record a new transaction
  Future<Transaction> createTransaction(Transaction transaction);

  /// Get total account balance for a user
  Future<double> getUserBalance(String userId);
}
