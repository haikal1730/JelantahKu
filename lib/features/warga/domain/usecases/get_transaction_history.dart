import '../entities/transaction.dart';
import '../repositories/transaction_repository.dart';

class GetTransactionHistory {
  final TransactionRepository repository;

  const GetTransactionHistory(this.repository);

  Future<List<Transaction>> execute(String userId) async {
    return await repository.getTransactions(userId);
  }
}
