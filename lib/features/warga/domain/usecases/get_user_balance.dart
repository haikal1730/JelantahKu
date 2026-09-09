import '../repositories/transaction_repository.dart';

class GetUserBalance {
  final TransactionRepository repository;

  const GetUserBalance(this.repository);

  Future<double> execute(String userId) async {
    return await repository.getUserBalance(userId);
  }
}
