import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:flutter/foundation.dart';
import 'package:invoice/core/models/sip_config.dart';
import 'package:invoice/core/models/call_info.dart';

/// سرویس مدیریت SIP Phone با JsSIP (فقط برای Web)
class WebSipService {
  static final WebSipService _instance = WebSipService._internal();
  factory WebSipService() => _instance;
  WebSipService._internal();

  // Callbacks
  Function(String callerNumber, String callerName)? onIncomingCall;
  Function()? onCallConnected;
  Function()? onCallEnded;
  Function(bool isRegistered)? onRegistrationChanged;
  Function(String error)? onError;

  bool _isInitialized = false;
  bool _isRegistered = false;
  CallInfo? _currentCall;

  bool get isInitialized => _isInitialized;
  bool get isRegistered => _isRegistered;
  CallInfo? get currentCall => _currentCall;

  /// راه‌اندازی SIP Client
  void initialize(SipConfig config) {
    if (!kIsWeb) {
      debugPrint('⚠️ WebSipService فقط روی Flutter Web کار می‌کند');
      return;
    }

    try {
      // ایجاد User Agent با JsSIP
      final jsCode = """
        (function() {
          // تنظیم سطح log (برای دیباگ)
          JsSIP.debug.enable('JsSIP:*');
          
          // ایجاد WebSocket Interface
          // استفاده از ws:// با path /ws برای Asterisk WebSocket
          const socket = new JsSIP.WebSocketInterface('ws://${config.sipServer}:${config.sipPort}/ws');
          
          // پیکربندی
          const configuration = {
            sockets: [socket],
            uri: 'sip:${config.extension}@${config.sipServer}',
            password: '${config.password}',
            display_name: '${config.displayName ?? config.extension}',
            session_timers: false,
            use_preloaded_route: false,
            user_agent: 'Invoice System v1.0',
            register: true,
            register_expires: 600,
          };
          
          // ایجاد UA
          window.sipUA = new JsSIP.UA(configuration);
          window.currentSession = null;
          
          console.log('🚀 SIP UA ایجاد شد');
          
          // --- رویدادهای UA ---
          
          window.sipUA.on('connecting', function(e) {
            console.log('🔄 در حال اتصال به سرور SIP...');
          });
          
          window.sipUA.on('connected', function(e) {
            console.log('✅ به سرور SIP متصل شد');
          });
          
          window.sipUA.on('disconnected', function(e) {
            console.log('❌ از سرور SIP قطع شد');
            if (window.dartOnRegistrationChanged) {
              window.dartOnRegistrationChanged(false);
            }
          });
          
          window.sipUA.on('registered', function(e) {
            console.log('✅ Registration موفق - داخلی ${config.extension} فعال است');
            if (window.dartOnRegistrationChanged) {
              window.dartOnRegistrationChanged(true);
            }
          });
          
          window.sipUA.on('unregistered', function(e) {
            console.log('⚠️ Unregistered از سرور');
            if (window.dartOnRegistrationChanged) {
              window.dartOnRegistrationChanged(false);
            }
          });
          
          window.sipUA.on('registrationFailed', function(e) {
            console.error('❌ Registration ناموفق:', e.cause);
            if (window.dartOnError) {
              window.dartOnError('خطا در ثبت: ' + e.cause);
            }
            if (window.dartOnRegistrationChanged) {
              window.dartOnRegistrationChanged(false);
            }
          });
          
          // --- رویداد تماس جدید ---
          window.sipUA.on('newRTCSession', function(e) {
            const session = e.session;
            const callId = session.id;
            
            if (session.direction === 'incoming') {
              // 📞 تماس ورودی
              const callerNumber = session.remote_identity.uri.user;
              const callerName = session.remote_identity.display_name || callerNumber;
              
              console.log('📞 تماس ورودی:', callerNumber, '-', callerName);
              
              // ذخیره session
              window.currentSession = session;
              
              // اطلاع به Dart
              if (window.dartOnIncomingCall) {
                window.dartOnIncomingCall(callerNumber, callerName, callId);
              }
              
              // رویدادهای session
              session.on('accepted', function() {
                console.log('✅ تماس پذیرفته شد');
              });
              
              session.on('confirmed', function() {
                console.log('✅ تماس برقرار شد (confirmed)');
                if (window.dartOnCallConnected) {
                  window.dartOnCallConnected();
                }
              });
              
              session.on('ended', function() {
                console.log('📴 تماس قطع شد');
                window.currentSession = null;
                if (window.dartOnCallEnded) {
                  window.dartOnCallEnded();
                }
              });
              
              session.on('failed', function(e) {
                console.log('❌ تماس ناموفق:', e.cause);
                window.currentSession = null;
                if (window.dartOnError) {
                  window.dartOnError('تماس ناموفق: ' + e.cause);
                }
                if (window.dartOnCallEnded) {
                  window.dartOnCallEnded();
                }
              });
              
            } else {
              // 📞 تماس خروجی
              window.currentSession = session;
              
              session.on('progress', function() {
                console.log('🔄 در حال برقراری...');
              });
              
              session.on('accepted', function() {
                console.log('✅ طرف مقابل پاسخ داد');
              });
              
              session.on('confirmed', function() {
                console.log('✅ تماس خروجی برقرار شد');
                if (window.dartOnCallConnected) {
                  window.dartOnCallConnected();
                }
              });
              
              session.on('ended', function() {
                console.log('📴 تماس خروجی قطع شد');
                window.currentSession = null;
                if (window.dartOnCallEnded) {
                  window.dartOnCallEnded();
                }
              });
              
              session.on('failed', function(e) {
                console.log('❌ تماس خروجی ناموفق:', e.cause);
                window.currentSession = null;
                if (window.dartOnError) {
                  window.dartOnError('تماس ناموفق: ' + e.cause);
                }
                if (window.dartOnCallEnded) {
                  window.dartOnCallEnded();
                }
              });
            }
          });
          
          // شروع UA
          window.sipUA.start();
          console.log('▶️ SIP UA Started');
          
        })();
      """;
      
      globalContext.callMethod('eval'.toJS, jsCode.toJS);

      // ثبت Dart Callbacks
      globalContext.setProperty('dartOnIncomingCall'.toJS, (JSString callerNumber, JSString callerName, JSString callId) {
        _currentCall = CallInfo(
          callId: callId.toDart,
          callerNumber: callerNumber.toDart,
          callerName: callerName.toDart,
          startTime: DateTime.now(),
          direction: CallDirection.incoming,
          status: CallStatus.ringing,
        );
        
        if (onIncomingCall != null) {
          onIncomingCall!(callerNumber.toDart, callerName.toDart);
        }
      }.toJS);

      globalContext.setProperty('dartOnCallConnected'.toJS, () {
        if (_currentCall != null) {
          _currentCall = _currentCall!.copyWith(status: CallStatus.connected);
        }
        onCallConnected?.call();
      }.toJS);

      globalContext.setProperty('dartOnCallEnded'.toJS, () {
        if (_currentCall != null) {
          _currentCall = _currentCall!.copyWith(status: CallStatus.ended);
        }
        onCallEnded?.call();
        _currentCall = null;
      }.toJS);

      globalContext.setProperty('dartOnRegistrationChanged'.toJS, (JSBoolean isRegistered) {
        _isRegistered = isRegistered.toDart;
        onRegistrationChanged?.call(isRegistered.toDart);
      }.toJS);

      globalContext.setProperty('dartOnError'.toJS, (JSString error) {
        onError?.call(error.toDart);
      }.toJS);

      _isInitialized = true;
      debugPrint('✅ WebSipService راه‌اندازی شد');
      
    } catch (error) {
      debugPrint('❌ خطا در راه‌اندازی SIP: $error');
      _isInitialized = false;
      onError?.call('خطا در راه‌اندازی: $error');
    }
  }

