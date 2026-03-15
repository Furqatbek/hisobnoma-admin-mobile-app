import 'package:flutter/services.dart';

/// Formats phone input as +998 XX XXX XX XX
class UzbekPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Strip all non-digits
    final digits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    // Limit to 9 digits (after country code)
    final limited = digits.length > 9 ? digits.substring(0, 9) : digits;

    // Format as: XX XXX XX XX
    final buffer = StringBuffer();
    for (var i = 0; i < limited.length; i++) {
      if (i == 2 || i == 5 || i == 7) {
        buffer.write(' ');
      }
      buffer.write(limited[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Extracts clean phone number from formatted input
String cleanPhoneNumber(String formatted) {
  final digits = formatted.replaceAll(RegExp(r'[^\d]'), '');
  if (digits.startsWith('998')) return '+$digits';
  return '+998$digits';
}
