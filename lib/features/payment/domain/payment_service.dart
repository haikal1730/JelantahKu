import 'dart:math';

import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_config.dart';
import '../../../core/error/failure.dart';
import '../../../core/network/api_client.dart';
import '../../../core/security/secure_storage_service.dart';
import '../../../core/supabase/supabase_client.dart';

class PaymentResult {
  const PaymentResult({
    required this.orderId,
    required this.status,
    this.redirectUrl,
    this.token,
  });

  final String orderId;
  final String status;
  final String? redirectUrl;
  final String? token;

  bool get isPaid => status == 'paid' || status == 'settlement' || status == 'capture';
  bool get isPending => status == 'pending';
}

class PaymentHistoryItem {
  const PaymentHistoryItem({
    required this.orderId,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.paidAt,
  });

  final String orderId;
  final num amount;
  final String status;
  final DateTime createdAt;
  final DateTime? paidAt;

  factory PaymentHistoryItem.fromMap(Map<String, dynamic> map) => PaymentHistoryItem(
        orderId: map['order_id'] as String,
        amount: (map['amount'] as num?) ?? 0,
        status: (map['status'] as String?) ?? 'pending',
        createdAt: DateTime.parse(map['created_at'] as String),
        paidAt: map['paid_at'] == null ? null : DateTime.tryParse(map['paid_at'] as String),
      );
}

abstract class PaymentService {
  Future<PaymentResult> createSubscription({required String userId, required int amount});
  Future<PaymentResult> getPaymentStatus(String orderId);
  Future<List<PaymentHistoryItem>> getHistory(String userId);
  Future<bool> openRedirectUrl(String? url);
}

class MockPaymentService implements PaymentService {
  @override
  Future<PaymentResult> createSubscription({required String userId, required int amount}) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    return PaymentResult(
      orderId: 'DEMO-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(999)}',
      status: 'paid',
    );
  }

  @override
  Future<PaymentResult> getPaymentStatus(String orderId) async =>
      PaymentResult(orderId: orderId, status: 'paid');

  @override
  Future<List<PaymentHistoryItem>> getHistory(String userId) async => const [];

  @override
  Future<bool> openRedirectUrl(String? url) async => false;
}

class BackendPaymentService implements PaymentService {
  BackendPaymentService(this._api, {SecureStorageService? storage})
      : _storage = storage ?? SecureStorageService();

  final ApiClient _api;
  final SecureStorageService _storage;

  Future<String> _token() async {
    final token = AppConfig.hasSupabaseConfig
        ? SupabaseService.client.auth.currentSession?.accessToken
        : await _storage.readToken();
    if (token == null || token.isEmpty) {
      throw const ServerFailure('Sesi login tidak valid. Silakan login ulang.');
    }
    return token;
  }

  @override
  Future<PaymentResult> createSubscription({required String userId, required int amount}) async {
    final response = await _api.postJson(
      '/payments/subscription',
      headers: {'Authorization': 'Bearer ${await _token()}'},
      body: {'amount': amount},
    );
    final orderId = response['orderId'] as String?;
    if (orderId == null || orderId.isEmpty) {
      throw const ServerFailure('Backend payment tidak mengembalikan orderId.');
    }
    return PaymentResult(
      orderId: orderId,
      status: (response['status'] as String?) ?? 'pending',
      redirectUrl: response['redirectUrl'] as String?,
      token: response['token'] as String?,
    );
  }

  @override
  Future<PaymentResult> getPaymentStatus(String orderId) async {
    final response = await _api.getJson(
      '/payments/subscription/${Uri.encodeComponent(orderId)}',
      headers: {'Authorization': 'Bearer ${await _token()}'},
    );
    return PaymentResult(
      orderId: response['order_id'] as String,
      status: (response['status'] as String?) ?? 'pending',
    );
  }

  @override
  Future<List<PaymentHistoryItem>> getHistory(String userId) async {
    if (!AppConfig.hasSupabaseConfig) return const [];
    final rows = await SupabaseService.client
        .from('payments')
        .select('order_id,amount,status,created_at,paid_at')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((row) => PaymentHistoryItem.fromMap(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  @override
  Future<bool> openRedirectUrl(String? url) async {
    if (url == null || url.isEmpty) return false;
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class PaymentServiceFactory {
  static PaymentService create() {
    if (AppConfig.paymentMode == 'real' && AppConfig.hasPaymentApi) {
      return BackendPaymentService(ApiClient());
    }
    return MockPaymentService();
  }
}