  /// پاسخ دادن به تماس ورودی
  void answerCall() {
    if (!_isInitialized || _currentCall == null) {
      debugPrint('⚠️ تماسی برای پاسخ دادن وجود ندارد');
      return;
    }

    try {
      final answerCode = """
        if (window.currentSession && window.currentSession.direction === 'incoming') {
          window.currentSession.answer({
            mediaConstraints: { 
              audio: true, 
              video: false 
            },
            pcConfig: {
              iceServers: [
                { urls: ['stun:stun.l.google.com:19302'] },
                { urls: ['stun:stun1.l.google.com:19302'] }
              ]
            }
          });
          console.log('✅ در حال پاسخ به تماس...');
        } else {
          console.error('❌ Session موجود نیست');
        }
      """;
      
      globalContext.callMethod('eval'.toJS, answerCode.toJS);
      
      if (_currentCall != null) {
        _currentCall = _currentCall!.copyWith(status: CallStatus.connecting);
      }
      
    } catch (error) {
      debugPrint('❌ خطا در پاسخ به تماس: $error');
      onError?.call('خطا در پاسخ به تماس');
    }
  }

  /// برقراری تماس خروجی
  void makeCall(String phoneNumber) {
    if (!_isInitialized || !_isRegistered) {
      debugPrint('⚠️ SIP ثبت نشده است');
      onError?.call('سیستم تلفنی آماده نیست');
      return;
    }

    try {
      final callCode = """
        const target = 'sip:$phoneNumber@' + window.sipUA.configuration.uri.host;
        
        const options = {
          mediaConstraints: { 
            audio: true, 
            video: false 
          },
          pcConfig: {
            iceServers: [
              { urls: ['stun:stun.l.google.com:19302'] }
            ]
          }
        };
        
        window.sipUA.call(target, options);
        console.log('📞 در حال برقراری تماس با:', target);
      """;
      
      globalContext.callMethod('eval'.toJS, callCode.toJS);
      
      _currentCall = CallInfo(
        callId: DateTime.now().millisecondsSinceEpoch.toString(),
        callerNumber: phoneNumber,
        startTime: DateTime.now(),
        direction: CallDirection.outgoing,
        status: CallStatus.connecting,
      );
      
    } catch (error) {
      debugPrint('❌ خطا در برقراری تماس: $error');
      onError?.call('خطا در برقراری تماس');
    }
  }

