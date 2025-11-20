# 🚀 راهنمای استفاده از سیستم Database-First

## ✅ کارهای انجام شده

### 1. زیرساخت و ابزارها
- ✅ نصب Jest, Supertest, @pact-foundation/pact
- ✅ پیکربندی Jest با coverage threshold 70%
- ✅ ایجاد دیتابیس تست `invoice_db_test`
- ✅ Scripts برای setup و cleanup دیتابیس

### 2. استخراج و مستندسازی Schema
- ✅ استخراج ساختار 4 جدول از MySQL:
  - customers (12 columns, 0 FKs)
  - document_items (11 columns, 1 FK)
  - documents (21 columns, 4 FKs)
  - users (8 columns, 0 FKs)
- ✅ تولید `backend/docs/database-schema.json`
- ✅ تولید `backend/docs/DATABASE_SCHEMA.md` با جزئیات کامل

### 3. Code Generators
- ✅ `generate-route-from-schema.js` - تولید Backend Routes
- ✅ `generate-dart-model.js` - تولید Flutter Models
- ✅ تبدیل خودکار تایپ‌ها:
  - MySQL `TINYINT(1)` → JavaScript `boolean` & Dart `bool`
  - MySQL `DECIMAL` → JavaScript `number` & Dart `double`
  - MySQL `TIMESTAMP` → JavaScript `Date` & Dart `DateTime`

### 4. فایل‌های تولید شده
**Backend Routes (4 فایل):**
- `src/routes/customers.js`
- `src/routes/documents.js`
- `src/routes/document_items.js`
- `src/routes/users.js`

**Flutter Models (4 فایل):**
- `lib/generated_models/customer_model.dart`
- `lib/generated_models/document_model.dart`
- `lib/generated_models/document_item_model.dart`
- `lib/generated_models/user_model.dart`

---

## 📋 دستورات موجود

### استخراج و مستندسازی
```bash
# استخراج Schema از MySQL
npm run extract-schema

# تولید مستندات
npm run generate-docs

# اعتبارسنجی Schema
npm run validate-schema
```

### Code Generation
```bash
# تولید Route برای یک جدول
npm run generate:route <table_name>
npm run generate:route customers

# تولید Model برای یک جدول
npm run generate:model <table_name>
npm run generate:model customers

# تولید همه Routes و Models
npm run generate:all
```

### Test Database
```bash
# راه‌اندازی دیتابیس تست
npm run db:setup

# Seed داده‌های تست
npm run db:seed

# Reset کامل
npm run db:reset
```

### Testing
```bash
# اجرای تمام تست‌ها
npm test

# اجرای تست‌ها با Coverage
npm run test:coverage

# اجرای تست خاص
npm test -- customers.test.js

# Watch mode
npm run test:watch
```

---

## 🔄 Workflow توسعه Feature جدید

### مرحله 1: تغییر در MySQL
```sql
-- مثال: اضافه کردن فیلد جدید
ALTER TABLE customers ADD COLUMN loyalty_points INT DEFAULT 0;
```

### مرحله 2: استخراج Schema
```bash
npm run extract-schema
npm run generate-docs
```

### مرحله 3: Validation
```bash
npm run validate-schema
```
اگر خطایی وجود دارد، Joi schema را اصلاح کنید.

### مرحله 4: Code Generation
```bash
# تولید مجدد Route و Model
npm run generate:route customers
npm run generate:model customers
```

### مرحله 5: انتقال Model به Flutter
```bash
# از PowerShell
Copy-Item "lib\generated_models\customer_model.dart" -Destination "lib\features\customer\data\models\customer_model.dart" -Force
```

### مرحله 6: تست
```bash
npm test -- customers.test.js
```

---

## 🎯 ویژگی‌های کدهای تولید شده

### Backend Routes
- ✅ CRUD کامل (GET list, GET by ID, POST, PUT, DELETE)
- ✅ Pagination با `page` و `limit`
- ✅ Search/Filter
- ✅ Joi Validation
- ✅ تبدیل خودکار `snake_case` ↔ `camelCase`
- ✅ Type Conversion (TINYINT→bool, DECIMAL→number)
- ✅ Foreign Key Error Handling
- ✅ Authentication با middleware

