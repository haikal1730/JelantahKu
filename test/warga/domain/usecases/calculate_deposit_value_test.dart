import 'package:flutter_test/flutter_test.dart';
import 'package:jelantah_ku/features/warga/domain/usecases/calculate_deposit_value.dart';

void main() {
  late CalculateDepositValue useCase;

  setUp(() {
    useCase = const CalculateDepositValue();
  });

  group('CalculateDepositValue UseCase Tests', () {
    test('Test 1: Calculate deposit 5 kg x Rp 5.000 = Rp 25.000', () {
      // Arrange
      const double weight = 5.0;
      const double price = 5000.0;

      // Act
      final result = useCase.execute(weightKg: weight, pricePerKg: price);

      // Assert
      expect(result, 25000.0);
    });

    test('Test 2: Calculate deposit 0 kg x Rp 5.000 = Rp 0', () {
      // Arrange
      const double weight = 0.0;
      const double price = 5000.0;

      // Act
      final result = useCase.execute(weightKg: weight, pricePerKg: price);

      // Assert
      expect(result, 0.0);
    });

    test('Calculate deposit with fractional weight e.g., 2.5 kg x Rp 5.000 = Rp 12.500', () {
      // Arrange
      const double weight = 2.5;
      const double price = 5000.0;

      // Act
      final result = useCase.execute(weightKg: weight, pricePerKg: price);

      // Assert
      expect(result, 12500.0);
    });

    test('Throws ArgumentError if negative weight or price is passed', () {
      expect(
        () => useCase.execute(weightKg: -1.0, pricePerKg: 5000.0),
        throwsArgumentError,
      );
      expect(
        () => useCase.execute(weightKg: 5.0, pricePerKg: -5000.0),
        throwsArgumentError,
      );
    });
  });
}
