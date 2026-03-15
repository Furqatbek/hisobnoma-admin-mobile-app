/// Input validation utilities
abstract final class Validators {
  /// Validate phone number (Uzbekistan format)
  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    // Remove spaces and dashes
    final cleaned = value.replaceAll(RegExp(r'[\s\-()]'), '');
    // Match +998XXXXXXXXX or 998XXXXXXXXX
    if (!RegExp(r'^\+?998\d{9}$').hasMatch(cleaned)) {
      return 'Enter a valid Uzbekistan phone number';
    }
    return null;
  }

  /// Validate OTP code (6 digits)
  static String? otpCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Code is required';
    }
    if (!RegExp(r'^\d{6}$').hasMatch(value)) {
      return 'Enter a valid 6-digit code';
    }
    return null;
  }

  /// Validate amount (positive number)
  static String? amount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Amount is required';
    }
    final parsed = double.tryParse(value.replaceAll(',', ''));
    if (parsed == null || parsed <= 0) {
      return 'Enter a valid amount';
    }
    return null;
  }

  /// Validate quantity (positive integer)
  static String? quantity(String? value) {
    if (value == null || value.isEmpty) {
      return 'Quantity is required';
    }
    final parsed = int.tryParse(value);
    if (parsed == null || parsed <= 0) {
      return 'Enter a valid quantity';
    }
    return null;
  }

  /// Validate required field
  static String? required(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }
}
