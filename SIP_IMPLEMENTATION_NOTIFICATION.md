# سرویس CallNotification - جستجوی مشتری و نمایش Popup

## 1. فایل: lib/core/services/call_notification_service.dart

```dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:invoice/core/constants/env.dart';
import 'package:invoice/features/customer/data/models/customer_call_data.dart';

/// سرویس مدیریت اطلاع‌رسانی تماس‌ها و جستجوی مشتری
class CallNotificationService {
  final Dio _dio;
  
  CallNotificationService(this._dio);

  /// جستجوی مشتری با شماره تلفن
  Future<CustomerCallData?> lookupCustomer(String phoneNumber) async {
    try {
      debugPrint('🔍 جستجوی مشتری با شماره: $phoneNumber');
      
      // حذف کاراکترهای اضافی از شماره
      final cleanNumber = _cleanPhoneNumber(phoneNumber);
      
      final response = await _dio.get(
        '/customers/by-phone/$cleanNumber',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        debugPrint('✅ مشتری پیدا شد: ${response.data['customer']['name']}');
        
        return CustomerCallData(
          customer: Customer.fromJson(response.data['customer']),
          lastDocument: response.data['lastDocument'] != null
              ? Document.fromJson(response.data['lastDocument'])
              : null,
          phoneNumber: cleanNumber,
        );
      }
      
      return null;
      
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        debugPrint('⚠️ مشتری با شماره $phoneNumber یافت نشد');
        return null;
      }
      
      debugPrint('❌ خطا در جستجوی مشتری: ${e.message}');
      return null;
      
    } catch (e) {
      debugPrint('❌ خطای غیرمنتظره در جستجوی مشتری: $e');
      return null;
    }
  }

  /// پاکسازی شماره تلفن (حذف فاصله، خط تیره، و...)
  String _cleanPhoneNumber(String phoneNumber) {
    // حذف تمام کاراکترهای غیر عددی
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    
    // اگر با 0098 شروع شود، به 0 تبدیل کن
    if (cleaned.startsWith('0098')) {
      cleaned = '0${cleaned.substring(4)}';
    }
    // اگر با 98 شروع شود (بدون 00)
    else if (cleaned.startsWith('98') && cleaned.length > 10) {
      cleaned = '0${cleaned.substring(2)}';
    }
    
    return cleaned;
  }

  /// ذخیره تاریخچه تماس (اختیاری - برای آینده)
  Future<void> saveCallHistory({
    required String phoneNumber,
    required String? customerName,
    required String direction,
    required int durationSeconds,
  }) async {
    try {
      // این API را در آینده می‌توانید پیاده کنید
      await _dio.post('/call-history', data: {
        'phoneNumber': phoneNumber,
        'customerName': customerName,
        'direction': direction,
        'duration': durationSeconds,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      debugPrint('✅ تاریخچه تماس ذخیره شد');
    } catch (e) {
      debugPrint('⚠️ خطا در ذخیره تاریخچه: $e');
      // عدم ذخیره تاریخچه نباید مانع کار شود
    }
  }
}
```

---

## 2. فایل: lib/core/services/sip_integration_service.dart

این سرویس **WebSipService** و **CallNotificationService** را با هم ترکیب می‌کند:

```dart
import 'package:flutter/foundation.dart';
import 'package:invoice/core/models/sip_config.dart';
import 'package:invoice/core/services/web_sip_service.dart';
import 'package:invoice/core/services/call_notification_service.dart';
import 'package:invoice/features/customer/data/models/customer_call_data.dart';

/// سرویس یکپارچه SIP + Notification
class SipIntegrationService {
  final WebSipService _sipService;
  final CallNotificationService _notificationService;
  
  // Callback برای نمایش Popup در UI
  Function(CustomerCallData customerData)? onCustomerCallReceived;
  Function(String phoneNumber)? onUnknownCallReceived;
  Function(String message)? onStatusChanged;
  Function(String error)? onError;

  SipIntegrationService({
    required WebSipService sipService,
    required CallNotificationService notificationService,
  })  : _sipService = sipService,
        _notificationService = notificationService {
    _setupCallbacks();
  }

  /// راه‌اندازی سیستم SIP
  void initialize(SipConfig config) {
    if (!kIsWeb) {
      debugPrint('⚠️ SIP Integration فقط روی Web کار می‌کند');
      return;
    }

    debugPrint('🚀 راه‌اندازی سیستم تلفن...');
    _sipService.initialize(config);
  }

  /// تنظیم Callbackها
  void _setupCallbacks() {
    // هنگام دریافت تماس ورودی
    _sipService.onIncomingCall = (callerNumber, callerName) async {
      debugPrint('📞 تماس ورودی از: $callerNumber ($callerName)');
      onStatusChanged?.call('تماس ورودی از $callerNumber');
      
      // جستجوی مشتری
      final customerData = await _notificationService.lookupCustomer(callerNumber);
      
      if (customerData != null) {
        // مشتری پیدا شد - نمایش Popup
        debugPrint('✅ مشتری پیدا شد: ${customerData.customer.name}');
        onCustomerCallReceived?.call(customerData);
      } else {
        // مشتری ناشناس
        debugPrint('⚠️ تماس از شماره ناشناس: $callerNumber');
        onUnknownCallReceived?.call(callerNumber);
      }
    };

    // هنگام برقراری تماس
    _sipService.onCallConnected = () {
      debugPrint('✅ تماس برقرار شد');
      onStatusChanged?.call('در تماس');
    };

    // هنگام قطع تماس
    _sipService.onCallEnded = () {
      debugPrint('📴 تماس قطع شد');
      onStatusChanged?.call('آماده');
      
      // ذخیره تاریخچه (اختیاری)
      final call = _sipService.currentCall;
      if (call != null) {
        _notificationService.saveCallHistory(
          phoneNumber: call.callerNumber,
          customerName: call.callerName,
          direction: call.direction == CallDirection.incoming ? 'incoming' : 'outgoing',
          durationSeconds: call.duration.inSeconds,
        );
      }
    };

    // هنگام تغییر وضعیت Registration
    _sipService.onRegistrationChanged = (isRegistered) {
      if (isRegistered) {
        debugPrint('✅ سیستم تلفن آماده است');
        onStatusChanged?.call('آماده');
      } else {
        debugPrint('❌ سیستم تلفن غیرفعال است');
        onStatusChanged?.call('غیرفعال');
      }
    };

    // هنگام خطا
    _sipService.onError = (error) {
      debugPrint('❌ خطا: $error');
      onError?.call(error);
    };
  }

  /// پاسخ به تماس
  void answerCall() {
    _sipService.answerCall();
  }

  /// برقراری تماس
  void makeCall(String phoneNumber) {
    _sipService.makeCall(phoneNumber);
  }

  /// قطع تماس
  void hangup() {
    _sipService.hangup();
  }

  /// ارسال DTMF
  void sendDTMF(String digit) {
    _sipService.sendDTMF(digit);
  }

  /// توقف سیستم
  void stop() {
    _sipService.stop();
  }

  /// وضعیت فعلی
  String get status => _sipService.getStatus();
  bool get isRegistered => _sipService.isRegistered;
  bool get isInitialized => _sipService.isInitialized;
}
```

