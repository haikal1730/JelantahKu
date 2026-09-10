import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/supabase/supabase_client.dart';
import '../../domain/entities/transaction.dart';
import '../models/transaction_model.dart';
import 'transaction_mock_datasource.dart';

/// Remote datasource berbasis Supabase Postgres + RPC.
/// RPC menjaga update saldo dan insert transaksi tetap atomik/idempotent.
class SupabaseTransactionDataSource implements TransactionDataSource {
  SupabaseClient get _client => SupabaseService.client;

  @override
  Future<List<TransactionModel>> getTransactions(String userId) async {
    try {
      final rows = await _client
          .from('transactions')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(100);
      return rows.map(_fromRow).toList();
    } on PostgrestException catch (e) {
      throw ServerFailure('Supabase: ${e.message}');
    }
  }

  @override
  Future<TransactionModel?> getTransactionById(String id) async {
    try {
      final row = await _client.from('transactions').select().eq('id', id).maybeSingle();
      return row == null ? null : _fromRow(row);
    } on PostgrestException catch (e) {
      throw ServerFailure('Supabase: ${e.message}');
    }
  }

  @override
  Future<TransactionModel> createTransaction(TransactionModel transaction) async {
    try {
      final row = await _client.rpc('create_transaction', params: {
        'p_id': transaction.id,
        'p_user_id': transaction.userId,
        'p_tube_id': transaction.tubeId,
        'p_weight_kg': transaction.weightKg,
        'p_price_per_kg': transaction.pricePerKg,
        'p_total_value': transaction.totalValue,
        'p_type': transaction.type.name,
        'p_status': transaction.status.name,
        'p_created_at': transaction.createdAt.toIso8601String(),
      });
      final data = row is List ? (row.isEmpty ? null : row.first) : row;
      if (data is! Map) throw const ServerFailure('RPC transaksi tidak mengembalikan data.');
      return _fromRow(Map<String, dynamic>.from(data));
    } on PostgrestException catch (e) {
      throw ServerFailure('Gagal menyimpan transaksi: ${e.message}');
    }
  }

  @override
  Future<double> getUserBalance(String userId) async {
    try {
      // Repair/reconcile the cached aggregate from the transaction ledger first.
      // This also fixes balances from transactions created before the balance
      // consistency migration was applied. The RPC only operates on auth.uid().
      final repaired = await _client.rpc('repair_my_balance');
      if (repaired is num) return repaired.toDouble();

      final row = await _client
          .from('profiles')
          .select('balance')
          .eq('id', userId)
          .maybeSingle();
      return (row?['balance'] as num?)?.toDouble() ?? 0;
    } on PostgrestException catch (e) {
      throw ServerFailure('Gagal mengambil saldo: ${e.message}');
    }
  }

  TransactionModel _fromRow(Map<String, dynamic> row) {
    return TransactionModel.fromJson({
      'id': row['id'],
      'userId': row['user_id'],
      'tubeId': row['tube_id'],
      'weightKg': row['weight_kg'],
      'pricePerKg': row['price_per_kg'],
      'totalValue': row['total_value'],
      'type': row['type'],
      'status': row['status'],
      'createdAt': row['created_at'],
    });
  }
}
