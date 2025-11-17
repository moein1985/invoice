# 📋 پیشنهادات بهبود برنامه Invoice - مطابق با فایل Excel

## 📊 خلاصه تحلیل

بر اساس بررسی فایل Excel شما (`Raw invoice.xlsm`) و مقایسه با کد موجود برنامه Flutter، تغییرات زیر پیشنهاد می‌شود تا برنامه کاملاً با نیازهای فایل Excel شما هماهنگ شود.

---

## 🎯 تغییرات پیشنهادی

### **1. افزودن فیلد Unit (واحد اندازه‌گیری)**
### **2. جداسازی قیمت خرید و فروش**
### **3. محاسبات خودکار درصد سود**
### **4. بهبود فرمول‌های محاسباتی**

---

## 📝 مقایسه ساختار Excel با Entity فعلی

### **ساختار Excel (Sheet 1: لیست قیمت خرید)**
```
| ردیف | شرح کالا | تعداد | واحد | خرید واحد | دستی | فروش واحد | جمع خرید | جمع فروش |
|------|----------|-------|------|-----------|------|-----------|----------|----------|
|  A   |    C     |   R   |  T   |     V     |  Y   |    AA     |    AD    |    AH    |
```

### **ساختار Excel (Sheet 2: پیش فاکتور فروش)**
```
| ردیف | شرح کالا | تعداد | واحد | قیمت واحد | جمع ردیف |
|------|----------|-------|------|-----------|----------|
|  A   |    C     |   Q   |  S   |     U     |    Y     |
```

### **Entity فعلی (DocumentItemEntity)**
```dart
final String id;
final String productName;      // ✅ معادل "شرح کالا"
final int quantity;            // ✅ معادل "تعداد"
final double unitPrice;        // ⚠️ فقط یک قیمت (باید جدا شود)
final double totalPrice;       // ✅ معادل "جمع ردیف"
final double profitPercentage; // ✅ درصد سود
final String supplier;         // ✅ تامین‌کننده
final String? description;     // ✅ توضیحات
// ❌ فیلد "واحد" وجود ندارد
// ❌ "قیمت خرید" و "قیمت فروش" جدا نیستند
```

---

## 💻 کد پیشنهادی با تغییرات

### **تغییر 1️⃣: DocumentItemEntity (Domain Layer)**

#### ❌ **کد فعلی:**
```dart
// lib/features/document/domain/entities/document_item_entity.dart
import 'package:equatable/equatable.dart';

class DocumentItemEntity extends Equatable {
  final String id;
  final String productName;
  final int quantity;
  final double unitPrice;        // ⚠️ فقط یک قیمت
  final double totalPrice;
  final double profitPercentage;
  final String supplier;
  final String? description;

  const DocumentItemEntity({
    required this.id,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.profitPercentage,
    required this.supplier,
    this.description,
  });

  @override
  List<Object?> get props => [
        id,
        productName,
        quantity,
        unitPrice,
        totalPrice,
        profitPercentage,
        supplier,
        description,
      ];

  DocumentItemEntity copyWith({
    String? id,
    String? productName,
    int? quantity,
    double? unitPrice,
    double? totalPrice,
    double? profitPercentage,
    String? supplier,
    String? description,
  }) {
    return DocumentItemEntity(
      id: id ?? this.id,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      profitPercentage: profitPercentage ?? this.profitPercentage,
      supplier: supplier ?? this.supplier,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productName': productName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
      'profitPercentage': profitPercentage,
      'supplier': supplier,
      'description': description,
    };
  }

  factory DocumentItemEntity.fromJson(Map<String, dynamic> json) {
    return DocumentItemEntity(
      id: json['id'] as String,
      productName: json['productName'] as String,
      quantity: json['quantity'] as int,
      unitPrice: (json['unitPrice'] as num).toDouble(),
      totalPrice: (json['totalPrice'] as num).toDouble(),
      profitPercentage: (json['profitPercentage'] as num).toDouble(),
      supplier: json['supplier'] as String,
      description: json['description'] as String?,
    );
  }
}
```

