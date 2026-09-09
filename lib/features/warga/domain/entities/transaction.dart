enum TransactionType {
  deposit,
  withdrawal,
}

enum TransactionStatus {
  pending,
  success,
  failed,
}

extension TransactionTypeX on TransactionType {
  String get label {
    switch (this) {
      case TransactionType.deposit:
        return 'Setoran Minyak';
      case TransactionType.withdrawal:
        return 'Penarikan Saldo';
    }
  }
}

extension TransactionStatusX on TransactionStatus {
  String get label {
    switch (this) {
      case TransactionStatus.pending:
        return 'Menunggu';
      case TransactionStatus.success:
        return 'Berhasil';
      case TransactionStatus.failed:
        return 'Gagal';
    }
  }
}

class Transaction {
  final String id;
  final String userId;
  final String tubeId;
  final double weightKg;
  final double pricePerKg;
  final double totalValue;
  final TransactionType type;
  final TransactionStatus status;
  final DateTime createdAt;

  const Transaction({
    required this.id,
    required this.userId,
    required this.tubeId,
    required this.weightKg,
    required this.pricePerKg,
    required this.totalValue,
    required this.type,
    required this.status,
    required this.createdAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Transaction &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
