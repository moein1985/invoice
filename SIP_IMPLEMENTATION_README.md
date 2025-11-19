# 📚 فهر

ت کامل فایل‌های پیاده‌سازی SIP Phone Integration

## 🎯 هدف
پیاده‌سازی سیستم SIP Phone در برنامه Flutter Web برای:
- دریافت تماس‌های ورودی از داخلی 1008
- شناسایی خودکار Caller ID
- جستجوی مشتری در دیتابیس
- نمایش گردش کار (آخرین فاکتور) مشتری

---

## 📁 فایل‌های راهنما

### 1️⃣ SIP_IMPLEMENTATION_BACKEND.md
**محتوا:**
- اضافه کردن فیلد `phone_numbers` به جدول `customers`
- ایجاد API endpoint: `GET /api/customers/by-phone/:phoneNumber`
- دستورات SQL برای ایجاد و تست
- نمونه curl برای تست API

**مسیر Backend:** `backend/src/routes/customers.js`

---

### 2️⃣ SIP_IMPLEMENTATION_MODELS.md
**محتوا:**
- مدل `SipConfig` - پیکربندی اتصال SIP
- مدل `CallInfo` - اطلاعات تماس فعال
- مدل `CustomerCallData` - ترکیب اطلاعات مشتری + سند
- به‌روزرسانی `Customer` entity و `CustomerModel`

**فایل‌های Dart:**
- `lib/core/models/sip_config.dart`
- `lib/core/models/call_info.dart`
- `lib/features/customer/data/models/customer_call_data.dart`
- تغییرات در `lib/features/customer/domain/entities/customer.dart`
- تغییرات در `lib/features/customer/data/models/customer_model.dart`

---

### 3️⃣ SIP_IMPLEMENTATION_SERVICE.md
**محتوا:**
- اضافه کردن JsSIP به `web/index.html`
- اضافه کردن `js: ^0.6.7` به `pubspec.yaml`
- پیاده‌سازی کامل `WebSipService` با JsSIP
- مدیریت Registration, تماس ورودی/خروجی، DTMF

**فایل Dart:**
- `lib/core/services/web_sip_service.dart` (500+ خط کد)

---

### 4️⃣ SIP_IMPLEMENTATION_NOTIFICATION.md
**محتوا:**
- پیاده‌سازی `CallNotificationService` - جستجوی مشتری
- پیاده‌سازی `SipIntegrationService` - ترکیب SIP + Notification
- ثبت سرویس‌ها در `injection_container.dart`
- راه‌اندازی در `main.dart`

**فایل‌های Dart:**
- `lib/core/services/call_notification_service.dart`
- `lib/core/services/sip_integration_service.dart`
- تغییرات در `lib/injection_container.dart`
- تغییرات در `lib/main.dart`

---

### 5️⃣ SIP_IMPLEMENTATION_TESTING.md
**محتوا:**
- چک‌لیست کامل پیاده‌سازی
- مراحل تست Backend و Frontend
- راهنمای اتصال به ایزابل یا Asterisk
- عیب‌یابی مشکلات رایج (10 مشکل + راه‌حل)
- لاگ‌های مهم برای دیباگ
- معیارهای موفقیت

---

## 🗂️ ساختار فایل‌های جدید