#### ✅ **کد پیشنهادی:**
```dart
// lib/features/document/domain/entities/document_item_entity.dart
import 'package:equatable/equatable.dart';

class DocumentItemEntity extends Equatable {
  final String id;
  final String productName;
  final int quantity;
  final String unit;              // ✨ جدید: واحد اندازه‌گیری (عدد، کیلو، متر، ...)
  final double purchasePrice;     // ✨ تغییر نام: قیمت خرید (قبلاً unitPrice بود)
  final double sellPrice;         // ✨ جدید: قیمت فروش
  final double totalPrice;        // محاسبه می‌شود: quantity * sellPrice
  final double profitPercentage;  // محاسبه می‌شود: ((sellPrice - purchasePrice) / purchasePrice) * 100
  final String supplier;
  final String? description;

  const DocumentItemEntity({
    required this.id,
    required this.productName,
    required this.quantity,
    required this.unit,
    required this.purchasePrice,
    required this.sellPrice,
    required this.totalPrice,
    required this.profitPercentage,
    required this.supplier,
    this.description,
  });

  @override
  List<Object?> get props => [
        id,
        productName,
        quantity,
        unit,
        purchasePrice,
        sellPrice,
        totalPrice,
        profitPercentage,
        supplier,
        description,
      ];

  /// محاسبه خودکار totalPrice و profitPercentage
  factory DocumentItemEntity.create({
    required String id,
    required String productName,
    required int quantity,
    required String unit,
    required double purchasePrice,
    required double sellPrice,
    required String supplier,
    String? description,
  }) {
    final totalPrice = quantity * sellPrice;
    final profitPercentage = purchasePrice > 0
        ? ((sellPrice - purchasePrice) / purchasePrice) * 100
        : 0.0;

    return DocumentItemEntity(
      id: id,
      productName: productName,
      quantity: quantity,
      unit: unit,
      purchasePrice: purchasePrice,
      sellPrice: sellPrice,
      totalPrice: totalPrice,
      profitPercentage: profitPercentage,
      supplier: supplier,
      description: description,
    );
  }

  /// مبلغ سود
  double get profitAmount => (sellPrice - purchasePrice) * quantity;

  /// جمع خرید
  double get totalPurchasePrice => quantity * purchasePrice;

  DocumentItemEntity copyWith({
    String? id,
    String? productName,
    int? quantity,
    String? unit,
    double? purchasePrice,
    double? sellPrice,
    double? totalPrice,
    double? profitPercentage,
    String? supplier,
    String? description,
  }) {
    return DocumentItemEntity(
      id: id ?? this.id,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellPrice: sellPrice ?? this.sellPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      profitPercentage: profitPercentage ?? this.profitPercentage,
      supplier: supplier ?? this.supplier,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productName': productName,
      'quantity': quantity,
      'unit': unit,
      'purchasePrice': purchasePrice,
      'sellPrice': sellPrice,
      'totalPrice': totalPrice,
      'profitPercentage': profitPercentage,
      'supplier': supplier,
      'description': description,
    };
  }

  factory DocumentItemEntity.fromJson(Map<String, dynamic> json) {
    return DocumentItemEntity(
      id: json['id'] as String,
      productName: json['productName'] as String,
      quantity: json['quantity'] as int,
      unit: json['unit'] as String,
      purchasePrice: (json['purchasePrice'] as num).toDouble(),
      sellPrice: (json['sellPrice'] as num).toDouble(),
      totalPrice: (json['totalPrice'] as num).toDouble(),
      profitPercentage: (json['profitPercentage'] as num).toDouble(),
      supplier: json['supplier'] as String,
      description: json['description'] as String?,
    );
  }
}
```

---

### **تغییر 2️⃣: DocumentItemModel (Data Layer)**

