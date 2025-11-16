import 'package:flutter_test/flutter_test.dart';
import 'package:invoice/core/utils/validators.dart';

void main() {
  group('Validators', () {
    test('required returns error for null or empty', () {
      expect(Validators.required(null), isNotNull);
      expect(Validators.required(''), isNotNull);
      expect(Validators.required('  '), isNotNull);
      expect(Validators.required('ok'), isNull);
    });

    test('validateRequired includes field name', () {
      final err = Validators.validateRequired('', 'نام');
      expect(err, contains('نام'));
    });

    test('validatePhone accepts common valid formats', () {
      expect(Validators.validatePhone('09123456789'), isNull);
      expect(Validators.validatePhone('9123456789'), isNull);
      expect(Validators.validatePhone('0912-345-6789'), isNull);
      expect(Validators.validatePhone('0912 345 6789'), isNull);
    });

    test('validatePhone rejects invalid numbers', () {
      expect(Validators.validatePhone('123'), isNotNull);
      expect(Validators.validatePhone('09abc'), isNotNull);
      expect(Validators.validatePhone(''), isNotNull);
    });

    test('validateNumber and positive number checks', () {
      expect(Validators.validateNumber('12.5', 'مبلغ'), isNull);
      expect(Validators.validateNumber('abc', 'مبلغ'), isNotNull);
      expect(Validators.validatePositiveNumber('0', 'قیمت'), isNotNull);
      expect(Validators.validatePositiveNumber('-1', 'قیمت'), isNotNull);
      expect(Validators.validatePositiveNumber('10', 'قیمت'), isNull);
    });

    test('validateEmail optional and format', () {
      expect(Validators.validateEmail(''), isNull);
      expect(Validators.validateEmail(null), isNull);
      expect(Validators.validateEmail('user@example.com'), isNull);
      expect(Validators.validateEmail('bad@com'), isNotNull);
    });

    test('validatePassword and validateUsername length checks', () {
      expect(Validators.validatePassword(''), isNotNull);
      expect(Validators.validatePassword('1234'), isNotNull);
      expect(Validators.validatePassword('12345'), isNull);

      expect(Validators.validateUsername(''), isNotNull);
      expect(Validators.validateUsername('ab'), isNotNull);
      expect(Validators.validateUsername('abc'), isNull);
    });
  });
}
