import 'dart:io';

/// Utilitas pengujian inspeksi (static testing) berbasis checklist.
///
/// `flutter test` dijalankan dari root package, sehingga seluruh path di sini
/// relatif terhadap root repositori.

String readSource(String relativePath) {
  final file = File(relativePath);
  if (!file.existsSync()) {
    throw StateError('Berkas inspeksi tidak ditemukan: $relativePath');
  }
  // Checkout di Windows memakai CRLF; samakan agar pola per-baris konsisten.
  return file.readAsStringSync().replaceAll('\r\n', '\n');
}

/// Seluruh berkas `.dart` di bawah [relativeDir], dengan separator `/`.
List<String> dartFilesIn(String relativeDir) {
  final dir = Directory(relativeDir);
  if (!dir.existsSync()) return const [];
  return dir
      .listSync(recursive: true)
      .whereType<File>()
      .map((file) => file.path.replaceAll(r'\', '/'))
      .where((path) => path.endsWith('.dart'))
      .toList()
    ..sort();
}

/// Nama subfolder langsung di bawah [relativeDir].
List<String> subfoldersOf(String relativeDir) {
  return Directory(relativeDir)
      .listSync()
      .whereType<Directory>()
      .map((dir) => dir.path.replaceAll(r'\', '/').split('/').last)
      .toList()
    ..sort();
}

final _importPattern = RegExp(
  r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
  multiLine: true,
);

/// Target import/export sebuah berkas Dart. Import relatif dan
/// `package:jelantah_ku/` dinormalisasi menjadi path dari root (`lib/...`).
List<String> importsOf(String dartFile) {
  return _importPattern
      .allMatches(readSource(dartFile))
      .map((match) => _resolveImport(dartFile, match.group(1)!))
      .toList();
}

String _resolveImport(String fromFile, String target) {
  const ownPackage = 'package:jelantah_ku/';
  if (target.startsWith(ownPackage)) {
    return 'lib/${target.substring(ownPackage.length)}';
  }
  if (target.startsWith('dart:') || target.startsWith('package:')) {
    return target;
  }
  return Uri.parse(fromFile).resolve(target).path;
}

/// Lokasi blok duplikat pertama pada [dartFile]: [window] baris kode berurutan
/// (tanpa baris kosong, komentar, dan import) yang muncul lebih dari sekali.
String? firstDuplicatedBlock(String dartFile, {int window = 8}) {
  final raw = readSource(dartFile).split('\n');
  final lines = <({int number, String text})>[];
  for (var i = 0; i < raw.length; i++) {
    final text = raw[i].trim();
    if (text.isEmpty || text.startsWith('//') || text.startsWith('import ')) {
      continue;
    }
    lines.add((number: i + 1, text: text));
  }

  final seen = <String, int>{};
  for (var i = 0; i + window <= lines.length; i++) {
    final block = lines.sublist(i, i + window).map((l) => l.text).join('\n');
    final firstLine = seen[block];
    if (firstLine != null) {
      return '$dartFile (baris $firstLine dan ${lines[i].number})';
    }
    seen[block] = lines[i].number;
  }
  return null;
}

/// Path berkas migrasi Supabase, berurutan sesuai nama berkas.
List<String> migrationFiles() {
  return Directory('supabase/migrations')
      .listSync()
      .whereType<File>()
      .map((file) => file.path.replaceAll(r'\', '/'))
      .where((path) => path.endsWith('.sql'))
      .toList()
    ..sort();
}

/// Gabungan seluruh migrasi dalam huruf kecil.
String allMigrationsSql() {
  return migrationFiles().map(readSource).join('\n').toLowerCase();
}

final createTablePattern = RegExp(
  r'create table (?:if not exists )?public\.(\w+)',
);

/// Nama tabel `public.*` yang dibuat pada [sql].
Set<String> tablesIn(String sql) {
  return createTablePattern.allMatches(sql).map((m) => m.group(1)!).toSet();
}

class SqlFunction {
  const SqlFunction({
    required this.name,
    required this.header,
    required this.body,
  });

  final String name;

  /// Bagian antara nama fungsi dan `as $$` (parameter, language, security).
  final String header;
  final String body;
}

final _functionPattern = RegExp(
  r'create or replace function public\.(\w+)\s*\(([\s\S]*?)\bas \$\$([\s\S]*?)\$\$;',
);

/// Seluruh definisi fungsi `public.*` pada [sql], sesuai urutan migrasi.
List<SqlFunction> sqlFunctions(String sql) {
  return _functionPattern
      .allMatches(sql)
      .map(
        (match) => SqlFunction(
          name: match.group(1)!,
          header: match.group(2)!,
          body: match.group(3)!,
        ),
      )
      .toList();
}