#### ❌ **کد فعلی:**
```dart
// lib/features/document/data/models/document_item_model.dart
import 'package:hive/hive.dart';
import '../../domain/entities/document_item_entity.dart';

part 'document_item_model.g.dart';

@HiveType(typeId: 4)
class DocumentItemModel extends DocumentItemEntity {
  const DocumentItemModel({
    required super.id,
    required super.productName,
    required super.quantity,
    required super.unitPrice,
    required super.totalPrice,
    required super.profitPercentage,
    required super.supplier,
    super.description,
  });

  @override
  @HiveField(0)
  String get id => super.id;

  @override
  @HiveField(1)
  String get productName => super.productName;

  @override
  @HiveField(2)
  int get quantity => super.quantity;

  @override
  @HiveField(3)
  double get unitPrice => super.unitPrice;

  @override
  @HiveField(4)
  double get totalPrice => super.totalPrice;

  @override
  @HiveField(5)
  double get profitPercentage => super.profitPercentage;

  @override
  @HiveField(6)
  String get supplier => super.supplier;

  @override
  @HiveField(7)
  String? get description => super.description;

  factory DocumentItemModel.fromEntity(DocumentItemEntity entity) {
    return DocumentItemModel(
      id: entity.id,
      productName: entity.productName,
      quantity: entity.quantity,
      unitPrice: entity.unitPrice,
      totalPrice: entity.totalPrice,
      profitPercentage: entity.profitPercentage,
      supplier: entity.supplier,
      description: entity.description,
    );
  }

  factory DocumentItemModel.fromJson(Map<String, dynamic> json) {
    return DocumentItemModel(
      id: json['id'] as String,
      productName: json['productName'] as String,
      quantity: json['quantity'] as int,
      unitPrice: (json['unitPrice'] as num).toDouble(),
      totalPrice: (json['totalPrice'] as num).toDouble(),
      profitPercentage: (json['profitPercentage'] as num).toDouble(),
      supplier: json['supplier'] as String,
      description: json['description'] as String?,
    );
  }
}
```

#### ✅ **کد پیشنهادی:**
```dart
// lib/features/document/data/models/document_item_model.dart
import 'package:hive/hive.dart';
import '../../domain/entities/document_item_entity.dart';

part 'document_item_model.g.dart';

@HiveType(typeId: 4)
class DocumentItemModel extends DocumentItemEntity {
  const DocumentItemModel({
    required super.id,
    required super.productName,
    required super.quantity,
    required super.unit,
    required super.purchasePrice,
    required super.sellPrice,
    required super.totalPrice,
    required super.profitPercentage,
    required super.supplier,
    super.description,
  });

  @override
  @HiveField(0)
  String get id => super.id;

  @override
  @HiveField(1)
  String get productName => super.productName;

  @override
  @HiveField(2)
  int get quantity => super.quantity;

  @override
  @HiveField(3)
  String get unit => super.unit;

  @override
  @HiveField(4)
  double get purchasePrice => super.purchasePrice;

  @override
  @HiveField(5)
  double get sellPrice => super.sellPrice;

  @override
  @HiveField(6)
  double get totalPrice => super.totalPrice;

  @override
  @HiveField(7)
  double get profitPercentage => super.profitPercentage;

  @override
  @HiveField(8)
  String get supplier => super.supplier;

  @override
  @HiveField(9)
  String? get description => super.description;

  factory DocumentItemModel.fromEntity(DocumentItemEntity entity) {
    return DocumentItemModel(
      id: entity.id,
      productName: entity.productName,
      quantity: entity.quantity,
      unit: entity.unit,
      purchasePrice: entity.purchasePrice,
      sellPrice: entity.sellPrice,
      totalPrice: entity.totalPrice,
      profitPercentage: entity.profitPercentage,
      supplier: entity.supplier,
      description: entity.description,
    );
  }

  DocumentItemEntity toEntity() {
    return DocumentItemEntity(
      id: id,
      productName: productName,
      quantity: quantity,
      unit: unit,
      purchasePrice: purchasePrice,
      sellPrice: sellPrice,
      totalPrice: totalPrice,
      profitPercentage: profitPercentage,
      supplier: supplier,
      description: description,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productName': productName,
      'quantity': quantity,
      'unit': unit,
      'purchasePrice': purchasePrice,
      'sellPrice': sellPrice,
      'totalPrice': totalPrice,
      'profitPercentage': profitPercentage,
      'supplier': supplier,
      'description': description,
    };
  }

  factory DocumentItemModel.fromJson(Map<String, dynamic> json) {
    return DocumentItemModel(
      id: json['id'] as String,
      productName: json['productName'] as String,
      quantity: json['quantity'] as int,
      unit: json['unit'] as String,
      purchasePrice: (json['purchasePrice'] as num).toDouble(),
      sellPrice: (json['sellPrice'] as num).toDouble(),
      totalPrice: (json['totalPrice'] as num).toDouble(),
      profitPercentage: (json['profitPercentage'] as num).toDouble(),
      supplier: json['supplier'] as String,
      description: json['description'] as String?,
    );
  }
}
```

---

### **تغییر 3️⃣: Excel Export Service**

#### **بهبود در ExcelExportService**