  /// قطع تماس
  void hangup() {
    if (!_isInitialized) return;

    try {
      final hangupCode = """
        if (window.currentSession) {
          window.currentSession.terminate();
          console.log('📴 تماس قطع شد');
          window.currentSession = null;
        }
      """;
      
      globalContext.callMethod('eval'.toJS, hangupCode.toJS);
      
      if (_currentCall != null) {
        _currentCall = _currentCall!.copyWith(status: CallStatus.ended);
      }
      
    } catch (error) {
      debugPrint('❌ خطا در قطع تماس: $error');
    }
  }

  /// ارسال DTMF (اعداد تلفن در حین تماس)
  void sendDTMF(String digit) {
    if (!_isInitialized || _currentCall == null) return;

    try {
      final dtmfCode = """
        if (window.currentSession) {
          window.currentSession.sendDTMF('$digit');
          console.log('📱 DTMF ارسال شد: $digit');
        }
      """;
      
      globalContext.callMethod('eval'.toJS, dtmfCode.toJS);
    } catch (error) {
      debugPrint('❌ خطا در ارسال DTMF: $error');
    }
  }

  /// توقف و Unregister
  void stop() {
    if (!_isInitialized) return;

    try {
      final stopCode = """
        if (window.sipUA) {
          window.sipUA.stop();
          console.log('⏹️ SIP UA متوقف شد');
          window.currentSession = null;
        }
      """;
      
      globalContext.callMethod('eval'.toJS, stopCode.toJS);
      
      _isInitialized = false;
      _isRegistered = false;
      _currentCall = null;
      
    } catch (error) {
      debugPrint('❌ خطا در توقف SIP: $error');
    }
  }

  /// دریافت وضعیت فعلی
  String getStatus() {
    if (!_isInitialized) return 'غیرفعال';
    if (!_isRegistered) return 'در حال اتصال...';
    if (_currentCall != null) {
      switch (_currentCall!.status) {
        case CallStatus.ringing:
          return 'در حال زنگ خوردن...';
        case CallStatus.connecting:
          return 'در حال اتصال...';
        case CallStatus.connected:
          return 'در تماس';
        case CallStatus.ended:
        case CallStatus.failed:
          return 'آماده';
      }
    }
    return 'آماده';
  }
}