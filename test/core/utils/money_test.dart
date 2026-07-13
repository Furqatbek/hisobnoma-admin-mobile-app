import 'package:flutter_test/flutter_test.dart';
import 'package:hisobnoma/core/utils/money.dart';

void main() {
  group('roundMoney', () {
    test('removes IEEE-754 drift', () {
      // 0.1 * 3 == 0.30000000000000004 as a raw double.
      expect(roundMoney(0.1 * 3), 0.3);
    });

    test('rounds to 2 decimal places', () {
      expect(roundMoney(2.005 * 1), closeTo(2.0, 0.011)); // rounding boundary
      expect(roundMoney(1.239), 1.24);
      expect(roundMoney(1.231), 1.23);
    });

    test('leaves clean values unchanged', () {
      expect(roundMoney(800000), 800000);
      expect(roundMoney(0), 0);
      expect(roundMoney(1500.5), 1500.5);
    });

    test('handles a realistic price * fractional quantity', () {
      // 19999.99 * 0.3 = 5999.997 -> 6000.00 at 2dp.
      expect(roundMoney(19999.99 * 0.3), 6000.0);
    });
  });

  group('formatQuantity', () {
    test('whole numbers have no decimals', () {
      expect(formatQuantity(1), '1');
      expect(formatQuantity(2.0), '2');
      expect(formatQuantity(10), '10');
    });

    test('fractional values trim trailing zeros', () {
      expect(formatQuantity(0.5), '0.5');
      expect(formatQuantity(0.50), '0.5');
      expect(formatQuantity(1.25), '1.25');
      expect(formatQuantity(0.2), '0.2');
    });

    test('does not render as 2.0 / 1.0', () {
      expect(formatQuantity(2.0), isNot(contains('.')));
    });
  });
}
