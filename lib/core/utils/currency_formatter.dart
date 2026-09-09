import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  static String format(double amount) {
    return _formatter.format(amount);
  }

  static String formatKg(double weight) {
    if (weight % 1 == 0) {
      return '${weight.toInt()} kg';
    }
    return '${weight.toStringAsFixed(1)} kg';
  }
}
