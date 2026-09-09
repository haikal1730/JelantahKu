import 'package:flutter_test/flutter_test.dart';
import 'package:jelantah_ku/features/warga/data/datasources/transaction_mock_datasource.dart';
import 'package:jelantah_ku/features/warga/data/repositories/transaction_repository_impl.dart';
import 'package:jelantah_ku/features/warga/domain/entities/transaction.dart';

void main() {
  late TransactionMockDataSource mockDataSource;
  late TransactionRepositoryImpl repository;
  const String testUserId = 'USR-8821';

  setUp(() {
    mockDataSource = TransactionMockDataSource();
    repository = TransactionRepositoryImpl(dataSource: mockDataSource);
  });

  group('TransactionRepository Unit Tests', () {
    test('Test 3: Transaction Repository returns list of mock transactions', () async {
      // Arrange
      mockDataSource.shouldSimulateError = false;

      // Act
      final transactions = await repository.getTransactions(testUserId);

      // Assert
      expect(transactions, isA<List<Transaction>>());
      expect(transactions.isNotEmpty, isTrue);
      expect(transactions.length, greaterThanOrEqualTo(5));

      final firstTrx = transactions.first;
      expect(firstTrx.userId, testUserId);
      expect(firstTrx.id, startsWith('TRX-'));
    });

    test('Transaction Repository creates and saves new deposit transaction', () async {
      // Arrange
      final newTrx = Transaction(
        id: 'TRX-9999',
        userId: testUserId,
        tubeId: 'TAB-001',
        weightKg: 5.0,
        pricePerKg: 5000.0,
        totalValue: 25000.0,
        type: TransactionType.deposit,
        status: TransactionStatus.success,
        createdAt: DateTime.now(),
      );

      // Act
      final savedTrx = await repository.createTransaction(newTrx);

      // Assert
      expect(savedTrx.id, 'TRX-9999');
      expect(savedTrx.totalValue, 25000.0);

      final listAfter = await repository.getTransactions(testUserId);
      expect(listAfter.any((t) => t.id == 'TRX-9999'), isTrue);
    });

    test('Transaction Repository retrieves initial balance Rp 125.000', () async {
      // Act
      final balance = await repository.getUserBalance(testUserId);

      // Assert
      expect(balance, 125000.0);
    });
  });
}
