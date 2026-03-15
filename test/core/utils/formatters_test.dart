import 'package:flutter_test/flutter_test.dart';
import 'package:hisobnoma/core/utils/formatters.dart';

void main() {
  group('Formatters', () {
    group('currency', () {
      test('formats with default symbol', () {
        expect(Formatters.currency(1500000), '1,500,000.00 UZS');
      });

      test('formats with custom symbol', () {
        expect(Formatters.currency(1234.5, symbol: 'USD'), '1,234.50 USD');
      });

      test('formats zero', () {
        expect(Formatters.currency(0), '0.00 UZS');
      });
    });

    group('compactCurrency', () {
      test('formats large numbers compactly', () {
        final result = Formatters.compactCurrency(1500000);
        expect(result, contains('UZS'));
        // Compact format varies by locale, just verify it's shorter
        expect(result.length, lessThan('1,500,000.00 UZS'.length));
      });

      test('formats with custom symbol', () {
        expect(
          Formatters.compactCurrency(500, symbol: 'USD'),
          contains('USD'),
        );
      });
    });

    group('percentage', () {
      test('formats positive with sign', () {
        expect(Formatters.percentage(9.38), '+9.38%');
      });

      test('formats negative without explicit sign', () {
        expect(Formatters.percentage(-5.2), '-5.2%');
      });

      test('formats zero', () {
        expect(Formatters.percentage(0), '0%');
      });

      test('formats without sign when showSign is false', () {
        expect(Formatters.percentage(9.38, showSign: false), '9.38%');
      });
    });

    group('integer', () {
      test('formats with commas', () {
        expect(Formatters.integer(1420), '1,420');
      });

      test('formats small numbers without commas', () {
        expect(Formatters.integer(42), '42');
      });

      test('formats zero', () {
        expect(Formatters.integer(0), '0');
      });
    });

    group('date', () {
      test('formats date correctly', () {
        final date = DateTime(2026, 1, 15);
        expect(Formatters.date(date), 'Jan 15, 2026');
      });
    });

    group('shortDate', () {
      test('formats short date', () {
        final date = DateTime(2026, 3, 5);
        expect(Formatters.shortDate(date), 'Mar 5');
      });
    });

    group('time', () {
      test('formats time in 12-hour format', () {
        final date = DateTime(2026, 1, 15, 14, 30);
        expect(Formatters.time(date), '2:30 PM');
      });

      test('formats morning time', () {
        final date = DateTime(2026, 1, 15, 9, 5);
        expect(Formatters.time(date), '9:05 AM');
      });
    });

    group('relativeDate', () {
      test('returns Today for today', () {
        expect(Formatters.relativeDate(DateTime.now()), 'Today');
      });

      test('returns Yesterday for yesterday', () {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        expect(Formatters.relativeDate(yesterday), 'Yesterday');
      });

      test('returns short date for same year', () {
        final now = DateTime.now();
        // Use a date at least 2 days in the past, same year
        final past = DateTime(now.year, now.month > 1 ? 1 : now.month, 5);
        if (past.isBefore(now.subtract(const Duration(days: 1)))) {
          final result = Formatters.relativeDate(past);
          expect(result, isNot('Today'));
          expect(result, isNot('Yesterday'));
        }
      });

      test('returns full date for different year', () {
        final oldDate = DateTime(2024, 6, 15);
        expect(Formatters.relativeDate(oldDate), 'Jun 15, 2024');
      });
    });

    group('parseIso', () {
      test('parses valid ISO string', () {
        final result = Formatters.parseIso('2026-01-15T10:30:00.000Z');
        expect(result, isNotNull);
        expect(result!.year, 2026);
        expect(result.month, 1);
        expect(result.day, 15);
      });

      test('returns null for null input', () {
        expect(Formatters.parseIso(null), isNull);
      });

      test('returns null for invalid string', () {
        expect(Formatters.parseIso('not-a-date'), isNull);
      });
    });

    group('toIso', () {
      test('converts to UTC ISO string', () {
        final date = DateTime.utc(2026, 1, 15, 10, 30);
        final result = Formatters.toIso(date);
        expect(result, contains('2026-01-15'));
        expect(result, contains('10:30'));
      });
    });
  });
}
