import 'package:flutter/foundation.dart';

/// سیستم لاگینگ ساده و حرفه‌ای برای برنامه
/// استفاده: AppLogger.debug('پیام'), AppLogger.info('پیام'), و غیره
class AppLogger {
  // تنظیم سطح لاگ فعلی
  static LogLevel currentLevel = kDebugMode ? LogLevel.debug : LogLevel.warning;

  /// لاگ سطح Debug - برای توسعه
  static void debug(String message, [String? tag]) {
    _log(LogLevel.debug, message, tag);
  }

  /// لاگ سطح Info - اطلاعات عمومی
  static void info(String message, [String? tag]) {
    _log(LogLevel.info, message, tag);
  }

  /// لاگ سطح Warning - هشدارها
  static void warning(String message, [String? tag]) {
    _log(LogLevel.warning, message, tag);
  }

  /// لاگ سطح Error - خطاها
  static void error(String message, [String? tag, Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.error, message, tag, error: error, stackTrace: stackTrace);
  }

  static void _log(
    LogLevel level,
    String message,
    String? tag, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    // اگر سطح لاگ کمتر از سطح فعلی باشد، نمایش نده
    if (level.index < currentLevel.index) return;

    final timestamp = DateTime.now().toString().substring(11, 19);
    final emoji = _getEmoji(level);
    final levelStr = level.name.toUpperCase().padRight(7);
    final tagStr = tag != null ? '[$tag] ' : '';

    final logLine = '$emoji $timestamp $levelStr $tagStr$message';
    debugPrint(logLine);

    if (error != null) {
      debugPrint('  ❌ Error: $error');
    }

    if (stackTrace != null && level == LogLevel.error) {
      final stackSnippet = stackTrace.toString().split('\n').take(5).join('\n  ');
      debugPrint('  📍 Stack: $stackSnippet');
    }
  }

  static String _getEmoji(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '🔍';
      case LogLevel.info:
        return 'ℹ️';
      case LogLevel.warning:
        return '⚠️';
      case LogLevel.error:
        return '🔴';
    }
  }
}

enum LogLevel {
  debug,
  info,
  warning,
  error,
}

/// Extension برای لاگ‌گیری راحت‌تر در کلاس‌ها
extension LoggerExtension on Object {
  String get logTag => runtimeType.toString();

  void logDebug(String message) => AppLogger.debug(message, logTag);
  void logInfo(String message) => AppLogger.info(message, logTag);
  void logWarning(String message) => AppLogger.warning(message, logTag);
  void logError(String message, [Object? error, StackTrace? stackTrace]) =>
      AppLogger.error(message, logTag, error, stackTrace);
}

