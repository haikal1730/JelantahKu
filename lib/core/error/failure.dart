/// Base Failure class for Clean Architecture domain layer
abstract class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => message;
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Terjadi kesalahan pada server.']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Terjadi kesalahan pada penyimpanan lokal.']);
}

class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'Data input tidak valid.']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Gagal terhubung ke jaringan.']);
}
