import '../../domain/entities/transaction.dart';

sealed class TransactionState {
  const TransactionState();

  const factory TransactionState.initial() = TransactionInitial;
  const factory TransactionState.loading() = TransactionLoading;
  const factory TransactionState.success(List<Transaction> transactions) = TransactionSuccess;
  const factory TransactionState.error(String message) = TransactionError;
}

final class TransactionInitial extends TransactionState {
  const TransactionInitial();
}

final class TransactionLoading extends TransactionState {
  const TransactionLoading();
}

final class TransactionSuccess extends TransactionState {
  final List<Transaction> transactions;
  const TransactionSuccess(this.transactions);
}

final class TransactionError extends TransactionState {
  final String message;
  const TransactionError(this.message);
}
