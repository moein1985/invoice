# راهنمای تست و عیب‌یابی SIP Phone Integration

## 📋 چک‌لیست پیاده‌سازی

### ✅ بخش Backend
- [ ] اجرای SQL برای اضافه کردن فیلد `phone_numbers` به جدول `customers`
- [ ] اضافه کردن route `/api/customers/by-phone/:phoneNumber` به `backend/src/routes/customers.js`
- [ ] اضافه کردن داده نمونه (مشتری با شماره تلفن)
- [ ] تست API با Postman یا curl

### ✅ بخش Flutter - مدل‌ها
- [ ] ایجاد `lib/core/models/sip_config.dart`
- [ ] ایجاد `lib/core/models/call_info.dart`
- [ ] ایجاد `lib/features/customer/data/models/customer_call_data.dart`
- [ ] به‌روزرسانی `Customer` entity با فیلد `phoneNumbers`
- [ ] به‌روزرسانی `CustomerModel` با فیلد `phoneNumbers`

### ✅ بخش Flutter - سرویس‌ها
- [ ] اضافه کردن JsSIP به `web/index.html`
- [ ] اضافه کردن `js: ^0.6.7` به `pubspec.yaml`
- [ ] ایجاد `lib/core/services/web_sip_service.dart`
- [ ] ایجاد `lib/core/services/call_notification_service.dart`
- [ ] ایجاد `lib/core/services/sip_integration_service.dart`
- [ ] ثبت سرویس‌ها در `injection_container.dart`
- [ ] راه‌اندازی SIP در `main.dart`

---

## 🧪 مراحل تست

### مرحله 1: تست Backend

```bash
# راه‌اندازی Backend
cd backend
node src/server.js
```

**انتظار:** پیام `Server running on http://localhost:3000`

#### تست API با curl:

```bash
# ابتدا login کنید و JWT Token بگیرید:
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}'

# خروجی: {"token":"eyJhbGc..."}

# حالا جستجوی مشتری:
curl -X GET http://localhost:3000/api/customers/by-phone/12345678 \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"

# انتظار:
# - اگر مشتری وجود دارد: {"customer":{...}, "lastDocument":{...}}
# - اگر وجود ندارد: 404 {"error":"مشتری با این شماره تلفن یافت نشد"}
```

#### اضافه کردن داده نمونه:

```sql
-- در MySQL:
INSERT INTO customers (id, name, phone_numbers, email, address) 
VALUES (
  UUID(),
  'علی خلیلی',
  JSON_ARRAY('09123456789', '12345678', '02112345678'),
  'khalili@example.com',
  'تهران، خیابان ولیعصر'
);

-- یا به‌روزرسانی مشتری موجود:
UPDATE customers 
SET phone_numbers = JSON_ARRAY('09123456789', '12345678') 
WHERE name LIKE '%خلیلی%';
```

---

### مرحله 2: تست Flutter (بدون SIP Server)

```bash
# راه‌اندازی Flutter
flutter pub get
flutter run -d chrome --web-port=8080
```

**چک کردن Console مرورگر:**
- باز کنید: F12 → Console
- باید ببینید:
  ```
  ✅ WebSipService راه‌اندازی شد
  🚀 SIP UA ایجاد شد
  ```
- ممکن است خطا ببینید:
  ```
  ❌ WebSocket connection failed
  ```
  **این طبیعی است** چون هنوز به SIP Server متصل نشده‌ایم.

---

### مرحله 3: شبیه‌سازی تماس (بدون SIP Server)

برای تست منطق بدون SIP Server، می‌توانید مستقیماً callback را صدا بزنید:

```dart
// در main.dart برای تست:
void _testCall() {
  final sipService = di.sl<SipIntegrationService>();
  
  // شبیه‌سازی تماس ورودی
  sipService.onIncomingCall?.call('12345678', 'تست');
  
  // باید در Console ببینید:
  // 🔍 جستجوی مشتری با شماره: 12345678
  // ✅ مشتری پیدا شد: علی خلیلی
}

// در یک Button:
ElevatedButton(
  onPressed: _testCall,
  child: Text('تست تماس'),
)
```

---

### مرحله 4: تست با SIP Server واقعی

#### گزینه A: استفاده از Asterisk در Docker

```bash
# نصب Asterisk
docker run -d --name asterisk \
  -p 5060:5060/udp \
  -p 5060:5060/tcp \
  -p 8088:8088 \
  -p 8089:8089 \
  andrius/asterisk

# یا FreeSWITCH:
docker run -d --name freeswitch \
  -p 5060:5060/udp \
  -p 5080:5080/tcp \
  -p 8081:8081 \
  drachtio/drachtio-freeswitch-mrf
```

#### گزینه B: اتصال به ایزابل موجود

1. **پیدا کردن IP ایزابل:**
   ```bash
   # در شبکه محلی
   ping isabelle-server.local
   # یا مستقیم IP: 192.168.1.100
   ```

2. **بررسی پورت WebSocket:**
   - معمولاً: 8089 یا 5060
   - در مستندات ایزابل چک کنید

3. **ایجاد Extension در ایزابل:**
   - شماره داخلی: 1008
   - نوع: WebRTC یا SIP
   - رمز عبور: یک رمز قوی

4. **تست با Softphone:**
   - دانلود MicroSIP (Windows) یا Linphone
   - پیکربندی:
     ```
     SIP Server: 192.168.1.100
     Username: 1008
     Password: your-password
     Transport: UDP یا TCP
     ```
   - Register کنید
   - اگر موفق بود، به Flutter متصل کنید

