# وضعیت پیاده‌سازی SIP Phone Integration

## ✅ مراحل تکمیل شده

### 1. Backend API
- ✅ افزودن فیلد `phone_numbers` به جدول customers (JSON Array)
- ✅ ایجاد endpoint جدید: `GET /api/customers/by-phone/:phoneNumber`
- ✅ پیاده‌سازی جستجوی مشتری با `JSON_CONTAINS`
- ✅ برگرداندن customer + lastDocument

### 2. Flutter Models
- ✅ `lib/core/models/sip_config.dart` - پیکربندی اتصال SIP
- ✅ `lib/core/models/call_info.dart` - اطلاعات تماس (callId, direction, status)
- ✅ `lib/features/customer/data/models/customer_call_data.dart` - ترکیب مشتری + سند

### 3. Entity & Model Updates
- ✅ `CustomerEntity` - افزودن `List<String>? phoneNumbers`
- ✅ `CustomerModel` - افزودن `@HiveField(12) List<String>? phoneNumbers`

### 4. Web Setup
- ✅ افزودن JsSIP CDN به `web/index.html`
- ✅ افزودن `js: ^0.6.7` به `pubspec.yaml`

### 5. Services Layer
- ✅ `lib/core/services/web_sip_service.dart` - سرویس اصلی SIP با JsSIP
- ✅ `lib/core/services/call_notification_service.dart` - جستجوی مشتری
- ✅ `lib/core/services/sip_integration_service.dart` - لایه یکپارچه‌سازی

### 6. Dependency Injection
- ✅ ثبت `WebSipService` در injection_container.dart
- ✅ ثبت `CallNotificationService` در injection_container.dart
- ✅ ثبت `SipIntegrationService` در injection_container.dart

### 7. Main App Initialization
- ✅ مقداردهی SIP در `main.dart` (فقط برای Web)
- ✅ تنظیم callback ها
- ✅ مدیریت lifecycle (dispose)

## 📋 مراحل باقی‌مانده

### 1. Database Setup
```sql
-- افزودن فیلد phone_numbers به جدول customers
ALTER TABLE customers ADD COLUMN phone_numbers JSON DEFAULT NULL;

-- مثال: ثبت شماره تلفن برای مشتری خلیلی
UPDATE customers 
SET phone_numbers = JSON_ARRAY('12345678', '09121234567') 
WHERE name LIKE '%خلیلی%';
```

### 2. تست Backend API
```bash
# تست endpoint جدید
curl http://localhost:3000/api/customers/by-phone/12345678

# یا با Postman
GET http://localhost:3000/api/customers/by-phone/12345678
Authorization: Bearer YOUR_TOKEN
```

### 3. اجرای Flutter Web
```bash
# نصب dependencies
flutter pub get

# اجرای در مرورگر Chrome
flutter run -d chrome --web-port=8080
```

### 4. پیکربندی SIP Server
در فایل `main.dart` خط 182-188:
```dart
final config = SipConfig(
  sipServer: '192.168.1.100',  // ← آدرس سرور SIP خود را وارد کنید
  sipPort: '7443',              // ← پورت WebSocket را وارد کنید
  extension: '1008',            // ← شماره داخلی خود را وارد کنید
  password: 'your_password',    // ← رمز عبور را وارد کنید
  displayName: 'System Extension',
  autoAnswer: false,
);
```

### 5. تست با Softphone
1. نصب یک softphone (مثلاً Zoiper)
2. تماس به داخلی 1008
3. بررسی Console برای لاگ‌ها:
   - ✅ "SIP UA ایجاد شد"
   - ✅ "Registration موفق"
   - ✅ "تماس جدید دریافت شد"
   - ✅ "جستجوی مشتری با شماره"

## 🔄 جریان کار (Workflow)

```
1. تماس ورودی → WebSipService (JsSIP UA)
                  ↓
2. استخراج شماره تلفن → CallNotificationService
                         ↓
3. جستجو در API → GET /customers/by-phone/12345678
                   ↓
4. پاسخ دریافتی:
   ✅ مشتری پیدا شد → onCustomerCallReceived
   ❌ مشتری ناشناس → onUnknownCallReceived
                      ↓
5. نمایش UI (در مرحله بعد) → پاپ‌آپ با اطلاعات
```

## 🐛 مشکلات احتمالی و راه‌حل‌ها

### 1. خطای CORS در WebSocket
```javascript
// در سرور SIP خود (مثلاً Asterisk):
http.conf:
enabled=yes
bindaddr=0.0.0.0
bindport=7443
tlsenable=yes
tlsbindaddr=0.0.0.0:7443
```

### 2. خطای "SIP UA ایجاد نشد"
- بررسی کنید JsSIP در `web/index.html` لود شده باشد
- Console مرورگر را برای خطاهای JavaScript بررسی کنید
- مطمئن شوید که URL WebSocket صحیح است: `wss://SERVER:PORT/ws`

### 3. مشتری پیدا نمی‌شود
- فیلد `phone_numbers` در دیتابیس NULL نباشد
- شماره تلفن در فرمت JSON Array باشد: `["12345678"]`
- بررسی کنید backend در حال اجراست: `node src/server.js`

### 4. WebRTC Media Issues
- STUN server در دسترس باشد: `stun.l.google.com:19302`
- مرورگر دسترسی به میکروفون داشته باشد
- اتصال HTTPS فعال باشد (برای production)

## 📝 نکات مهم

1. **فقط Web**: این پیاده‌سازی فقط برای Flutter Web است (`if (kIsWeb)`)
2. **Security**: رمز عبور SIP را در production از environment variable بخوانید
3. **UI**: هنوز UI برای نمایش پاپ‌آپ پیاده‌سازی نشده (مرحله بعد)
4. **Testing**: ابتدا با شماره تست مشتری خلیلی (`12345678`) امتحان کنید
5. **Phone Cleaning**: شماره‌ها به صورت خودکار normalize می‌شوند (حذف 0098, 98, و غیر ارقام)

## 🎯 مرحله بعد: UI Implementation

در مرحله بعد باید:
1. ویجت پاپ‌آپ برای نمایش اطلاعات مشتری
2. دکمه‌های پاسخ/قطع تماس
3. نمایش وضعیت تماس در AppBar
4. صفحه تنظیمات SIP برای تغییر پیکربندی
5. ذخیره تاریخچه تماس‌ها

## 🚀 دستور اجرا

```bash
# 1. Backend
cd backend
npm install
node src/server.js

# 2. Flutter Web
cd ..
flutter pub get
flutter run -d chrome --web-port=8080

# 3. مرورگر را باز کنید و به Console دقت کنید
# باید ببینید: "✅ SIP Integration با موفقیت راه‌اندازی شد"
```

---
**تاریخ**: $(date)  
**وضعیت**: Backend + Services Layer تکمیل شده - آماده تست  
**مرحله بعد**: تست با SIP server واقعی + پیاده‌سازی UI
