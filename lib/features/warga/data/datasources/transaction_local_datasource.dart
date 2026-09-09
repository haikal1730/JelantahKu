import 'dart:convert';
import '../../../../core/storage/local_storage.dart';
import '../models/transaction_model.dart';

class TransactionLocalDataSource {
  TransactionLocalDataSource({LocalStorage? storage})
      : _storage = storage ?? LocalStorage.instance;

  final LocalStorage _storage;
  static const _cachePrefix = 'transactions_cache_';
  static const _pendingKey = 'transactions_pending_sync';
  static const _balancePrefix = 'balance_cache_';

  Future<List<TransactionModel>> getCachedTransactions(String userId) async {
    final raw = await _storage.getString('$_cachePrefix$userId');
    if (raw == null || raw.isEmpty) return [];

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => TransactionModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> cacheTransactions(
    String userId,
    List<TransactionModel> transactions,
  ) async {
    await _storage.setString(
      '$_cachePrefix$userId',
      jsonEncode(transactions.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> upsertCachedTransaction(TransactionModel transaction) async {
    final list = await getCachedTransactions(transaction.userId);
    final index = list.indexWhere((item) => item.id == transaction.id);
    if (index >= 0) {
      list[index] = transaction;
    } else {
      list.insert(0, transaction);
    }
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    await cacheTransactions(transaction.userId, list);
  }

  Future<List<TransactionModel>> getPendingTransactions() async {
    final raw = await _storage.getString(_pendingKey);
    if (raw == null || raw.isEmpty) return [];

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => TransactionModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> savePendingTransaction(TransactionModel transaction) async {
    final list = await getPendingTransactions();
    final index = list.indexWhere((item) => item.id == transaction.id);
    if (index >= 0) {
      list[index] = transaction;
    } else {
      list.add(transaction);
    }
    await _storage.setString(
      _pendingKey,
      jsonEncode(list.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> removePendingTransaction(String transactionId) async {
    final list = await getPendingTransactions();
    list.removeWhere((item) => item.id == transactionId);
    await _storage.setString(
      _pendingKey,
      jsonEncode(list.map((e) => e.toJson()).toList()),
    );
  }

  Future<int> pendingCount() async => (await getPendingTransactions()).length;

  Future<double?> getCachedBalance(String userId) async {
    final raw = await _storage.getString('$_balancePrefix$userId');
    return raw == null ? null : double.tryParse(raw);
  }

  Future<void> cacheBalance(String userId, double balance) async {
    await _storage.setString('$_balancePrefix$userId', balance.toString());
  }
}
