import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jelantah_ku/features/warga/data/datasources/transaction_mock_datasource.dart';
import 'package:jelantah_ku/features/warga/data/repositories/transaction_repository_impl.dart';
import 'package:jelantah_ku/features/warga/domain/usecases/confirm_deposit.dart';
import 'package:jelantah_ku/features/warga/domain/usecases/get_transaction_history.dart';
import 'package:jelantah_ku/features/warga/presentation/providers/transaction_provider.dart';
import 'package:jelantah_ku/features/warga/presentation/providers/transaction_state.dart';

void main() {
  late TransactionMockDataSource dataSource;
  late TransactionRepositoryImpl repository;
  late GetTransactionHistory getTransactionHistory;
  late ConfirmDeposit confirmDeposit;
  late ProviderContainer container;
  const String testUserId = 'USR-8821';

  setUp(() {
    dataSource = TransactionMockDataSource();
    repository = TransactionRepositoryImpl(dataSource: dataSource);
    getTransactionHistory = GetTransactionHistory(repository);
    confirmDeposit = ConfirmDeposit(repository: repository);

    container = ProviderContainer(
      overrides: [
        transactionDataSourceProvider.overrideWithValue(dataSource),
        transactionRepositoryProvider.overrideWithValue(repository),
        getTransactionHistoryProvider.overrideWithValue(getTransactionHistory),
        confirmDepositUseCaseProvider.overrideWithValue(confirmDeposit),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('TransactionNotifier & State Flow Unit Tests', () {
    test('Test 4: Notifier transitions from Loading -> Success on normal load', () async {
      // Arrange
      dataSource.shouldSimulateError = false;
      final notifier = container.read(transactionNotifierProvider.notifier);

      // Verify Initial State
      expect(container.read(transactionNotifierProvider), isA<TransactionInitial>());

      // Act
      final future = notifier.loadTransactions(testUserId);

      // Verify Loading State while async operation is pending
      expect(container.read(transactionNotifierProvider), isA<TransactionLoading>());

      await future;

      // Assert Success State with populated transaction list
      final state = container.read(transactionNotifierProvider);
      expect(state, isA<TransactionSuccess>());
      if (state is TransactionSuccess) {
        expect(state.transactions.isNotEmpty, isTrue);
        expect(state.transactions.length, greaterThanOrEqualTo(5));
      }
    });

    test('Test 5: Notifier transitions from Loading -> Error when DataSource fails', () async {
      // Arrange
      dataSource.shouldSimulateError = true;
      final notifier = container.read(transactionNotifierProvider.notifier);

      // Act
      final future = notifier.loadTransactions(testUserId);

      // Verify Loading State
      expect(container.read(transactionNotifierProvider), isA<TransactionLoading>());

      await future;

      // Assert Error State with message
      final state = container.read(transactionNotifierProvider);
      expect(state, isA<TransactionError>());
      if (state is TransactionError) {
        expect(state.message, contains('Gagal memuat riwayat transaksi'));
      }
    });
  });
}