```dart
// lib/features/export/services/excel_export_service.dart

// ✨ افزودن ستون‌های جدید به Excel
sheet.appendRow(_row([
  'ردیف',
  'شرح کالا',
  'تعداد',
  'واحد',              // ✨ جدید
  'قیمت خرید',         // ✨ جدید
  'قیمت فروش',         // ✨ تغییر نام
  'درصد سود',
  'جمع ردیف',
]));

// افزودن داده‌ها
for (var i = 0; i < document.items.length; i++) {
  final item = document.items[i];
  sheet.appendRow(_row([
    (i + 1).toString(),
    item.productName,
    item.quantity.toString(),
    item.unit,                          // ✨ جدید
    item.purchasePrice.toStringAsFixed(0), // ✨ جدید
    item.sellPrice.toStringAsFixed(0),     // ✨ تغییر نام
    '${item.profitPercentage.toStringAsFixed(1)}%',
    item.totalPrice.toStringAsFixed(0),
  ]));
}

// ✨ افزودن جمع کل خرید و فروش
final totalPurchase = document.items.fold<double>(
  0, (sum, item) => sum + item.totalPurchasePrice);
final totalProfit = document.items.fold<double>(
  0, (sum, item) => sum + item.profitAmount);

sheet.appendRow([]);
sheet.appendRow(_row(['جمع کل خرید', totalPurchase.toStringAsFixed(0)]));
sheet.appendRow(_row(['جمع کل فروش', document.totalAmount.toStringAsFixed(0)]));
sheet.appendRow(_row(['جمع سود', totalProfit.toStringAsFixed(0)]));
```

---

### **تغییر 4️⃣: PDF Export Service**

```dart
// lib/features/export/services/pdf_export_service.dart

// ✨ افزودن ستون‌های جدید به PDF
pw.Table(
  border: pw.TableBorder.all(),
  children: [
    // هدر جدول
    pw.TableRow(children: [
      pw.Text('ردیف'),
      pw.Text('شرح کالا'),
      pw.Text('تعداد'),
      pw.Text('واحد'),          // ✨ جدید
      pw.Text('قیمت خرید'),     // ✨ جدید
      pw.Text('قیمت فروش'),     // ✨ تغییر
      pw.Text('درصد سود'),
      pw.Text('جمع'),
    ]),
    // ردیف‌ها
    ...document.items.asMap().entries.map((entry) {
      final item = entry.value;
      return pw.TableRow(children: [
        pw.Text('${entry.key + 1}'),
        pw.Text(item.productName),
        pw.Text('${item.quantity}'),
        pw.Text(item.unit),                              // ✨ جدید
        pw.Text(NumberFormatter.formatCurrency(item.purchasePrice)), // ✨ جدید
        pw.Text(NumberFormatter.formatCurrency(item.sellPrice)),     // ✨ تغییر
        pw.Text('${item.profitPercentage.toStringAsFixed(1)}%'),
        pw.Text(NumberFormatter.formatCurrency(item.totalPrice)),
      ]);
    }),
  ],
),
```

---

## 📋 لیست واحدهای پیشنهادی

برای فیلد `unit`، می‌توانید از enum استفاده کنید:

```dart
// lib/core/enums/unit_type.dart
enum UnitType {
  piece,      // عدد
  kilogram,   // کیلوگرم
  meter,      // متر
  liter,      // لیتر
  box,        // بسته
  carton,     // کارتن
  package,    // بسته‌بندی
  roll,       // رول
  sheet,      // ورق
  set;        // ست

  String toFarsi() {
    switch (this) {
      case UnitType.piece:
        return 'عدد';
      case UnitType.kilogram:
        return 'کیلوگرم';
      case UnitType.meter:
        return 'متر';
      case UnitType.liter:
        return 'لیتر';
      case UnitType.box:
        return 'بسته';
      case UnitType.carton:
        return 'کارتن';
      case UnitType.package:
        return 'بسته‌بندی';
      case UnitType.roll:
        return 'رول';
      case UnitType.sheet:
        return 'ورق';
      case UnitType.set:
        return 'ست';
    }
  }
}
```

یا می‌توانید `unit` را به صورت `String` نگه دارید تا کاربران بتوانند واحدهای دلخواه خود را وارد کنند.

---

## ⚡ مراحل اعمال تغییرات

### **گام 1: بک‌آپ از دیتابیس**
```bash
# قبل از اعمال تغییرات، از دیتابیس Hive بک‌آپ بگیرید
```

