/// UseCase responsible for computing total monetary value of cooking oil deposit.
/// Business rule: totalValue = weightKg * pricePerKg
class CalculateDepositValue {
  const CalculateDepositValue();

  double execute({
    required double weightKg,
    required double pricePerKg,
  }) {
    if (weightKg < 0 || pricePerKg < 0) {
      throw ArgumentError('Weight and price per kg cannot be negative.');
    }
    return weightKg * pricePerKg;
  }
}
