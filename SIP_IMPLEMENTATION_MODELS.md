# مدل‌های داده برای SIP Phone Integration

## 1. فایل: lib/core/models/sip_config.dart

```dart
/// پیکربندی اتصال SIP
class SipConfig {
  final String sipServer;      // مثال: '192.168.1.100'
  final String sipPort;        // مثال: '8089'
  final String extension;      // مثال: '1008'
  final String password;       // رمز عبور داخلی
  final String? displayName;   // نام نمایشی (اختیاری)
  final bool autoAnswer;       // پاسخ خودکار (پیش‌فرض false)

  const SipConfig({
    required this.sipServer,
    required this.sipPort,
    required this.extension,
    required this.password,
    this.displayName,
    this.autoAnswer = false,
  });

  // برای ذخیره در SharedPreferences
  Map<String, dynamic> toJson() => {
    'sipServer': sipServer,
    'sipPort': sipPort,
    'extension': extension,
    'password': password,
    'displayName': displayName,
    'autoAnswer': autoAnswer,
  };

  factory SipConfig.fromJson(Map<String, dynamic> json) => SipConfig(
    sipServer: json['sipServer'] as String,
    sipPort: json['sipPort'] as String,
    extension: json['extension'] as String,
    password: json['password'] as String,
    displayName: json['displayName'] as String?,
    autoAnswer: json['autoAnswer'] as bool? ?? false,
  );

  SipConfig copyWith({
    String? sipServer,
    String? sipPort,
    String? extension,
    String? password,
    String? displayName,
    bool? autoAnswer,
  }) {
    return SipConfig(
      sipServer: sipServer ?? this.sipServer,
      sipPort: sipPort ?? this.sipPort,
      extension: extension ?? this.extension,
      password: password ?? this.password,
      displayName: displayName ?? this.displayName,
      autoAnswer: autoAnswer ?? this.autoAnswer,
    );
  }
}
```

---

## 2. فایل: lib/core/models/call_info.dart

```dart
/// اطلاعات تماس فعال
class CallInfo {
  final String callId;
  final String callerNumber;
  final String? callerName;
  final DateTime startTime;
  final CallDirection direction;
  final CallStatus status;

  const CallInfo({
    required this.callId,
    required this.callerNumber,
    this.callerName,
    required this.startTime,
    required this.direction,
    required this.status,
  });

  CallInfo copyWith({
    String? callId,
    String? callerNumber,
    String? callerName,
    DateTime? startTime,
    CallDirection? direction,
    CallStatus? status,
  }) {
    return CallInfo(
      callId: callId ?? this.callId,
      callerNumber: callerNumber ?? this.callerNumber,
      callerName: callerName ?? this.callerName,
      startTime: startTime ?? this.startTime,
      direction: direction ?? this.direction,
      status: status ?? this.status,
    );
  }

  // محاسبه مدت زمان تماس
  Duration get duration => DateTime.now().difference(startTime);
}

enum CallDirection {
  incoming,  // تماس ورودی
  outgoing,  // تماس خروجی
}

enum CallStatus {
  ringing,    // در حال زنگ خوردن
  connecting, // در حال اتصال
  connected,  // متصل شده
  ended,      // قطع شده
  failed,     // ناموفق
}
```

---

## 3. فایل: lib/features/customer/data/models/customer_call_data.dart

```dart
import 'package:invoice/features/customer/domain/entities/customer.dart';
import 'package:invoice/features/document/domain/entities/document.dart';

/// ترکیب اطلاعات مشتری + آخرین سند برای نمایش در Popup
class CustomerCallData {
  final Customer customer;
  final Document? lastDocument;
  final String phoneNumber; // شماره‌ای که تماس گرفته

  const CustomerCallData({
    required this.customer,
    this.lastDocument,
    required this.phoneNumber,
  });

  factory CustomerCallData.fromJson(Map<String, dynamic> json) {
    return CustomerCallData(
      customer: Customer.fromJson(json['customer']),
      lastDocument: json['lastDocument'] != null 
          ? Document.fromJson(json['lastDocument'])
          : null,
      phoneNumber: json['phoneNumber'] as String? ?? '',
    );
  }
}
```

---

## 4. به‌روزرسانی: lib/features/customer/domain/entities/customer.dart

در کلاس Customer این فیلد را اضافه کنید:

```dart
class Customer extends Equatable {
  final String id;
  final String name;
  final List<String>? phoneNumbers;  // ← این خط را اضافه کنید
  final String? email;
  final String? address;
  // ... سایر فیلدها

  const Customer({
    required this.id,
    required this.name,
    this.phoneNumbers,  // ← این خط را اضافه کنید
    this.email,
    this.address,
    // ...
  });

  @override
  List<Object?> get props => [
    id, 
    name, 
    phoneNumbers,  // ← این خط را اضافه کنید
    email, 
    address,
    // ...
  ];
}
```

---

## 5. به‌روزرسانی: lib/features/customer/data/models/customer_model.dart

```dart
class CustomerModel extends Customer {
  const CustomerModel({
    required String id,
    required String name,
    List<String>? phoneNumbers,  // ← اضافه کنید
    String? email,
    String? address,
    // ...
  }) : super(
    id: id,
    name: name,
    phoneNumbers: phoneNumbers,  // ← اضافه کنید
    email: email,
    address: address,
    // ...
  );

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'] as String,
      name: json['name'] as String,
      phoneNumbers: json['phoneNumbers'] != null
          ? List<String>.from(json['phoneNumbers'])
          : null,  // ← اضافه کنید
      email: json['email'] as String?,
      address: json['address'] as String?,
      // ...
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phoneNumbers': phoneNumbers,  // ← اضافه کنید
      'email': email,
      'address': address,
      // ...
    };
  }
}
```

---

**نکته:** این فایل‌ها فقط مدل‌های داده هستند و هیچ منطق پیچیده‌ای ندارند. در بخش بعدی سرویس‌های اصلی را می‌نویسیم.
