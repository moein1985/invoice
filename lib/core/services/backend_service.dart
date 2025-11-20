import 'dart:io';
import 'package:flutter/foundation.dart';

/// سرویس مدیریت Backend
/// مسئول راه‌اندازی خودکار Backend و MySQL
class BackendService {
  static Process? _backendProcess;
  static bool _isRunning = false;

  /// راه‌اندازی کامل Backend (Docker + MySQL + Node.js)
  static Future<bool> startBackend() async {
    // در Web، Backend باید از قبل اجرا شده باشد
    if (kIsWeb) {
      debugPrint('🌐 Running on Web - Backend should be started manually');
      debugPrint('ℹ️  Make sure Docker and Backend are running on host machine');
      _isRunning = true;
      return true;
    }

    if (_isRunning) {
      debugPrint('✅ Backend already running');
      return true;
    }

    try {
      debugPrint('🚀 Starting backend services...');

      // مرحله 1: چک کردن Docker
      if (!await _isDockerRunning()) {
        debugPrint('❌ Docker Desktop is not running!');
        debugPrint('⚠️  Please start Docker Desktop and try again');
        return false;
      }

      // مرحله 2: Start کردن MySQL Container
      if (!await _startMySQLContainer()) {
        debugPrint('❌ Failed to start MySQL container');
        return false;
      }

      // مرحله 3: Start کردن Backend Node.js
      if (!await _startNodeBackend()) {
        debugPrint('❌ Failed to start Node.js backend');
        return false;
      }

      // مرحله 4: منتظر ماندن برای آماده شدن Backend
      if (!await _waitForBackend()) {
        debugPrint('❌ Backend health check failed');
        return false;
      }

      _isRunning = true;
      debugPrint('✅ Backend services started successfully!');
      return true;
    } catch (e) {
      debugPrint('❌ Error starting backend: $e');
      return false;
    }
  }

  /// توقف Backend
  static Future<void> stopBackend() async {
    if (_backendProcess != null) {
      debugPrint('🛑 Stopping backend...');
      _backendProcess!.kill();
      _backendProcess = null;
      _isRunning = false;
      debugPrint('✅ Backend stopped');
    }
  }

  /// چک کردن Docker در حال اجرا است
  static Future<bool> _isDockerRunning() async {
    try {
      final result = await Process.run('docker', ['ps']);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  /// Start کردن MySQL Container
  static Future<bool> _startMySQLContainer() async {
    try {
      debugPrint('🐳 Checking MySQL container...');

      // چک کردن Container موجود است
      final checkResult = await Process.run(
        'docker',
        ['ps', '-a', '--filter', 'name=invoice_mysql', '--format', '{{.Status}}'],
      );

      if (checkResult.stdout.toString().contains('Up')) {
        debugPrint('✅ MySQL container already running');
        return true;
      }

      // Start کردن Container
      debugPrint('🔄 Starting MySQL container...');
      final startResult = await Process.run('docker', ['start', 'invoice_mysql']);

      if (startResult.exitCode == 0) {
        // منتظر ماندن برای آماده شدن MySQL
        await Future.delayed(const Duration(seconds: 3));
        debugPrint('✅ MySQL container started');
        return true;
      } else {
        debugPrint('❌ Failed to start MySQL: ${startResult.stderr}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error with MySQL container: $e');
      return false;
    }
  }

  /// Start کردن Backend Node.js
  static Future<bool> _startNodeBackend() async {
    try {
      debugPrint('📦 Starting Node.js backend...');

      // مسیر به backend directory
      final backendPath = Platform.isWindows
          ? r'backend'
          : 'backend';

      // اجرای node server
      _backendProcess = await Process.start(
        'node',
        ['src/server.js'],
        workingDirectory: backendPath,
        mode: ProcessStartMode.detached,
      );

      // لاگ کردن خروجی
      _backendProcess!.stdout.listen((data) {
        debugPrint('Backend: ${String.fromCharCodes(data)}');
      });

      _backendProcess!.stderr.listen((data) {
        debugPrint('Backend Error: ${String.fromCharCodes(data)}');
      });

      debugPrint('✅ Node.js backend process started');
      return true;
    } catch (e) {
      debugPrint('❌ Error starting Node.js: $e');
      return false;
    }
  }

  /// منتظر ماندن برای آماده شدن Backend
  static Future<bool> _waitForBackend() async {
    debugPrint('⏳ Waiting for backend to be ready...');

    for (var i = 0; i < 30; i++) {
      // تلاش برای 30 ثانیه
      try {
        final client = HttpClient();
        final request = await client.getUrl(Uri.parse('http://localhost:3000/health'));
        final response = await request.close();

        if (response.statusCode == 200) {
          debugPrint('✅ Backend health check passed');
          client.close();
          return true;
        }

        client.close();
      } catch (e) {
        // هنوز آماده نیست
      }

      await Future.delayed(const Duration(seconds: 1));
      debugPrint('⏳ Waiting... (${i + 1}/30)');
    }

    debugPrint('❌ Backend health check timeout');
    return false;
  }

  /// چک کردن وضعیت Backend
  static bool get isRunning => _isRunning;
}
