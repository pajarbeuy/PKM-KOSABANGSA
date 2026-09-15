import 'package:intl/intl.dart';

/// Extension and utility class for consistent formatting across PKM Mobile
class AppFormatters {
  AppFormatters._();

  static final NumberFormat _rupiahFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static final NumberFormat _decimalFormat = NumberFormat('#,##0.##', 'id_ID');

  static final DateFormat _indonesianDateFormat = DateFormat('d MMM yyyy', 'id_ID');
  static final DateFormat _indonesianDateTimeFormat = DateFormat('d MMM yyyy, HH:mm', 'id_ID');

  /// Format number to Indonesian Rupiah (e.g. Rp 1.500.000)
  static String formatRupiah(num? amount) {
    if (amount == null) return 'Rp 0';
    return _rupiahFormat.format(amount);
  }

  /// Format quantity with unit (e.g. "150 kg", "25 box")
  static String formatQuantity(num? value, [String unit = 'kg']) {
    if (value == null) return '0 $unit';
    return '${_decimalFormat.format(value)} $unit';
  }

  /// Format date string (ISO8601 or YYYY-MM-DD) to Indonesian formatted date
  static String formatDate(dynamic date) {
    if (date == null) return '-';
    DateTime? parsedDate;
    if (date is DateTime) {
      parsedDate = date;
    } else if (date is String) {
      if (date.isEmpty) return '-';
      parsedDate = DateTime.tryParse(date);
    }
    if (parsedDate == null) return date.toString();
    try {
      return _indonesianDateFormat.format(parsedDate);
    } catch (_) {
      return parsedDate.toString().split(' ')[0];
    }
  }

  /// Format date and time (e.g. 15 Jan 2026, 14:30)
  static String formatDateTime(dynamic date) {
    if (date == null) return '-';
    DateTime? parsedDate;
    if (date is DateTime) {
      parsedDate = date;
    } else if (date is String) {
      if (date.isEmpty) return '-';
      parsedDate = DateTime.tryParse(date);
    }
    if (parsedDate == null) return date.toString();
    try {
      return _indonesianDateTimeFormat.format(parsedDate);
    } catch (_) {
      return parsedDate.toString();
    }
  }
}

/// Helpful num extension for quick formatting
extension NumFormattingExtension on num {
  String toRupiah() => AppFormatters.formatRupiah(this);
  String toQuantity([String unit = 'kg']) => AppFormatters.formatQuantity(this, unit);
}

/// Helpful DateTime extension
extension DateTimeFormattingExtension on DateTime {
  String toIndonesianDate() => AppFormatters.formatDate(this);
  String toIndonesianDateTime() => AppFormatters.formatDateTime(this);
}
