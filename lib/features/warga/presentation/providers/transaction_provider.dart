import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/transaction_mock_datasource.dart';
import '../../data/repositories/transaction_repository_impl.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../domain/usecases/calculate_deposit_value.dart';
import '../../domain/usecases/confirm_deposit.dart';
import '../../domain/usecases/get_transaction_history.dart';
import '../../domain/usecases/get_user_balance.dart';
import 'transaction_state.dart';
import 'balance_provider.dart';

// DataSource Provider
final transactionDataSourceProvider = Provider<TransactionMockDataSource>((ref) {
  return TransactionMockDataSource();
});

// Repository Provider
final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final dataSource = ref.watch(transactionDataSourceProvider);
  return TransactionRepositoryImpl(dataSource: dataSource);
});

// UseCase Providers
final calculateDepositValueProvider = Provider<CalculateDepositValue>((ref) {
  return const CalculateDepositValue();
});

final getTransactionHistoryProvider = Provider<GetTransactionHistory>((ref) {
  final repo = ref.watch(transactionRepositoryProvider);
  return GetTransactionHistory(repo);
});

final getUserBalanceProvider = Provider<GetUserBalance>((ref) {
  final repo = ref.watch(transactionRepositoryProvider);
  return GetUserBalance(repo);
});

final confirmDepositUseCaseProvider = Provider<ConfirmDeposit>((ref) {
  final repo = ref.watch(transactionRepositoryProvider);
  final calculator = ref.watch(calculateDepositValueProvider);
  return ConfirmDeposit(repository: repo, calculator: calculator);
});

// Notifier & State Management
class TransactionNotifier extends StateNotifier<TransactionState> {
  final GetTransactionHistory getTransactionHistory;
  final ConfirmDeposit confirmDepositUseCase;
  final TransactionMockDataSource dataSource;
  final Ref ref;

  TransactionNotifier({
    required this.getTransactionHistory,
    required this.confirmDepositUseCase,
    required this.dataSource,
    required this.ref,
  }) : super(const TransactionState.initial());

  bool get isErrorSimulated => dataSource.shouldSimulateError;

  void toggleErrorSimulation(String userId) {
    dataSource.shouldSimulateError = !dataSource.shouldSimulateError;
    loadTransactions(userId);
  }

  void setErrorSimulation(bool value, String userId) {
    dataSource.shouldSimulateError = value;
    loadTransactions(userId);
  }

  Future<void> loadTransactions(String userId) async {
    state = const TransactionState.loading();
    try {
      final transactions = await getTransactionHistory.execute(userId);
      state = TransactionState.success(transactions);
    } catch (e) {
      state = TransactionState.error(e.toString());
    }
  }

  Future<bool> createDeposit({
    required String userId,
    required String tubeId,
    required double weightKg,
    required double pricePerKg,
  }) async {
    try {
      await confirmDepositUseCase.execute(
        userId: userId,
        tubeId: tubeId,
        weightKg: weightKg,
        pricePerKg: pricePerKg,
      );

      // Refresh transactions and balance
      await loadTransactions(userId);
      await ref.read(balanceNotifierProvider.notifier).loadBalance(userId);
      return true;
    } catch (e) {
      state = TransactionState.error(e.toString());
      return false;
    }
  }
}

final transactionNotifierProvider =
    StateNotifierProvider<TransactionNotifier, TransactionState>((ref) {
  final getHistory = ref.watch(getTransactionHistoryProvider);
  final confirmDeposit = ref.watch(confirmDepositUseCaseProvider);
  final dataSource = ref.watch(transactionDataSourceProvider);

  return TransactionNotifier(
    getTransactionHistory: getHistory,
    confirmDepositUseCase: confirmDeposit,
    dataSource: dataSource,
    ref: ref,
  );
});
