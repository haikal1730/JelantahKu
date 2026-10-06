import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:jelantah_ku/core/config/app_config.dart';
import 'package:jelantah_ku/core/error/failure.dart';
import 'package:jelantah_ku/core/network/api_client.dart';
import 'package:jelantah_ku/core/security/secure_storage_service.dart';
import 'package:jelantah_ku/features/auth/data/auth_service.dart';
import 'package:jelantah_ku/features/auth/domain/entities/user_role.dart';
import 'package:jelantah_ku/features/payment/domain/payment_service.dart';

import '../support/inspection_support.dart';

/// NFR-002 — Security (Authenticity, Access Control & Integrity).
///
/// Setiap akses data harus terautentikasi dan terotorisasi per pengguna/role
/// (least privilege), dan setiap input divalidasi sebelum diproses, baik di
/// klien, backend pembayaran, maupun database.
void main() {
  Matcher validationFailure(String message) => throwsA(
        isA<ValidationFailure>().having((f) => f.message, 'message', message),
      );

  group('NFR-002 Access Control — validasi input dan autentikasi klien', () {
    late AuthService auth;

    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      auth = AuthService(secureStorage: SecureStorageService());
    });

    test('TC-SEC-002-01: login menolak email dengan format tidak valid', () {
      for (final email in ['bukan-email', 'warga@desa', 'warga @desa.id', '@desa.id']) {
        expect(
          () => auth.signInEmail(email: email, password: 'rahasia123'),
          validationFailure('Format email tidak valid.'),
          reason: email,
        );
      }
    });

    test('TC-SEC-002-02: login menolak email kosong', () {
      for (final email in ['', '   ']) {
        expect(
          () => auth.signInEmail(email: email, password: 'rahasia123'),
          validationFailure('Format email tidak valid.'),
        );
      }
    });

    test('TC-SEC-002-03: password di bawah 6 karakter ditolak (batas 5/6)', () {
      // 5 karakter: ditolak oleh validasi.
      expect(
        () => auth.signInEmail(email: 'warga@desa.id', password: '12345'),
        validationFailure('Password minimal 6 karakter.'),
      );

      // 6 karakter: lolos validasi, berhenti di pengecekan konfigurasi server.
      expect(
        () => auth.signInEmail(email: 'warga@desa.id', password: '123456'),
        throwsA(isA<ServerFailure>()),
      );
    });

    test('TC-SEC-002-04: registrasi menolak nama kurang dari 2 karakter', () {
      expect(
        () => auth.registerEmail(
          name: ' A ',
          email: 'warga@desa.id',
          password: 'rahasia123',
        ),
        validationFailure('Nama minimal 2 karakter.'),
      );
    });

    test('TC-SEC-002-05: tanpa konfigurasi Supabase, autentikasi gagal tertutup (tanpa akun demo)', () async {
      // Arrange: sisa sesi lokal tidak boleh dianggap sebagai sesi yang sah.
      FlutterSecureStorage.setMockInitialValues({
        'session_user_id': 'user-lama',
        'session_token': 'jwt-lama',
      });

      // Act & Assert
      expect(auth.supabaseAvailable, isFalse);
      expect(await auth.restoreSession(), isNull);
      await expectLater(
        auth.signInEmail(email: 'warga@desa.id', password: 'rahasia123'),
        throwsA(isA<ServerFailure>()),
      );
      await expectLater(auth.signInGoogle(), throwsA(isA<ServerFailure>()));
    });
  });

  group('NFR-002 Access Control — role dan least privilege', () {
    test('TC-SEC-002-06: role tidak dikenal jatuh ke hak akses terendah (warga)', () {
      for (final value in [null, '', 'superadmin', 'root', 1]) {
        expect(UserRole.fromDatabase(value), UserRole.warga, reason: '$value');
      }
    });

    test('TC-SEC-002-07: hanya nilai role dari database yang menaikkan hak akses', () {
      expect(UserRole.fromDatabase('admin'), UserRole.admin);
      expect(UserRole.fromDatabase('ADMIN'), UserRole.admin);
      expect(UserRole.fromDatabase('Owner'), UserRole.owner);
      expect(UserRole.fromDatabase('warga'), UserRole.warga);
    });

    test('TC-SEC-002-08: klien tidak pernah mengirim kolom role saat upsert profil', () {
      final upsertPayload = RegExp(r'\.upsert\(\{([^}]*)\}');
      final payloads = [
        'lib/features/auth/data/auth_service.dart',
        'lib/features/auth/presentation/providers/auth_provider.dart',
      ].expand(
        (file) => upsertPayload.allMatches(readSource(file)).map((m) => m.group(1)!),
      );

      expect(payloads, isNotEmpty);
      expect(payloads.where((payload) => payload.contains("'role'")), isEmpty);
    });
  });

  group('NFR-002 Access Control — klien pembayaran', () {
    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      AppConfig.apiBaseUrl = 'https://api.jelantahku.test';
    });

    tearDown(() => AppConfig.apiBaseUrl = '');

    test('TC-SEC-002-09: permintaan pembayaran tanpa token sesi ditolak sebelum dikirim', () async {
      // Arrange
      var sentRequests = 0;
      final service = BackendPaymentService(
        ApiClient(
          client: MockClient((_) async {
            sentRequests++;
            return http.Response('{}', 200);
          }),
        ),
      );

      // Act & Assert
      await expectLater(
        service.createSubscription(userId: 'user-123', amount: 25000),
        throwsA(isA<ServerFailure>()),
      );
      expect(sentRequests, 0);
    });

    test('TC-SEC-002-10: permintaan pembayaran membawa Bearer token dan tidak mengirim userId', () async {
      // Arrange
      FlutterSecureStorage.setMockInitialValues({'session_token': 'jwt-abc'});
      late http.Request captured;
      final service = BackendPaymentService(
        ApiClient(
          client: MockClient((request) async {
            captured = request;
            return http.Response(
              jsonEncode({'orderId': 'JELANTAH-1', 'status': 'pending'}),
              200,
            );
          }),
        ),
      );

      // Act
      final result = await service.createSubscription(
        userId: 'user-orang-lain',
        amount: 25000,
      );

      // Assert
      expect(captured.headers['Authorization'], 'Bearer jwt-abc');
      expect(jsonDecode(captured.body), {'amount': 25000});
      expect(result.orderId, 'JELANTAH-1');
    });

    test('TC-SEC-002-11: orderId di-encode sehingga tidak dapat menyisipkan path/query', () async {
      // Arrange
      FlutterSecureStorage.setMockInitialValues({'session_token': 'jwt-abc'});
      late http.Request captured;
      final service = BackendPaymentService(
        ApiClient(
          client: MockClient((request) async {
            captured = request;
            return http.Response(
              jsonEncode({'order_id': 'JELANTAH-1', 'status': 'pending'}),
              200,
            );
          }),
        ),
      );

      // Act
      await service.getPaymentStatus('../../admin?role=owner');

      // Assert
      expect(
        captured.url.pathSegments,
        ['payments', 'subscription', '../../admin?role=owner'],
      );
      expect(captured.url.hasQuery, isFalse);
    });
  });

  group('NFR-002 Access Control — backend pembayaran (backend/server.js)', () {
    final server = readSource('backend/server.js');
    final routePattern = RegExp(
      r'''app\.(get|post|put|patch|delete)\(\s*'([^']+)'\s*,\s*(\w+)?''',
    );

    String handlerOf(String route) {
      final start = server.indexOf("'$route'");
      final next = server.indexOf('\napp.', start);
      return server.substring(start, next < 0 ? server.length : next);
    }

    test('TC-SEC-002-12: seluruh endpoint non-publik dilindungi middleware autentikasi', () {
      const publicRoutes = {'/health', '/payments/midtrans/webhook'};
      final routes = routePattern.allMatches(server).toList();

      final unprotected = routes
          .where((route) => !publicRoutes.contains(route.group(2)))
          .where((route) => route.group(3) != 'requireSupabaseUser')
          .map((route) => route.group(2));

      expect(routes.length, greaterThan(publicRoutes.length));
      expect(unprotected, isEmpty);
    });

    test('TC-SEC-002-13: middleware menolak permintaan tanpa Bearer token yang valid (401)', () {
      final middleware = server.substring(
        server.indexOf('async function requireSupabaseUser'),
        server.indexOf("app.get('/health'"),
      );

      expect(middleware, contains("auth.startsWith('Bearer ')"));
      expect(middleware, contains('supabaseAdmin.auth.getUser(token)'));
      expect('status(401)'.allMatches(middleware), hasLength(3));
      expect(
        middleware.indexOf('next()'),
        greaterThan(middleware.indexOf('getUser(token)')),
      );
    });

    test('TC-SEC-002-14: identitas pengguna diambil dari JWT, bukan dari body request', () {
      expect(server, contains('const userId = req.user.id'));
      expect(
        server,
        isNot(contains(RegExp(r'req\.(body|query|params)\.(userId|user_id)'))),
      );
    });

    test('TC-SEC-002-15: nominal langganan divalidasi ulang di server', () {
      final handler = handlerOf('/payments/subscription');

      expect(handler, contains('Number.isInteger(amount)'));
      expect(handler, contains('amount !== 25000'));
      expect(handler, contains('status(400)'));
    });

    test('TC-SEC-002-16: status pembayaran hanya dapat dibaca oleh pemiliknya', () {
      final handler = handlerOf('/payments/subscription/:orderId');

      expect(handler, contains(".eq('order_id', req.params.orderId)"));
      expect(handler, contains(".eq('user_id', req.user.id)"));
    });

    test('TC-SEC-002-17: webhook memverifikasi status ke Midtrans sebelum mengaktifkan Premium', () {
      final webhook = handlerOf('/payments/midtrans/webhook');
      final verifiedAt = webhook.indexOf('snap.transaction.status(orderId)');
      final activatedAt = webhook.indexOf('subscription_active: true');

      expect(verifiedAt, isNonNegative);
      expect(activatedAt, greaterThan(verifiedAt));
      expect(webhook, contains('paymentStatus(transaction)'));
      expect(webhook, isNot(contains('paymentStatus(req.body)')));
    });
  });

  group('NFR-002 Access Control — database (supabase/migrations)', () {
    final sql = allMigrationsSql();
    final tables = tablesIn(sql);
    final functions = sqlFunctions(sql);

    // Definisi terakhir adalah yang berlaku setelah seluruh migrasi dijalankan.
    final createTransaction =
        functions.lastWhere((f) => f.name == 'create_transaction');

    test('TC-SEC-002-18: Row Level Security aktif pada setiap tabel', () {
      final withoutRls = tables.where(
        (table) => !sql.contains(
          'alter table public.$table enable row level security',
        ),
      );

      expect(tables, isNotEmpty);
      expect(withoutRls, isEmpty);
    });

    test('TC-SEC-002-19: akses anon dicabut dari setiap tabel', () {
      final openToAnon = tables.where(
        (table) => !sql.contains('revoke all on public.$table from anon'),
      );

      expect(openToAnon, isEmpty);
    });

    test('TC-SEC-002-20: setiap policy membatasi akses berdasarkan auth.uid()', () {
      final policies = RegExp(r'create policy[\s\S]*?;')
          .allMatches(sql)
          .map((match) => match.group(0)!)
          .toList();

      expect(policies, isNotEmpty);
      expect(policies.where((p) => !p.contains('auth.uid()')), isEmpty);
    });

    test('TC-SEC-002-21: klien hanya diberi hak SELECT pada tabel finansial', () {
      final grants = RegExp(
        r'grant ([\w, ]+) on public\.(transactions|payments) to authenticated',
      ).allMatches(sql).toList();

      expect(grants, hasLength(2));
      expect(grants.map((grant) => grant.group(1)!.trim()), everyElement('select'));
    });

    test('TC-SEC-002-22: fungsi SECURITY DEFINER mengunci search_path dan memeriksa auth.uid()', () {
      final definers =
          functions.where((f) => f.header.contains('security definer'));
      final rpcs = definers.where(
        (f) => {'create_transaction', 'repair_my_balance'}.contains(f.name),
      );

      expect(rpcs, isNotEmpty);
      expect(
        definers.where((f) => !f.header.contains('set search_path')),
        isEmpty,
      );
      expect(
        rpcs.where(
          (f) => !f.body.contains('auth.uid()') || !f.body.contains('not authorized'),
        ),
        isEmpty,
      );
    });

    test('TC-SEC-002-23: trigger melindungi kolom balance, role, dan langganan dari update klien', () {
      final guard = functions.lastWhere(
        (f) => f.name == 'protect_profile_financial_fields',
      );

      expect(guard.body, contains('new.balance := old.balance'));
      expect(guard.body, contains('new.role := old.role'));
      expect(
        guard.body,
        contains('new.subscription_active := old.subscription_active'),
      );
      expect(
        sql,
        contains(
          RegExp(
            r'create trigger protect_profile_financial_fields\s+before update on public\.profiles',
          ),
        ),
      );
    });

    test('TC-SEC-002-24: RPC create_transaction menghitung ulang nilai transaksi di server', () {
      final recomputed = RegExp(r'p_weight_kg\s*\*\s*p_price_per_kg');

      expect(
        recomputed.hasMatch(createTransaction.body),
        isTrue,
        reason: 'p_total_value dan p_status dari klien dipakai apa adanya untuk '
            'mengubah saldo, sehingga pengguna dapat mengkredit saldonya sendiri.',
      );
    });

    test('TC-SEC-002-25: pencarian idempotensi create_transaction dibatasi ke pemilik transaksi', () {
      final lookup = RegExp(r'select \* into existing_tx[\s\S]*?;')
          .firstMatch(createTransaction.body)!
          .group(0)!;

      expect(
        lookup,
        contains('user_id'),
        reason: 'Fungsi SECURITY DEFINER mengembalikan transaksi milik pengguna '
            'lain bila p_id sama (ID transaksi dapat ditebak).',
      );
    });
  });
}