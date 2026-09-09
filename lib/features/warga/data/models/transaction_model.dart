import '../../domain/entities/transaction.dart';

class TransactionModel extends Transaction {
  const TransactionModel({
    required super.id,
    required super.userId,
    required super.tubeId,
    required super.weightKg,
    required super.pricePerKg,
    required super.totalValue,
    required super.type,
    required super.status,
    required super.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      tubeId: json['tubeId'] as String,
      weightKg: (json['weightKg'] as num).toDouble(),
      pricePerKg: (json['pricePerKg'] as num).toDouble(),
      totalValue: (json['totalValue'] as num).toDouble(),
      type: TransactionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TransactionType.deposit,
      ),
      status: TransactionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TransactionStatus.success,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'tubeId': tubeId,
      'weightKg': weightKg,
      'pricePerKg': pricePerKg,
      'totalValue': totalValue,
      'type': type.name,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory TransactionModel.fromEntity(Transaction entity) {
    return TransactionModel(
      id: entity.id,
      userId: entity.userId,
      tubeId: entity.tubeId,
      weightKg: entity.weightKg,
      pricePerKg: entity.pricePerKg,
      totalValue: entity.totalValue,
      type: entity.type,
      status: entity.status,
      createdAt: entity.createdAt,
    );
  }
}
