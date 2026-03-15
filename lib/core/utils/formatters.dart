import 'package:intl/intl.dart';

/// Number and date formatting utilities
abstract final class Formatters {
  /// Format currency value (e.g., "1,500,000.00")
  static String currency(double amount, {String symbol = 'UZS'}) {
    final formatter = NumberFormat('#,##0.00');
    return '${formatter.format(amount)} $symbol';
  }

  /// Format compact currency (e.g., "1.5M")
  static String compactCurrency(double amount, {String symbol = 'UZS'}) {
    final formatter = NumberFormat.compact();
    return '${formatter.format(amount)} $symbol';
  }

  /// Format percentage (e.g., "+9.38%")
  static String percentage(double value, {bool showSign = true}) {
    final formatter = NumberFormat('0.##');
    final prefix = showSign && value > 0 ? '+' : '';
    return '$prefix${formatter.format(value)}%';
  }

  /// Format integer with commas (e.g., "1,420")
  static String integer(int value) {
    final formatter = NumberFormat('#,##0');
    return formatter.format(value);
  }

  /// Format date (e.g., "Jan 15, 2026")
  static String date(DateTime dateTime) {
    return DateFormat('MMM d, y').format(dateTime);
  }

  /// Format short date (e.g., "Jan 15")
  static String shortDate(DateTime dateTime) {
    return DateFormat('MMM d').format(dateTime);
  }

  /// Format time (e.g., "10:30 AM")
  static String time(DateTime dateTime) {
    return DateFormat('h:mm a').format(dateTime);
  }

  /// Format relative date (e.g., "Today", "Yesterday", "Jan 15")
  static String relativeDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (dateOnly == today) return 'Today';
    if (dateOnly == today.subtract(const Duration(days: 1))) return 'Yesterday';
    if (dateOnly.year == today.year) return DateFormat('MMM d').format(dateTime);
    return DateFormat('MMM d, y').format(dateTime);
  }

  /// Format ISO datetime string to DateTime
  static DateTime? parseIso(String? isoString) {
    if (isoString == null) return null;
    return DateTime.tryParse(isoString);
  }

  /// Format DateTime to ISO string
  static String toIso(DateTime dateTime) {
    return dateTime.toUtc().toIso8601String();
  }
}
