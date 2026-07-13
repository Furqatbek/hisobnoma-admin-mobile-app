// Pure money/quantity helpers used on the sale path. Kept free of Flutter
// imports so they are unit-testable in isolation.

/// Rounds a monetary amount to 2 decimal places, avoiding IEEE-754 drift
/// (e.g. 0.1 * 3 = 0.30000000000000004) before it is sent to the backend.
double roundMoney(double v) => (v * 100).roundToDouble() / 100;

/// Formats a quantity for display: whole numbers without decimals, fractional
/// values trimmed of trailing zeros (e.g. 2, 0.5, 1.25).
String formatQuantity(double q) {
  if (q == q.roundToDouble()) return q.toInt().toString();
  var s = q.toStringAsFixed(3);
  s = s.replaceFirst(RegExp(r'0+$'), '');
  if (s.endsWith('.')) s = s.substring(0, s.length - 1);
  return s;
}
