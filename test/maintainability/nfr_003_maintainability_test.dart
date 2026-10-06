import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:jelantah_ku/core/config/app_config.dart';
import 'package:jelantah_ku/core/network/api_client.dart';
import 'package:jelantah_ku/features/warga/data/datasources/transaction_mock_datasource.dart';
import 'package:jelantah_ku/features/warga/data/models/transaction_model.dart';
import 'package:jelantah_ku/features/warga/data/repositories/transaction_repository_impl.dart';
import 'package:jelantah_ku/features/warga/domain/entities/transaction.dart';
import 'package:jelantah_ku/features/warga/domain/repositories/transaction_repository.dart';
import 'package:jelantah_ku/features/warga/domain/usecases/confirm_deposit.dart';
import 'package:jelantah_ku/features/warga/domain/usecases/get_user_balance.dart';

import '../support/inspection_support.dart';

class _FakeDataSource implements TransactionDataSource {
  @override
  Future<double> getUserBalance(String userId) async => 7500;

  @override
  Future<List<TransactionModel>> getTransactions(String userId) async => [];

  @override
  Future<TransactionModel?> getTransactionById(String id) async => null;

  @override
  Future<TransactionModel> createTransaction(TransactionModel transaction) async =>
      transaction;
}

class _FakeRepository implements TransactionRepository {
  final created = <Transaction>[];

  @override
  Future<double> getUserBalance(String userId) async => 42000;

  @override
  Future<List<Transaction>> getTransactions(String userId) async => created;

  @override
  Future<Transaction?> getTransactionById(String id) async => null;

  @override
  Future<Transaction> createTransaction(Transaction transaction) async {
    created.add(transaction);
    return transaction;
  }
}

