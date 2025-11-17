# 🚀 راهنمای به‌روزرسانی به نسخه 2.0.0

## ✅ تغییرات اعمال شده

تمام تغییرات پیشنهادی با موفقیت پیاده‌سازی شدند:

### 1️⃣ **Entity و Model**
- ✅ افزودن فیلد `unit` (واحد اندازه‌گیری)
- ✅ تبدیل `unitPrice` به `purchasePrice` و `sellPrice`
- ✅ محاسبات خودکار `totalPrice` و `profitPercentage`
- ✅ افزودن getters: `profitAmount` و `totalPurchasePrice`

### 2️⃣ **Enum جدید**
- ✅ `UnitType` enum با 10 نوع واحد رایج
- ✅ متدهای تبدیل `toFarsi()` و `fromString()`

### 3️⃣ **Export Services**
- ✅ به‌روزرسانی Excel Export با ستون‌های جدید
- ✅ به‌روزرسانی PDF Export با ستون‌های جدید
- ✅ افزودن نمایش جمع کل خرید، فروش و سود

### 4️⃣ **Hive Adapters**
- ✅ بازسازی کدهای Hive با `build_runner`

### 5️⃣ **Migration Script**
- ✅ اسکریپت تبدیل دیتابیس قدیمی به جدید

---

## ⚠️ مراحل بعدی (مهم!)

### گام 1: بررسی Compile Errors

برنامه را اجرا کنید تا ببینیم آیا خطای compile وجود دارد:

```bash
flutter run
```

احتمالاً در جاهایی که `DocumentItemEntity` ایجاد می‌شود، خطا دریافت خواهید کرد. این خطاها را باید اصلاح کنید.

---

### گام 2: به‌روزرسانی UI و BLoC

باید در تمام جاهایی که `DocumentItemEntity` یا `DocumentItemModel` ساخته می‌شود، پارامترهای جدید را اضافه کنید:

#### ❌ **قبل:**
```dart
DocumentItemEntity(
  id: uuid.v4(),
  productName: 'محصول نمونه',
  quantity: 5,
  unitPrice: 10000,        // حذف شد
  totalPrice: 50000,
  profitPercentage: 20,
  supplier: 'تامین‌کننده',
);
```

#### ✅ **بعد:**
```dart
DocumentItemEntity.create(
  id: uuid.v4(),
  productName: 'محصول نمونه',
  quantity: 5,
  unit: 'عدد',             // جدید
  purchasePrice: 8000,      // جدید
  sellPrice: 10000,         // جدید
  supplier: 'تامین‌کننده',
);
```

یا اگر می‌خواهید خودتان محاسبه کنید:

```dart
DocumentItemEntity(
  id: uuid.v4(),
  productName: 'محصول نمونه',
  quantity: 5,
  unit: 'عدد',
  purchasePrice: 8000,
  sellPrice: 10000,
  totalPrice: 50000,        // quantity * sellPrice
  profitPercentage: 25,     // ((10000-8000)/8000)*100
  supplier: 'تامین‌کننده',
);
```

---

### گام 3: Migration دیتابیس (اگر داده قبلی دارید)

اگر داده‌های قبلی در Hive دارید، باید Migration را اجرا کنید:

#### 🔹 **روش 1: از طریق کد**

در فایل `main.dart`، قبل از `runApp` این کد را اضافه کنید:

```dart
import 'lib/core/utils/database_migration_v2.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // مقداردهی Hive
  await Hive.initFlutter();
  
  // ثبت Adapters
  Hive.registerAdapter(DocumentModelAdapter());
  Hive.registerAdapter(DocumentItemModelAdapter());
  // ... سایر adapters
  
  // ⚠️ Migration (فقط یک بار اجرا شود!)
  try {
    // ایجاد Backup
    await DatabaseMigrationV2.createBackup();
    
    // اجرای Migration
    await DatabaseMigrationV2.migrate();
    
    print('✅ Migration کامل شد!');
  } catch (e) {
    print('❌ خطا در Migration: $e');
    // در صورت خطا، از backup بازگردانی کنید
    // await DatabaseMigrationV2.restoreFromBackup();
  }
  
  runApp(const MyApp());
}
```

#### 🔹 **روش 2: شروع از صفر (پاک کردن دیتابیس)**

اگر داده مهمی ندارید، می‌توانید Hive را پاک کنید:

```dart
// پاک کردن تمام باکس‌های Hive
await Hive.deleteBoxFromDisk('documents');
await Hive.deleteBoxFromDisk('customers');
// ... سایر باکس‌ها
```