---

## 3. فایل: lib/injection_container.dart - ثبت سرویس‌ها

در فایل `injection_container.dart` این سرویس‌ها را ثبت کنید:

```dart
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:invoice/core/services/web_sip_service.dart';
import 'package:invoice/core/services/call_notification_service.dart';
import 'package:invoice/core/services/sip_integration_service.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // ... کدهای موجود
  
  // ==================== SIP Services ====================
  
  // WebSipService (Singleton)
  sl.registerLazySingleton(() => WebSipService());
  
  // CallNotificationService
  sl.registerLazySingleton(() => CallNotificationService(sl<Dio>()));
  
  // SipIntegrationService (Singleton)
  sl.registerLazySingleton(() => SipIntegrationService(
    sipService: sl<WebSipService>(),
    notificationService: sl<CallNotificationService>(),
  ));
  
  // ... ادامه کدهای موجود
}
```

---

## 4. فایل: lib/main.dart - راه‌اندازی SIP در برنامه

در `main.dart` بعد از `runApp`:

```dart
import 'package:flutter/material.dart';
import 'package:invoice/injection_container.dart' as di;
import 'package:invoice/core/services/sip_integration_service.dart';
import 'package:invoice/core/models/sip_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // راه‌اندازی Dependency Injection
  await di.init();
  
  // راه‌اندازی SIP (فقط در Web)
  if (kIsWeb) {
    _initializeSipPhone();
  }
  
  runApp(MyApp());
}

void _initializeSipPhone() {
  final sipService = di.sl<SipIntegrationService>();
  
  // پیکربندی SIP - این مقادیر را از تنظیمات یا دیتابیس بخوانید
  final config = SipConfig(
    sipServer: '192.168.1.100',  // IP سرور ایزابل یا Gateway
    sipPort: '8089',              // پورت WebSocket
    extension: '1008',            // شماره داخلی
    password: 'your-password',    // رمز عبور داخلی
    displayName: 'کارمند فروش',
    autoAnswer: false,            // پاسخ خودکار خاموش
  );
  
  // راه‌اندازی
  sipService.initialize(config);
  
  // تنظیم Callbacks (فعلاً فقط log)
  sipService.onCustomerCallReceived = (customerData) {
    debugPrint('🎯 مشتری: ${customerData.customer.name}');
    debugPrint('📄 آخرین سند: ${customerData.lastDocument?.documentNumber ?? 'ندارد'}');
    // TODO: نمایش Popup (در مرحله بعد)
  };
  
  sipService.onUnknownCallReceived = (phoneNumber) {
    debugPrint('⚠️ تماس ناشناس: $phoneNumber');
    // TODO: نمایش Notification ساده
  };
  
  sipService.onStatusChanged = (status) {
    debugPrint('📊 وضعیت: $status');
  };
  
  sipService.onError = (error) {
    debugPrint('❌ خطا: $error');
  };
}
```

---

**نکته:** این فایل‌ها **فقط منطق** را پیاده‌سازی می‌کنند. هیچ UI ایجاد نشده است. در مرحله بعد (اگر تست موفق بود) UI برای Popup اضافه می‌کنیم.

---

## تست اولیه:

1. Backend را اجرا کنید
2. داده نمونه مشتری با شماره اضافه کنید:
```sql
UPDATE customers SET phone_numbers = JSON_ARRAY('12345678') WHERE id = 'customer-id';
```
3. Flutter را اجرا کنید: `flutter run -d chrome --web-port=8080`
4. در Console مرورگر باید ببینید:
   - ✅ SIP UA ایجاد شد
   - ✅ Registration موفق
   - ✅ داخلی 1008 فعال است

5. با یک Softphone (مثل MicroSIP) به داخلی 1008 زنگ بزنید
6. باید در Console ببینید:
   - 📞 تماس ورودی
   - 🔍 جستجوی مشتری
   - ✅ مشتری پیدا شد (اگر شماره در دیتابیس باشد)