5. **به‌روزرسانی پیکربندی در Flutter:**
   ```dart
   // در main.dart
   final config = SipConfig(
     sipServer: '192.168.1.100',  // IP ایزابل
     sipPort: '8089',              // پورت WebSocket
     extension: '1008',
     password: 'your-real-password',
     displayName: 'کارمند فروش',
   );
   ```

6. **راه‌اندازی Flutter و بررسی Console:**
   ```
   ✅ به سرور SIP متصل شد
   ✅ Registration موفق - داخلی 1008 فعال است
   ```

7. **تست تماس:**
   - با Softphone دیگر به 1008 زنگ بزنید
   - باید در Console ببینید:
     ```
     📞 تماس ورودی: 09123456789
     🔍 جستجوی مشتری...
     ✅ مشتری پیدا شد: علی خلیلی
     ```

---

## 🔧 عیب‌یابی مشکلات رایج

### مشکل 1: WebSocket Connection Failed
```
❌ WebSocket connection to 'wss://...' failed
```

**راه‌حل:**
- بررسی IP و Port صحیح باشد
- بررسی Firewall (پورت 8089 باز باشد)
- تست با `ws://` به جای `wss://` (فقط برای تست محلی)
- در کد جایگزین کنید:
  ```javascript
  const socket = new JsSIP.WebSocketInterface('ws://192.168.1.100:8089/ws');
  ```

### مشکل 2: Registration Failed - Authentication Error
```
❌ Registration ناموفق: 401 Unauthorized
```

**راه‌حل:**
- بررسی username و password صحیح باشد
- در ایزابل چک کنید Extension فعال است
- تست با Softphone دیگر

### مشکل 3: JsSIP is not defined
```
❌ ReferenceError: JsSIP is not defined
```

**راه‌حل:**
- بررسی `<script src="...jssip...">` در `web/index.html` اضافه شده
- `flutter clean && flutter pub get`
- مرورگر را Refresh سخت کنید (Ctrl+Shift+R)

### مشکل 4: CORS Error
```
❌ CORS policy: No 'Access-Control-Allow-Origin' header
```

**راه‌حل:**
- بررسی Backend روی port 3000 است
- بررسی Flutter روی port 8080 است
- بررسی `CORS_ORIGIN=*` در `backend/.env`

### مشکل 5: Customer Not Found
```
⚠️ مشتری با شماره ... یافت نشد
```

**راه‌حل:**
- بررسی داده نمونه در دیتابیس اضافه شده:
  ```sql
  SELECT id, name, phone_numbers FROM customers WHERE phone_numbers IS NOT NULL;
  ```
- بررسی فرمت شماره (باید به صورت JSON Array باشد)
- تست مستقیم API با curl

### مشکل 6: No Audio in Call
```
✅ تماس برقرار شد ولی صدا نیست
```

**راه‌حل:**
- بررسی مجوز Microphone در مرورگر (باید Allow باشد)
- بررسی STUN server قابل دسترسی است
- تست ICE Candidates:
  ```javascript
  pcConfig: {
    iceServers: [
      { urls: 'stun:stun.l.google.com:19302' },
      { urls: 'stun:stun1.l.google.com:19302' }
    ]
  }
  ```

---

## 📊 لاگ‌های مهم برای دیباگ

### Console مرورگر (F12):
```javascript
// موفق:
✅ SIP UA ایجاد شد
✅ به سرور SIP متصل شد
✅ Registration موفق - داخلی 1008 فعال است
📞 تماس ورودی: 12345678
🔍 جستجوی مشتری با شماره: 12345678
✅ مشتری پیدا شد: علی خلیلی

// ناموفق:
❌ WebSocket connection failed
❌ Registration ناموفق: 403 Forbidden
❌ خطا در جستجوی مشتری: DioError [...]
```

### Backend Terminal:
```
✅ Server running on http://localhost:3000
🔍 Searching for customer with phone: 12345678
✅ Customer found: علی خلیلی
```

---

## 📝 نکات مهم

1. **امنیت:** در production از `wss://` (WebSocket Secure) استفاده کنید
2. **رمز عبور:** در `main.dart` hard-code نکنید، از environment variables استفاده کنید
3. **تست قبل از UI:** حتماً ابتدا منطق را با Console.log تست کنید
4. **Network:** Backend و SIP Server باید در یک شبکه قابل دسترسی باشند
5. **Browser Permission:** اولین بار که صدا پخش می‌شود، مرورگر اجازه می‌خواهد

---

## ✅ معیار موفقیت

شما می‌دانید که سیستم کار می‌کند وقتی:
1. ✅ Backend API با `/by-phone/:phoneNumber` پاسخ می‌دهد
2. ✅ Flutter به SIP Server متصل می‌شود (Registration موفق)
3. ✅ وقتی زنگ می‌زنید، در Console می‌بینید: "تماس ورودی"
4. ✅ مشتری پیدا می‌شود و اطلاعاتش log می‌شود
5. ✅ صدای تماس شنیده می‌شود

---

## 🎯 مرحله بعد (بعد از تست موفق)

اگر همه چیز کار کرد:
1. ✅ طراحی UI برای Popup نمایش اطلاعات مشتری
2. ✅ دکمه‌های Answer/Hangup
3. ✅ نمایش اطلاعات تماس (مدت زمان، وضعیت)
4. ✅ لینک مستقیم به پروفایل مشتری
5. ✅ تاریخچه تماس‌ها

**فعلاً فقط منطق را تست کنید و بعد سراغ UI می‌رویم! 🚀**
