import '../entities/transaction.dart';
import '../repositories/transaction_repository.dart';
import 'calculate_deposit_value.dart';

class ConfirmDeposit {
  final TransactionRepository repository;
  final CalculateDepositValue calculator;

  const ConfirmDeposit({
    required this.repository,
    this.calculator = const CalculateDepositValue(),
  });

  Future<Transaction> execute({
    required String userId,
    required String tubeId,
    required double weightKg,
    required double pricePerKg,
  }) async {
    final totalValue = calculator.execute(
      weightKg: weightKg,
      pricePerKg: pricePerKg,
    );

    final transaction = Transaction(
      id: 'TRX-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
      userId: userId,
      tubeId: tubeId,
      weightKg: weightKg,
      pricePerKg: pricePerKg,
      totalValue: totalValue,
      type: TransactionType.deposit,
      status: TransactionStatus.success,
      createdAt: DateTime.now(),
    );

    return await repository.createTransaction(transaction);
  }
}
