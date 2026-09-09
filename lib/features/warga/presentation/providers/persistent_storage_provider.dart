import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../../core/security/secure_storage_service.dart';
import '../../data/datasources/transaction_local_datasource.dart';

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

final transactionLocalDataSourceProvider =
    Provider<TransactionLocalDataSource>((ref) {
  return TransactionLocalDataSource();
});
