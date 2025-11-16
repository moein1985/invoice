import 'package:flutter_test/flutter_test.dart';
import 'package:invoice/core/utils/number_formatter.dart';

void main() {
  group('NumberFormatter', () {
    test('formatWithComma formats large numbers', () {
      final formatted = NumberFormatter.formatWithComma(1234567);
      expect(formatted, '1,234,567');
    });

    test('toPersianNumber converts digits', () {
      final persian = NumberFormatter.toPersianNumber('123');
      expect(persian, isNot('123'));
      expect(persian, contains('۱'));
    });

    test('formatCurrency combines formatting and persian digits', () {
      final currency = NumberFormatter.formatCurrency(1234567);
      expect(currency, contains('ریال'));
      // ensure digits are Persian in the result
      expect(currency.contains(RegExp(r'[0-9]')), isFalse);
    });

    test('parseFormattedNumber parses Persian formatted currency', () {
      final text = NumberFormatter.formatCurrency(1234567);
      final parsed = NumberFormatter.parseFormattedNumber(text);
      expect(parsed, isNotNull);
      expect(parsed, equals(1234567));
    });

    test('parseFormattedNumber returns null for invalid input', () {
      expect(NumberFormatter.parseFormattedNumber('not a number'), isNull);
    });
  });
}