/// NFR-003 — Maintainability (Modularity, Testability, Analysability,
/// Modifiability, Reusability).
///
/// Kode harus modular mengikuti Clean Architecture, dapat diuji dengan
/// dependensi tiruan, mudah dianalisis, serta bebas duplikasi dan kode mati.
void main() {
  const layers = {'data', 'domain', 'presentation'};
  final features = subfoldersOf('lib/features');

  // Domain hanya boleh bergantung pada dart:*, domain fitur yang sama, dan
  // tipe Failure bersama.
  List<String> impureDomainImports(String feature) {
    final violations = <String>[];
    for (final file in dartFilesIn('lib/features/$feature/domain')) {
      for (final target in importsOf(file)) {
        final allowed = target.startsWith('dart:') ||
            target.startsWith('lib/features/$feature/domain/') ||
            target.startsWith('lib/core/error/');
        if (!allowed) violations.add('$file -> $target');
      }
    }
    return violations;
  }

  group('NFR-003 Maintainability — modularitas (Clean Architecture)', () {
    test('TC-MNT-003-01: setiap fitur hanya berisi lapisan data/domain/presentation', () {
      expect(features, isNotEmpty);
      for (final feature in features) {
        expect(
          subfoldersOf('lib/features/$feature'),
          everyElement(isIn(layers)),
          reason: feature,
        );
      }
    });

    test('TC-MNT-003-02: domain fitur warga bebas dari framework dan infrastruktur', () {
      expect(dartFilesIn('lib/features/warga/domain'), isNotEmpty);
      expect(impureDomainImports('warga'), isEmpty);
    });

    test('TC-MNT-003-03: domain fitur auth bebas dari framework dan infrastruktur', () {
      expect(dartFilesIn('lib/features/auth/domain'), isNotEmpty);
      expect(impureDomainImports('auth'), isEmpty);
    });

    test('TC-MNT-003-04: domain fitur payment bebas dari framework dan infrastruktur', () {
      expect(dartFilesIn('lib/features/payment/domain'), isNotEmpty);
      expect(impureDomainImports('payment'), isEmpty);
    });

    test('TC-MNT-003-05: lapisan data tidak bergantung pada lapisan presentation', () {
      final violations = <String>[];
      for (final feature in features) {
        for (final file in dartFilesIn('lib/features/$feature/data')) {
          violations.addAll(
            importsOf(file)
                .where((target) => target.contains('/presentation/'))
                .map((target) => '$file -> $target'),
          );
        }
      }

      expect(violations, isEmpty);
    });

    test('TC-MNT-003-06: modul core tidak bergantung pada modul fitur', () {
      final violations = <String>[];
      for (final file in dartFilesIn('lib/core')) {
        violations.addAll(
          importsOf(file)
              .where((target) => target.startsWith('lib/features/'))
              .map((target) => '$file -> $target'),
        );
      }

      expect(violations, isEmpty);
    });

    test('TC-MNT-003-07: lapisan presentation tidak mengakses Supabase/HTTP secara langsung', () {
      const infrastructure = [
        'package:supabase_flutter/',
        'package:http/',
        'lib/core/supabase/',
        'lib/core/network/api_client.dart',
      ];
      final presentationFiles = [
        ...dartFilesIn('lib/presentation'),
        for (final feature in features)
          ...dartFilesIn('lib/features/$feature/presentation'),
      ];

      final violations = <String>[];
      for (final file in presentationFiles) {
        violations.addAll(
          importsOf(file)
              .where((target) => infrastructure.any(target.startsWith))
              .map((target) => '$file -> $target'),
        );
      }

      expect(presentationFiles, isNotEmpty);
      expect(violations, isEmpty);
    });
  });

  group('NFR-003 Maintainability — testability', () {
    test('TC-MNT-003-08: service infrastruktur menerima dependensi tiruan lewat constructor', () async {
      // Arrange
      AppConfig.apiBaseUrl = 'https://api.jelantahku.test';
      addTearDown(() => AppConfig.apiBaseUrl = '');
      final api = ApiClient(
        client: MockClient((_) async => http.Response('{"ok":true}', 200)),
      );
      final repository = TransactionRepositoryImpl(dataSource: _FakeDataSource());

      // Act & Assert
      expect(await api.getJson('/health'), {'ok': true});
      expect(await repository.getUserBalance('user-1'), 7500);
    });

    test('TC-MNT-003-09: use case bergantung pada abstraksi TransactionRepository', () async {
      // Arrange
      final repository = _FakeRepository();

      // Act
      final balance = await GetUserBalance(repository).execute('user-1');
      final deposit = await ConfirmDeposit(repository: repository).execute(
        userId: 'user-1',
        tubeId: 'TAB-001',
        weightKg: 2,
        pricePerKg: 5000,
      );

      // Assert
      expect(balance, 42000);
      expect(deposit.totalValue, 10000);
      expect(repository.created.single.id, deposit.id);
    });
  });

  group('NFR-003 Maintainability — analysability', () {
    final libFiles = dartFilesIn('lib');

    test('TC-MNT-003-10: lint flutter_lints aktif dan tidak ada rule yang dimatikan', () {
      final analysis = readSource('analysis_options.yaml');

      expect(analysis, contains('include: package:flutter_lints/flutter.yaml'));
      expect(
        readSource('pubspec.yaml'),
        contains(RegExp(r'^\s+flutter_lints:', multiLine: true)),
      );
      expect(
        analysis,
        isNot(contains(RegExp(r'^\s+\w+:\s*false', multiLine: true))),
      );
    });

    test('TC-MNT-003-11: tidak ada print/debugPrint maupun TODO/FIXME tertinggal di lib/', () {
      final leftover = RegExp(r'\b(print|debugPrint)\s*\(|\b(TODO|FIXME)\b');

      final offenders =
          libFiles.where((file) => leftover.hasMatch(readSource(file)));

      expect(offenders, isEmpty);
    });

    test('TC-MNT-003-12: ukuran setiap berkas sumber tidak melebihi 500 baris', () {
      const maxLines = 500;

      final oversized = {
        for (final file in libFiles)
          if (readSource(file).split('\n').length > maxLines)
            file: readSource(file).split('\n').length,
      };

      expect(libFiles, isNotEmpty);
      expect(oversized, isEmpty);
    });
  });

  group('NFR-003 Maintainability — modifiability dan reusability', () {
    final libFiles = dartFilesIn('lib');

    test('TC-MNT-003-13: tidak ada blok kode duplikat (>= 8 baris) di lapisan non-UI', () {
      // core/constants berisi deklarasi tema (UI), bukan logika.
      final nonUiFiles = [
        ...dartFilesIn('lib/core')
            .where((file) => !file.startsWith('lib/core/constants/')),
        for (final feature in features) ...[
          ...dartFilesIn('lib/features/$feature/data'),
          ...dartFilesIn('lib/features/$feature/domain'),
        ],
      ];

      final duplicated = nonUiFiles.map(firstDuplicatedBlock).nonNulls.toList();

      expect(duplicated, isEmpty);
    });

    test('TC-MNT-003-14: tidak ada berkas Dart yang tidak dirujuk (kode mati)', () {
      final referenced = libFiles.expand(importsOf).toSet();

      final unreferenced = libFiles
          .where((file) => file != 'lib/main.dart')
          .where((file) => !referenced.contains(file))
          .toList();

      expect(unreferenced, isEmpty);
    });

    test('TC-MNT-003-15: konfigurasi environment terpusat di AppConfig', () {
      final readers = libFiles
          .where((file) => readSource(file).contains('fromEnvironment('))
          .toList();

      expect(readers, ['lib/core/config/app_config.dart']);
    });

    test('TC-MNT-003-16: dependensi pihak ketiga (node_modules) tidak di-commit ke repositori', () {
      final tracked = Process.runSync(
        'git',
        ['ls-files', '--', 'backend/node_modules'],
      ).stdout.toString().trim();
      final trackedCount = tracked.isEmpty ? 0 : tracked.split('\n').length;
      final ignored = readSource('.gitignore')
          .split('\n')
          .any((rule) => rule.contains('node_modules'));

      expect(trackedCount, 0, reason: 'berkas node_modules ter-track oleh git');
      expect(ignored, isTrue, reason: '.gitignore belum memuat node_modules');
    });

    test('TC-MNT-003-17: setiap tabel didefinisikan tepat satu kali di seluruh migrasi', () {
      final definedIn = <String, List<String>>{};
      for (final file in migrationFiles()) {
        for (final table in tablesIn(readSource(file).toLowerCase())) {
          definedIn.putIfAbsent(table, () => []).add(file.split('/').last);
        }
      }

      final redefined = Map.of(definedIn)
        ..removeWhere((table, files) => files.length == 1);

      expect(definedIn, isNotEmpty);
      expect(redefined, isEmpty);
    });
  });
}