### Flutter Models
- ✅ Equatable برای مقایسه
- ✅ `fromJson()` با Type Conversion:
  ```dart
  isActive: _parseBool(json['isActive'])
  creditLimit: _parseDouble(json['creditLimit'])
  createdAt: DateTime.parse(json['createdAt'])
  ```
- ✅ `toJson()` برای API requests
- ✅ `copyWith()` برای State Management
- ✅ Helper methods:
  - `_parseBool()` - تبدیل 0/1/true/false
  - `_parseDouble()` - تبدیل String/int به double

---

## 🔧 نکات مهم

### 1. Type Conversion در Backend
```javascript
// در mapLogic
isActive: item.is_active === 1  // TINYINT → boolean
creditLimit: item.credit_limit !== null ? parseFloat(item.credit_limit) : null  // DECIMAL → number
```

### 2. PUT Endpoint با Partial Update
```javascript
// استفاده از fork برای optional کردن فیلدها
const updateSchema = customersSchema.fork(
  Object.keys(customersSchema.describe().keys),
  (schema) => schema.optional()
);
```

### 3. Clean Database در تست‌ها
```javascript
// استفاده از DELETE به جای TRUNCATE
await pool.query('SET FOREIGN_KEY_CHECKS = 0');
await pool.query(`DELETE FROM ${tableName}`);
await pool.query('SET FOREIGN_KEY_CHECKS = 1');
```

### 4. Test User Seed
```javascript
// فیلدهای required: id, username, password_hash, full_name
await pool.query(`
  INSERT INTO users (id, username, password_hash, full_name, role, is_active)
  VALUES (?, ?, ?, ?, ?, ?)
`, [userId, 'testuser', hashedPassword, 'Test User', 'admin', 1]);
```

---

## 🐛 عیب‌یابی

### مشکل: Schema Validation Failed
```bash
# استخراج مجدد Schema
npm run extract-schema

# بررسی خروجی
npm run validate-schema
```

### مشکل: Test Database Connection Error
```bash
# بررسی دسترسی
docker exec invoice_mysql mysql -uinvoice_user -pinvoice_pass -e "SHOW DATABASES;"

# دادن دسترسی به test database
docker exec invoice_mysql mysql -uroot -pinvoice_root_pass -e "GRANT ALL PRIVILEGES ON invoice_db_test.* TO 'invoice_user'@'%'; FLUSH PRIVILEGES;"
```

### مشکل: Type Mismatch در Flutter
اطمینان حاصل کنید که:
- Backend `parseFloat()` برای DECIMAL استفاده می‌کند
- Backend `=== 1` برای TINYINT استفاده می‌کند
- Flutter `_parseBool()` و `_parseDouble()` دارد

---

## 📊 Coverage Requirements

```javascript
coverageThreshold: {
  global: {
    branches: 70,
    functions: 70,
    lines: 70,
    statements: 70
  }
}
```

---

## 🚀 مراحل بعدی (پیشنهادی)

### 1. Contract Testing با Pact
- نصب `@pact-foundation/pact` در Flutter
- نوشتن Consumer Tests
- Provider Verification در Backend

### 2. CI/CD Integration
- GitHub Actions workflow
- Automated testing
- Schema validation در pipeline

### 3. Pre-commit Hooks
```bash
# .git/hooks/pre-commit
#!/bin/bash
npm run validate-schema
if [ $? -ne 0 ]; then
  echo "❌ Schema validation failed!"
  exit 1
fi
```

---

## 📚 مراجع

- [Jest Documentation](https://jestjs.io/)
- [Supertest](https://github.com/visionmedia/supertest)
- [Joi Validation](https://joi.dev/api/)
- [Pact](https://docs.pact.io/)

---

**تاریخ ایجاد:** 20 نوامبر 2025  
**نسخه:** 1.0.0  
**وضعیت:** آماده برای استفاده در Production