```
invoice/
├── backend/
│   └── src/
│       └── routes/
│           └── customers.js  [تغییر: اضافه شدن route by-phone]
│
├── lib/
│   ├── core/
│   │   ├── models/
│   │   │   ├── sip_config.dart        [جدید]
│   │   │   └── call_info.dart         [جدید]
│   │   │
│   │   └── services/
│   │       ├── web_sip_service.dart           [جدید - 500+ خط]
│   │       ├── call_notification_service.dart [جدید - 100 خط]
│   │       └── sip_integration_service.dart   [جدید - 150 خط]
│   │
│   ├── features/
│   │   └── customer/
│   │       ├── domain/
│   │       │   └── entities/
│   │       │       └── customer.dart          [تغییر: phoneNumbers]
│   │       │
│   │       └── data/
│   │           └── models/
│   │               ├── customer_model.dart    [تغییر: phoneNumbers]
│   │               └── customer_call_data.dart [جدید]
│   │
│   ├── injection_container.dart  [تغییر: ثبت SIP services]
│   └── main.dart                 [تغییر: راه‌اندازی SIP]
│
├── web/
│   └── index.html  [تغییر: اضافه JsSIP CDN]
│
├── pubspec.yaml  [تغییر: اضافه js: ^0.6.7]
│
└── [فایل‌های راهنما]
    ├── SIP_IMPLEMENTATION_BACKEND.md
    ├── SIP_IMPLEMENTATION_MODELS.md
    ├── SIP_IMPLEMENTATION_SERVICE.md
    ├── SIP_IMPLEMENTATION_NOTIFICATION.md
    └── SIP_IMPLEMENTATION_TESTING.md
```

---

## 🔄 ترتیب پیاده‌سازی (برای دستیار هوش مصنوعی)

### مرحله 1: Backend
1. اجرای SQL برای اضافه کردن `phone_numbers`
2. اضافه کردن route در `customers.js`
3. تست با curl

### مرحله 2: Models
1. ایجاد `sip_config.dart`
2. ایجاد `call_info.dart`
3. ایجاد `customer_call_data.dart`
4. به‌روزرسانی `customer.dart` و `customer_model.dart`

### مرحله 3: Services - Part 1
1. اضافه JsSIP به `web/index.html`
2. اضافه `js` به `pubspec.yaml`
3. ایجاد `web_sip_service.dart`

### مرحله 4: Services - Part 2
1. ایجاد `call_notification_service.dart`
2. ایجاد `sip_integration_service.dart`

### مرحله 5: Integration
1. به‌روزرسانی `injection_container.dart`
2. به‌روزرسانی `main.dart`

### مرحله 6: Testing
1. تست Backend API
2. تست Flutter Connection
3. تست با SIP Server

---

## ⚙️ پیکربندی مورد نیاز

```dart
// مقادیری که باید در main.dart تنظیم شوند:
final config = SipConfig(
  sipServer: '192.168.1.100',  // ← IP ایزابل یا Gateway
  sipPort: '8089',              // ← پورت WebSocket
  extension: '1008',            // ← شماره داخلی
  password: 'your-password',    // ← رمز عبور
  displayName: 'کارمند فروش',
  autoAnswer: false,
);
```

```sql
-- داده نمونه برای تست:
UPDATE customers 
SET phone_numbers = JSON_ARRAY('09123456789', '12345678', '02112345678') 
WHERE name = 'خلیلی';
```

---

## 🎯 نتیجه نهایی

بعد از پیاده‌سازی:
1. ✅ وقتی به داخلی 1008 زنگ می‌زنید
2. ✅ Flutter خودکار Caller ID را می‌گیرد (مثلاً 12345678)
3. ✅ در دیتابیس جستجو می‌کند
4. ✅ اگر مشتری پیدا شد، اطلاعات + آخرین فاکتور را برمی‌گرداند
5. ✅ در Console log می‌شود (فعلاً UI نداریم)

---

## 📞 پشتیبانی

**مشکلات رایج:**
- WebSocket Connection Failed → چک IP, Port, Firewall
- Registration Failed → چک Username, Password
- Customer Not Found → چک داده دیتابیس
- No Audio → چک Microphone Permission, STUN servers

**همه راه‌حل‌ها در `SIP_IMPLEMENTATION_TESTING.md` است.**

---

## ⏭️ مرحله بعد (بعد از تست موفق)

اگر همه چیز کار کرد، UI اضافه می‌کنیم:
- Popup نمایش اطلاعات مشتری
- دکمه‌های Answer/Hangup
- نمایش وضعیت تماس
- لینک به پروفایل مشتری

**فعلاً فقط منطق را پیاده کنید و تست کنید! 🚀**
