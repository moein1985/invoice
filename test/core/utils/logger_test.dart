import 'package:flutter_test/flutter_test.dart';
import 'package:invoice/core/utils/logger.dart';

class Dummy {}

void main() {
  group('AppLogger and LoggerExtension', () {
    test('logTag extension returns runtime type', () {
      final d = Dummy();
      expect(d.logTag, equals('Dummy'));
    });

    test('logging methods do not throw', () {
      // change level to debug to allow all logs
      AppLogger.currentLevel = LogLevel.debug;
      expect(() => AppLogger.debug('test debug'), returnsNormally);
      expect(() => AppLogger.info('test info'), returnsNormally);
      expect(() => AppLogger.warning('test warn'), returnsNormally);
      expect(() => AppLogger.error('test error'), returnsNormally);

      // extension methods
      final d = Dummy();
      expect(() => d.logDebug('x'), returnsNormally);
      expect(() => d.logInfo('x'), returnsNormally);
    });
  });
}
