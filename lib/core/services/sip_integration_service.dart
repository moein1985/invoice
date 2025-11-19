import 'package:flutter/foundation.dart';
import 'package:invoice/core/models/sip_config.dart';
import 'package:invoice/core/models/call_info.dart';
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
