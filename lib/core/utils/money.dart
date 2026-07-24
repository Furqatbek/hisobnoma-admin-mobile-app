// Pure money/quantity helpers used on the sale path. Kept free of Flutter
// imports so they are unit-testable in isolation.

/// Rounds a monetary amount to 2 decimal places, avoiding IEEE-754 drift
/// (e.g. 0.1 * 3 = 0.30000000000000004) before it is sent to the backend.
double roundMoney(double v) => (v * 100).roundToDouble() / 100;

/// Parses a user-entered amount into a rounded double. Tolerates spaces,
/// commas as decimal or thousands separators, and stray non-numeric input
/// (returns 0 for empty/garbage). Used by finance entry forms.
double parseMoney(String input) {
  var s = input.trim().replaceAll(' ', '');
  if (s.isEmpty) return 0;
  // If both separators appear, assume the last one is the decimal point.
  if (s.contains(',') && s.contains('.')) {
    if (s.lastIndexOf(',') > s.lastIndexOf('.')) {
      s = s.replaceAll('.', '').replaceAll(',', '.');
    } else {
      s = s.replaceAll(',', '');
    }
  } else if (s.contains(',')) {
    s = s.replaceAll(',', '.');
  }
  final value = double.tryParse(s) ?? 0;
  return roundMoney(value);
}

/// Formats a [DateTime] as `yyyy-MM-dd` (the finance API's date format).
String formatDateYmd(DateTime d) {
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '${d.year}-$m-$day';
}

/// Formats a quantity for display: whole numbers without decimals, fractional
/// values trimmed of trailing zeros (e.g. 2, 0.5, 1.25).
String formatQuantity(double q) {
  if (q == q.roundToDouble()) return q.toInt().toString();
  var s = q.toStringAsFixed(3);
  s = s.replaceFirst(RegExp(r'0+$'), '');
  if (s.endsWith('.')) s = s.substring(0, s.length - 1);
  return s;
}
