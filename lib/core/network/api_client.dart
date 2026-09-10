
import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../error/failure.dart';

/// HTTP client sederhana dengan timeout + retry exponential backoff.
/// Jangan pernah menaruh secret key payment gateway di aplikasi Flutter.
class ApiClient {
  ApiClient({
    http.Client? client,
    this.maxAttempts = 3,
    this.timeout = const Duration(seconds: 12),
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final int maxAttempts;
  final Duration timeout;

  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    if (!AppConfig.hasApi) {
      throw const NetworkFailure('API_BASE_URL belum dikonfigurasi.');
    }

    final uri = Uri.parse('${AppConfig.apiBaseUrl}$path');
    return _request(
      () => _client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          ...?headers,
        },
        body: jsonEncode(body ?? {}),
      ),
    );
  }

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String>? headers,
  }) async {
    if (!AppConfig.hasApi) {
      throw const NetworkFailure('API_BASE_URL belum dikonfigurasi.');
    }

    final uri = Uri.parse('${AppConfig.apiBaseUrl}$path');
    return _request(
      () => _client.get(
        uri,
        headers: {
          'Accept': 'application/json',
          ...?headers,
        },
      ),
    );
  }

  Future<Map<String, dynamic>> _request(
    Future<http.Response> Function() request,
  ) async {
    Object? lastError;

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final response = await request().timeout(timeout);

        if (response.statusCode >= 200 && response.statusCode < 300) {
          if (response.body.trim().isEmpty) return <String, dynamic>{};
          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic>) return decoded;
          throw const ServerFailure('Format respons API tidak valid.');
        }

        // 4xx bukan transient error: jangan retry tanpa alasan.
        if (response.statusCode >= 400 && response.statusCode < 500) {
          var detail = '';

          try {
            final decoded = jsonDecode(response.body);
            if (decoded is Map && decoded['message'] != null) {
              detail = ': ${decoded['message']}';
            } else if (decoded is Map && decoded['error'] != null) {
              detail = ': ${decoded['error']}';
            }
          } catch (_) {
            if (response.body.trim().isNotEmpty) {
              detail = ': ${response.body.trim()}';
            }
          }

          throw ServerFailure(
            'API menolak permintaan (${response.statusCode})$detail',
          );
        }

        lastError = ServerFailure(
          'Server bermasalah (${response.statusCode}).',
        );
      } on TimeoutException {
        lastError = const NetworkFailure(
          'Koneksi timeout. Periksa jaringan internet.',
        );
      } on http.ClientException catch (e) {
        lastError = NetworkFailure('Gagal terhubung ke server: ${e.message}');
      } on Failure {
        rethrow;
      } catch (e) {
        lastError = NetworkFailure('Network error: $e');
      }

      if (attempt < maxAttempts) {
        await Future<void>.delayed(Duration(milliseconds: 500 * (1 << (attempt - 1))));
      }
    }

    if (lastError is Failure) throw lastError!;
    throw const NetworkFailure('Permintaan gagal setelah beberapa percobaan.');
  }

  void close() => _client.close();
}
