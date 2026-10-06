import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:jelantah_ku/core/config/app_config.dart';
import 'package:jelantah_ku/core/error/failure.dart';
import 'package:jelantah_ku/core/network/api_client.dart';
import 'package:jelantah_ku/core/security/secure_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/inspection_support.dart';

/// NFR-001 — Security (Confidentiality).
///
/// Kredensial, secret server, dan token sesi tidak boleh terekspos melalui kode
/// sumber klien, repositori, maupun penyimpanan lokal yang tidak terenkripsi.
void main() {
  // Pola secret yang hanya boleh berada di server / environment variable.
  final serverSecretPatterns = <String, RegExp>{
    'Supabase secret key': RegExp(r'sb_secret_[A-Za-z0-9_-]+'),
    'JWT ter-hardcode': RegExp(r'eyJ[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}\.'),
    'Midtrans server key': RegExp(r'(?:SB-)?Mid-server-[A-Za-z0-9_-]{8,}'),
    'Private key': RegExp(r'-----BEGIN [A-Z ]*PRIVATE KEY-----'),
  };

  const clientTextExtensions = ['.dart', '.xml', '.kts', '.json', '.html', '.js'];

  List<String> clientSideFiles() {
    final files = <String>['env.production.json', 'env.apk.json', '.env.example'];
    for (final root in ['lib', 'android/app', 'web']) {
      files.addAll(
        Directory(root)
            .listSync(recursive: true)
            .whereType<File>()
            .map((file) => file.path.replaceAll(r'\', '/'))
            .where((path) => clientTextExtensions.any(path.endsWith)),
      );
    }
    return files;
  }

  group('NFR-001 Confidentiality — penyimpanan sesi', () {
    late SecureStorageService service;

    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      SharedPreferences.setMockInitialValues({});
      service = SecureStorageService();
    });

    test('TC-SEC-001-01: saveSession menyimpan userId dan token di secure storage', () async {
      // Act
      await service.saveSession(userId: 'user-123', token: 'jwt-abc');

      // Assert
      expect(await service.readUserId(), 'user-123');
      expect(await service.readToken(), 'jwt-abc');
      expect(
        await const FlutterSecureStorage().readAll(),
        {'session_user_id': 'user-123', 'session_token': 'jwt-abc'},
      );
    });

    test('TC-SEC-001-02: token sesi tidak pernah ditulis ke SharedPreferences', () async {
      // Act
      await service.saveSession(userId: 'user-123', token: 'jwt-abc');
      await service.saveDemoProfile(email: 'warga@desa.id', name: 'Warga');

      // Assert
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys(), isEmpty);

      final sessionModules = [
        ...dartFilesIn('lib/core/security'),
        ...dartFilesIn('lib/features/auth'),
        ...dartFilesIn('lib/features/payment'),
      ];
      final unencrypted = sessionModules.where(
        (file) => importsOf(file).any(
          (target) =>
              target.startsWith('package:shared_preferences/') ||
              target == 'lib/core/storage/local_storage.dart',
        ),
      );
      expect(unencrypted, isEmpty);
    });

    test('TC-SEC-001-03: clearSession menghapus token dan identitas pengguna saat logout', () async {
      // Arrange
      await service.saveSession(userId: 'user-123', token: 'jwt-abc');
      await service.saveDemoProfile(email: 'warga@desa.id', name: 'Warga');

      // Act
      await service.clearSession();

      // Assert
      expect(await service.readToken(), isNull);
      expect(await service.readUserId(), isNull);
      expect(await service.readDemoEmail(), isNull);
      expect(await service.readDemoName(), isNull);
    });
  });

  group('NFR-001 Confidentiality — secret dan konfigurasi', () {
    test('TC-SEC-001-04: tidak ada secret server pada kode dan konfigurasi sisi klien', () {
      final leaks = <String>[];
      for (final path in clientSideFiles()) {
        final content = readSource(path);
        if (content.toLowerCase().contains('service_role')) {
          leaks.add('$path: service_role');
        }
        serverSecretPatterns.forEach((label, pattern) {
          if (pattern.hasMatch(content)) leaks.add('$path: $label');
        });
      }

      expect(leaks, isEmpty);
    });

    test('TC-SEC-001-05: tidak ada API key yang di-hardcode pada kode sumber Dart', () {
      final googleApiKey = RegExp(r'AIza[0-9A-Za-z_-]{35}');

      final offenders = dartFilesIn('lib')
          .where((file) => googleApiKey.hasMatch(readSource(file)))
          .toList();

      expect(
        offenders,
        isEmpty,
        reason: 'API key harus disuplai lewat --dart-define, bukan literal di kode.',
      );
    });

    test('TC-SEC-001-06: AppConfig hanya membaca --dart-define tanpa default URL/key', () async {
      // Act
      await AppConfig.load();

      // Assert
      expect(AppConfig.supabaseUrl, isEmpty);
      expect(AppConfig.supabasePublishableKey, isEmpty);
      expect(AppConfig.apiBaseUrl, isEmpty);
      expect(AppConfig.firebaseApiKey, isEmpty);
      expect(AppConfig.hasSupabaseConfig, isFalse);
      expect(AppConfig.paymentMode, 'mock');
      expect(
        readSource('lib/core/config/app_config.dart'),
        isNot(contains(RegExp(r'https?://'))),
      );
    });

    test('TC-SEC-001-07: .gitignore mengecualikan berkas env, key.properties, dan keystore', () {
      final rules = readSource('.gitignore')
          .split('\n')
          .map((line) => line.trim())
          .toSet();

      expect(
        rules,
        containsAll([
          '.env',
          '.env.*',
          'backend/.env',
          'android/key.properties',
          'android/*.jks',
          'android/*.keystore',
        ]),
      );
    });

    test('TC-SEC-001-08: berkas contoh environment hanya berisi placeholder', () {
      final sensitiveKey = RegExp(r'KEY|SECRET|TOKEN|PASSWORD');
      final placeholder = RegExp(r'^$|YOUR|X{6,}');
      final realValues = <String>[];

      for (final path in ['.env.example', 'backend/.env.example']) {
        for (final line in readSource(path).split('\n')) {
          final separator = line.indexOf('=');
          if (line.trim().startsWith('#') || separator < 0) continue;
          final key = line.substring(0, separator).trim();
          final value = line.substring(separator + 1).trim();
          if (sensitiveKey.hasMatch(key) && !placeholder.hasMatch(value)) {
            realValues.add('$path: $key');
          }
        }
      }

      final exampleJson =
          jsonDecode(readSource('env.example.json')) as Map<String, dynamic>;
      exampleJson.forEach((key, value) {
        if (sensitiveKey.hasMatch(key) && !placeholder.hasMatch('$value')) {
          realValues.add('env.example.json: $key');
        }
      });

      expect(realValues, isEmpty);
    });

    test('TC-SEC-001-09: backend membaca secret hanya dari environment variable', () {
      final server = readSource('backend/server.js');

      expect(server, contains('process.env.SUPABASE_SERVICE_ROLE_KEY'));
      expect(server, contains('serverKey: process.env.MIDTRANS_SERVER_KEY'));
      serverSecretPatterns.forEach((label, pattern) {
        expect(pattern.hasMatch(server), isFalse, reason: label);
      });
    });

    test('TC-SEC-001-10: konfigurasi produksi yang di-commit hanya memuat nilai publik', () {
      const publicKeys = {
        'API_BASE_URL',
        'PAYMENT_API_URL',
        'USE_SUPABASE',
        'SUPABASE_URL',
        'SUPABASE_PUBLISHABLE_KEY',
        'SUPABASE_REDIRECT_URL',
        'FIREBASE_API_KEY',
        'FIREBASE_APP_ID',
        'FIREBASE_MESSAGING_SENDER_ID',
        'FIREBASE_PROJECT_ID',
        'PAYMENT_MODE',
      };

      for (final path in ['env.production.json', 'env.apk.json']) {
        final config = jsonDecode(readSource(path)) as Map<String, dynamic>;

        expect(config.keys, everyElement(isIn(publicKeys)), reason: path);
        expect(
          config['SUPABASE_PUBLISHABLE_KEY'],
          startsWith('sb_publishable_'),
          reason: path,
        );
      }
    });
  });

  group('NFR-001 Confidentiality — transport dan rilis', () {
    test('TC-SEC-001-11: komunikasi produksi hanya melalui HTTPS (tanpa cleartext)', () {
      final manifest = readSource('android/app/src/main/AndroidManifest.xml');
      expect(manifest, isNot(contains('usesCleartextTraffic="true"')));

      for (final path in ['env.production.json', 'env.apk.json']) {
        final config = jsonDecode(readSource(path)) as Map<String, dynamic>;
        expect(config['API_BASE_URL'], startsWith('https://'), reason: path);
        expect(config['SUPABASE_URL'], startsWith('https://'), reason: path);
      }
    });

    test('TC-SEC-001-12: build rilis Android memakai R8 dan signing dari key.properties', () {
      final gradle = readSource('android/app/build.gradle.kts');

      expect(gradle, contains('isMinifyEnabled = true'));
      expect(gradle, contains('isShrinkResources = true'));
      expect(gradle, contains('rootProject.file("key.properties")'));
      expect(
        gradle,
        isNot(contains(RegExp(r'(storePassword|keyPassword)\s*=\s*"'))),
      );
    });

    test('TC-SEC-001-13: pesan error API tidak membocorkan token Authorization', () async {
      // Arrange
      AppConfig.apiBaseUrl = 'https://api.jelantahku.test';
      addTearDown(() => AppConfig.apiBaseUrl = '');
      final api = ApiClient(
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({'message': 'Token Supabase tidak valid.'}),
            401,
          ),
        ),
      );

      // Act & Assert
      await expectLater(
        api.getJson(
          '/payments/subscription/ORDER-1',
          headers: {'Authorization': 'Bearer jwt-rahasia'},
        ),
        throwsA(
          isA<ServerFailure>().having(
            (failure) => failure.message,
            'message',
            allOf(contains('401'), isNot(contains('jwt-rahasia'))),
          ),
        ),
      );
    });
  });
}