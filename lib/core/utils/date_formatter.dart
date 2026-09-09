import 'package:intl/intl.dart';

class DateFormatter {
  static final DateFormat _dateTimeFormat = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');
  static final DateFormat _dateFormat = DateFormat('dd MMMM yyyy', 'id_ID');

  static String formatDateTime(DateTime dateTime) {
    try {
      return _dateTimeFormat.format(dateTime);
    } catch (_) {
      return DateFormat('dd MMM yyyy, HH:mm').format(dateTime);
    }
  }

  static String formatDate(DateTime dateTime) {
    try {
      return _dateFormat.format(dateTime);
    } catch (_) {
      return DateFormat('dd MMM yyyy').format(dateTime);
    }
  }
}