### **گام 2: ویرایش Entity و Model**
1. ویرایش `document_item_entity.dart`
2. ویرایش `document_item_model.dart`
3. اجرای `flutter pub run build_runner build --delete-conflicting-outputs`

### **گام 3: Migration دیتابیس**
اگر داده‌های قبلی دارید، باید یک migration script بنویسید:

```dart
// lib/core/utils/database_migration.dart
Future<void> migrateDocumentItems() async {
  final box = await Hive.openBox<DocumentItemModel>('document_items');
  
  // خواندن تمام آیتم‌ها
  final oldItems = box.values.toList();
  
  // حذف باکس قدیمی
  await box.clear();
  
  // تبدیل و ذخیره با ساختار جدید
  for (var oldItem in oldItems) {
    final newItem = DocumentItemModel(
      id: oldItem.id,
      productName: oldItem.productName,
      quantity: oldItem.quantity,
      unit: 'عدد', // مقدار پیش‌فرض
      purchasePrice: oldItem.unitPrice * 0.8, // فرض: قیمت خرید 80% قیمت فروش
      sellPrice: oldItem.unitPrice,
      totalPrice: oldItem.totalPrice,
      profitPercentage: 20.0, // مقدار پیش‌فرض 20%
      supplier: oldItem.supplier,
      description: oldItem.description,
    );
    await box.add(newItem);
  }
}
```

### **گام 4: به‌روزرسانی UI**
تمام صفحاتی که `DocumentItemEntity` را نمایش می‌دهند باید به‌روز شوند تا فیلدهای جدید را نشان دهند.

### **گام 5: تست کامل**
- تست ایجاد سند جدید
- تست ویرایش سند
- تست Export به PDF/Excel
- تست محاسبات خودکار

---

## ✅ مزایای این تغییرات

1. ✨ **هماهنگی کامل با Excel**: ساختار برنامه دقیقاً مطابق با فایل Excel شما
2. ✨ **محاسبات دقیق‌تر**: جداسازی قیمت خرید و فروش → محاسبه دقیق سود
3. ✨ **واحد اندازه‌گیری**: قابلیت ثبت واحد برای هر محصول
4. ✨ **گزارشات بهتر**: امکان نمایش جمع کل خرید، فروش و سود
5. ✨ **انعطاف‌پذیری**: کاربران می‌توانند درصد سود را به راحتی ببینند و تغییر دهند

---

## 🚨 نکات مهم

### **Breaking Changes**
این تغییرات Breaking Change هستند و نیاز به:
- ✅ Migration دیتابیس
- ✅ به‌روزرسانی تمام جاهایی که `DocumentItemEntity` استفاده می‌شود
- ✅ تست کامل قبل از Deploy

### **نسخه‌بندی**
پیشنهاد می‌شود:
- نسخه فعلی را به عنوان `v1.0.0` تگ بزنید
- نسخه جدید را `v2.0.0` بنامید (به دلیل Breaking Changes)

---

## 📞 سوالات و پشتیبانی

اگر سوالی در مورد اعمال این تغییرات دارید یا نیاز به کمک دارید، لطفاً اطلاع دهید.

---

## 📊 خلاصه تطبیق با Excel

| فیلد Excel          | فیلد قبلی          | فیلد جدید          | وضعیت |
|---------------------|--------------------|--------------------|-------|
| شرح کالا            | productName        | productName        | ✅     |
| تعداد               | quantity           | quantity           | ✅     |
| واحد                | ❌ وجود نداشت      | unit               | ✨ جدید |
| خرید واحد          | ❌ وجود نداشت      | purchasePrice      | ✨ جدید |
| فروش واحد / قیمت واحد | unitPrice        | sellPrice          | 🔄 تغییر نام |
| جمع خرید            | ❌ وجود نداشت      | totalPurchasePrice | ✨ محاسباتی |
| جمع فروش / جمع ردیف | totalPrice         | totalPrice         | ✅     |
| درصد سود            | profitPercentage   | profitPercentage   | ✅ (محاسبه بهبود یافت) |
| تامین‌کننده         | supplier           | supplier           | ✅     |

---

**📅 تاریخ ایجاد:** 17 نوامبر 2025  
**📌 وضعیت:** پیشنهادی - در انتظار تایید  
**🔖 نسخه:** 2.0.0 (پیشنهادی)