یا دستی فولدر Hive را پاک کنید:
- **Windows**: `C:\Users\<YourName>\AppData\Local\<AppName>\`
- **Linux**: `~/.local/share/<AppName>/`
- **macOS**: `~/Library/Application Support/<AppName>/`

---

### گام 4: به‌روزرسانی UI Forms

در فرم‌های ایجاد/ویرایش آیتم، فیلدهای جدید را اضافه کنید:

```dart
// فیلد واحد
TextFormField(
  decoration: InputDecoration(labelText: 'واحد'),
  initialValue: item?.unit ?? 'عدد',
  onSaved: (value) => _unit = value ?? 'عدد',
),

// فیلد قیمت خرید
TextFormField(
  decoration: InputDecoration(labelText: 'قیمت خرید'),
  keyboardType: TextInputType.number,
  onSaved: (value) => _purchasePrice = double.tryParse(value ?? '0') ?? 0,
),

// فیلد قیمت فروش
TextFormField(
  decoration: InputDecoration(labelText: 'قیمت فروش'),
  keyboardType: TextInputType.number,
  onSaved: (value) => _sellPrice = double.tryParse(value ?? '0') ?? 0,
),
```

---

### گام 5: تست کامل

پس از اعمال تغییرات، حتماً موارد زیر را تست کنید:

- [ ] ایجاد سند جدید (فاکتور/پیش‌فاکتور)
- [ ] ویرایش سند
- [ ] حذف سند
- [ ] Export به PDF (بررسی ستون‌های جدید)
- [ ] Export به Excel (بررسی ستون‌های جدید)
- [ ] محاسبات خودکار (جمع خرید، فروش، سود)
- [ ] نمایش لیست اسناد
- [ ] جستجو و فیلتر

---

## 🎯 فایل‌های تغییر یافته

```
lib/
├── core/
│   ├── enums/
│   │   └── unit_type.dart                    ✨ جدید
│   └── utils/
│       └── database_migration_v2.dart         ✨ جدید
├── features/
│   ├── document/
│   │   ├── domain/entities/
│   │   │   └── document_item_entity.dart      🔄 تغییر
│   │   └── data/models/
│   │       └── document_item_model.dart       🔄 تغییر
│   └── export/services/
│       ├── excel_export_service.dart          🔄 تغییر
│       └── pdf_export_service.dart            🔄 تغییر
```

---

## 📊 مثال کامل استفاده

```dart
// ایجاد آیتم جدید با factory method
final item = DocumentItemEntity.create(
  id: const Uuid().v4(),
  productName: 'لپ‌تاپ Asus',
  quantity: 2,
  unit: 'عدد',
  purchasePrice: 25000000,  // 25 میلیون
  sellPrice: 30000000,      // 30 میلیون
  supplier: 'شرکت توزیع',
  description: 'مدل ROG',
);

// خروجی خودکار:
// - totalPrice: 60000000 (2 * 30000000)
// - profitPercentage: 20% ((30M - 25M) / 25M * 100)
// - profitAmount: 10000000 (5M * 2)
// - totalPurchasePrice: 50000000 (25M * 2)

print('قیمت کل: ${item.totalPrice}');
print('درصد سود: ${item.profitPercentage}%');
print('مبلغ سود: ${item.profitAmount}');
```

---

## ❓ سوالات متداول

### 1. چرا باید Migration اجرا کنم?
اگر داده‌های قبلی دارید، ساختار آن‌ها با نسخه جدید سازگار نیست و باید تبدیل شوند.

### 2. اگر Migration خطا داد چه کنم?
از قبل Backup گرفته می‌شود. می‌توانید با `DatabaseMigrationV2.restoreFromBackup()` بازگردانی کنید.

### 3. آیا می‌توانم فیلد unit را اختیاری کنم?
بله، می‌توانید `unit` را `String?` کنید و مقدار پیش‌فرض ندهید.

### 4. آیا باید همه جا `factory create` استفاده کنم?
خیر، فقط برای راحتی است. می‌توانید constructor معمولی را هم استفاده کنید.

---

## 🔗 منابع مرتبط

- [IMPROVEMENT_PROPOSAL.md](./IMPROVEMENT_PROPOSAL.md) - جزئیات کامل تغییرات
- [Hive Documentation](https://docs.hivedb.dev/)
- [Flutter Clean Architecture](https://resocoder.com/flutter-clean-architecture-tdd/)

---

## ✉️ پشتیبانی

اگر سوال یا مشکلی دارید:
1. خطاهای compile را در اینجا گزارش دهید
2. لاگ‌های Migration را ذخیره کنید
3. مشکل را با جزئیات شرح دهید

---

**📅 تاریخ به‌روزرسانی:** 17 نوامبر 2025  
**📌 نسخه:** 2.0.0  
**✍️ وضعیت:** پیاده‌سازی شده - نیاز به تست
