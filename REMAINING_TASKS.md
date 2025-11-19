# ✅ کارهای باقی‌مانده برای تست SIP Integration

## وضعیت فعلی (تکمیل شده):

### ✅ Backend:
- [x] Route `/api/customers/by-phone/:phoneNumber` اضافه شده
- [x] کد Node.js آماده است

### ✅ Flutter:
- [x] تمام Model ها ساخته شده
- [x] تمام Service ها پیاده‌سازی شده
- [x] Dependency Injection تنظیم شده
- [x] main.dart مقداردهی شده
- [x] بدون خطای compile

---

## 📋 کارهای باقی‌مانده (برای تست):

### 1️⃣ دیتابیس (MySQL) - اولویت بالا ⚡

```bash
# راه 1: از طریق MySQL Workbench یا phpMyAdmin
```

```sql
-- باز کردن دیتابیس
USE invoice_db;

-- اضافه کردن فیلد phone_numbers
ALTER TABLE customers ADD COLUMN phone_numbers JSON DEFAULT NULL;

-- اضافه کردن داده تست
UPDATE customers 
SET phone_numbers = JSON_ARRAY('09123456789', '12345678') 
WHERE name LIKE '%خلیلی%' 
LIMIT 1;

-- اگر مشتری خلیلی وجود نداشت:
INSERT INTO customers (id, name, phone_numbers, email, address, is_active) 
VALUES (
  UUID(),
  'خلیلی',
  JSON_ARRAY('09123456789', '12345678'),
  'khalili@example.com',
  'تهران',
  1
);

-- بررسی
SELECT id, name, phone_numbers FROM customers WHERE phone_numbers IS NOT NULL;
```

**چطور اجرا کنیم؟**
- باز کردن MySQL Workbench
- اتصال به localhost
- انتخاب دیتابیس `invoice_db`
- اجرای دستورات بالا

---

### 2️⃣ راه‌اندازی Backend - اولویت بالا ⚡

```bash
# Terminal 1: Backend
cd c:\Users\Administrator\Desktop\codes\invoice\invoice\backend
npm install  # اگر قبلاً نکرده‌اید
node src/server.js
```

**باید ببینید:**
```
✅ Connected to MySQL database
✅ Server running on port 3000
```

---

### 3️⃣ نصب Dependencies و اجرای Flutter Web

```bash
# Terminal 2: Flutter
cd c:\Users\Administrator\Desktop\codes\invoice\invoice
flutter pub get
flutter run -d chrome --web-port=8080
```

**باید ببینید:**
```
✅ Application Starting...
✅ SIP Integration با موفقیت راه‌اندازی شد
```

---

### 4️⃣ پیکربندی SIP Server - قبل از تست واقعی

**فایل:** `lib/main.dart` (خط 182)

```dart
final config = SipConfig(
  sipServer: '192.168.1.100',     // ← IP سرور SIP خود را وارد کنید
  sipPort: '7443',                 // ← پورت WebSocket (معمولاً 7443 یا 8089)
  extension: '1008',               // ← شماره داخلی شما
  password: 'your_password',       // ← رمز عبور داخلی
  displayName: 'System Extension',
  autoAnswer: false,
);
```

**اگر سرور SIP ندارید:**
- می‌توانید از [Asterisk](https://www.asterisk.org/) استفاده کنید
- یا از سرویس‌های cloud مثل [Twilio](https://www.twilio.com/)
- یا فعلاً فقط تست کنید که آیا کد اجرا می‌شود (بدون اتصال واقعی)

---

### 5️⃣ تست API با Postman/curl (اختیاری)

```bash
# ابتدا لاگین کنید و token بگیرید:
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}'

# سپس تست کنید:
curl -X GET "http://localhost:3000/api/customers/by-phone/12345678" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

**انتظار می‌رود:**
```json
{
  "customer": {
    "id": "...",
    "name": "خلیلی",
    "phoneNumbers": ["09123456789", "12345678"]
  },
  "lastDocument": {
    "documentNumber": "INV-001",
    ...
  }
}
```

---

## 🎯 ترتیب اجرا (Step by Step):

### مرحله 1: دیتابیس (5 دقیقه)
1. باز کردن MySQL Workbench
2. اجرای `ALTER TABLE customers ADD COLUMN phone_numbers JSON`
3. اجرای `INSERT` برای داده تست

### مرحله 2: Backend (2 دقیقه)
1. باز کردن Terminal در مسیر `backend`
2. اجرای `node src/server.js`
3. بررسی لاگ: "Server running on port 3000"

### مرحله 3: Flutter (5 دقیقه)
1. باز کردن Terminal جدید
2. اجرای `flutter pub get`
3. اجرای `flutter run -d chrome --web-port=8080`
4. بررسی Console مرورگر (F12)

### مرحله 4: بررسی لاگ‌ها
در Console مرورگر باید ببینید:
```
✅ SIP Integration با موفقیت راه‌اندازی شد
🚀 SIP UA ایجاد شد
⚠️ (احتمالاً خطای اتصال به SIP - طبیعی است اگر سرور ندارید)
```

---

## 🐛 مشکلات احتمالی:

### خطا: "Cannot connect to MySQL"
```bash
# بررسی MySQL در حال اجراست:
Get-Service -Name MySQL* 

# یا شروع MySQL:
net start MySQL80
```

### خطا: "Table customers doesn't exist"
```sql
-- دیتابیس را چک کنید:
SHOW DATABASES;
USE invoice_db;
SHOW TABLES;
```

### خطا در Flutter: "Port 8080 already in use"
```bash
# استفاده از پورت دیگر:
flutter run -d chrome --web-port=8081
```

---

## 📝 خلاصه:

**کارهای حتمی برای تست:**
1. ✅ اجرای SQL برای اضافه کردن `phone_numbers` 
2. ✅ اجرای `node src/server.js`
3. ✅ اجرای `flutter run -d chrome`

**کارهای اختیاری (بعداً):**
4. پیکربندی SIP Server واقعی
5. تست با softphone
6. پیاده‌سازی UI برای popup

---

## 🚀 دستور سریع (Copy & Paste):

```bash
# Terminal 1 - Backend
cd c:\Users\Administrator\Desktop\codes\invoice\invoice\backend
node src/server.js

# Terminal 2 - Flutter
cd c:\Users\Administrator\Desktop\codes\invoice\invoice
flutter pub get
flutter run -d chrome --web-port=8080
```

---

**سوال:** آیا می‌خواهید الان شروع کنیم یا ابتدا نیاز به کمک برای MySQL دارید؟
