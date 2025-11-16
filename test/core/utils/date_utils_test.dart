import 'package:flutter_test/flutter_test.dart';
import 'package:invoice/core/utils/date_utils.dart';

void main() {
  group('PersianDateUtils', () {
    test('toJalali and fromJalali round-trip', () {
      final now = DateTime(2023, 11, 7); // corresponds to a jalali date
      final jalaliStr = PersianDateUtils.toJalali(now);
      expect(jalaliStr.contains('/'), isTrue);

      // parse parts and convert back
      final parts = jalaliStr.split('/').map(int.parse).toList();
      final dt = PersianDateUtils.fromJalali(parts[0], parts[1], parts[2]);
      expect(dt.year, equals(now.year));
    });

    test('formatPersian returns non-empty string', () {
      final s = PersianDateUtils.formatPersian(DateTime(2023, 11, 7));
      expect(s, isNotEmpty);
      expect(s.contains(' '), isTrue);
    });

    test('startOfMonth and endOfMonth produce sensible range', () {
      final start = PersianDateUtils.startOfMonth();
      final end = PersianDateUtils.endOfMonth();
      expect(start.isBefore(end) || start.isAtSameMomentAs(end), isTrue);
    });

    test('startOfYear and endOfYear produce sensible range', () {
      final start = PersianDateUtils.startOfYear();
      final end = PersianDateUtils.endOfYear();
      expect(start.isBefore(end) || start.isAtSameMomentAs(end), isTrue);
    });
  });
}
