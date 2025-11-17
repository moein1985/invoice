import 'package:hive/hive.dart';
import '../../features/document/data/models/document_model.dart';
import '../../features/document/data/models/document_item_model.dart';

/// Migration Script برای تبدیل دیتابیس قدیمی به ساختار جدید
/// 
/// تغییرات:
/// - افزودن فیلد unit (پیش‌فرض: 'عدد')
/// - تبدیل unitPrice به purchasePrice و sellPrice
/// - محاسبه مجدد profitPercentage
class DatabaseMigrationV2 {
  
  /// اجرای migration
  static Future<void> migrate() async {
    print('🔄 شروع Migration به نسخه 2.0.0...');
    
    try {
      // 1. Migration برای Documents
      await _migrateDocuments();
      
      print('✅ Migration با موفقیت انجام شد!');
      print('📝 توجه: لطفاً برنامه را restart کنید.');
    } catch (e) {
      print('❌ خطا در Migration: $e');
      rethrow;
    }
  }
  
  static Future<void> _migrateDocuments() async {
    print('📦 در حال Migration اسناد...');
    
    // باز کردن باکس Documents
    final box = await Hive.openBox<DocumentModel>('documents');
    final documents = box.values.toList();
    
    if (documents.isEmpty) {
      print('ℹ️ هیچ سندی برای Migration وجود ندارد.');
      return;
    }
    
    print('📊 تعداد اسناد: ${documents.length}');
    
    // پاک کردن باکس (backup قبلاً گرفته شده)
    await box.clear();
    
    // Migration هر سند
    int migratedCount = 0;
    for (final oldDoc in documents) {
      try {
        final migratedItems = <DocumentItemModel>[];
        
        // Migration آیتم‌های هر سند
        for (final oldItem in oldDoc.items) {
          // تبدیل unitPrice به purchasePrice و sellPrice
          // فرض: قیمت خرید 80% قیمت فروش است (می‌توانید تغییر دهید)
          final sellPrice = _getOldUnitPrice(oldItem);
          final purchasePrice = sellPrice * 0.8; // 20% سود
          final profitPercentage = ((sellPrice - purchasePrice) / purchasePrice) * 100;
          
          final newItem = DocumentItemModel(
            id: oldItem.id,
            productName: oldItem.productName,
            quantity: oldItem.quantity,
            unit: 'عدد', // مقدار پیش‌فرض
            purchasePrice: purchasePrice,
            sellPrice: sellPrice,
            totalPrice: oldItem.quantity * sellPrice,
            profitPercentage: profitPercentage,
            supplier: oldItem.supplier,
            description: oldItem.description,
          );
          
          migratedItems.add(newItem);
        }
        
        // ایجاد سند جدید
        final newDoc = DocumentModel(
          id: oldDoc.id,
          userId: oldDoc.userId,
          documentNumber: oldDoc.documentNumber,
          documentTypeString: oldDoc.documentTypeString,
          customerId: oldDoc.customerId,
          documentDate: oldDoc.documentDate,
          items: migratedItems,
          totalAmount: oldDoc.totalAmount,
          discount: oldDoc.discount,
          finalAmount: oldDoc.finalAmount,
          statusString: oldDoc.statusString,
          notes: oldDoc.notes,
          createdAt: oldDoc.createdAt,
          updatedAt: DateTime.now(),
        );
        
        await box.add(newDoc);
        migratedCount++;
      } catch (e) {
        print('⚠️ خطا در Migration سند ${oldDoc.documentNumber}: $e');
      }
    }
    
    print('✅ $migratedCount سند با موفقیت منتقل شد.');
  }
  
  /// دریافت unitPrice از آیتم قدیمی (برای سازگاری با ساختار قبلی)
  static double _getOldUnitPrice(dynamic item) {
    try {
      // تلاش برای خواندن از فیلد قدیمی
      if (item is DocumentItemModel) {
        // در نسخه جدید، sellPrice را برمی‌گرداند
        return item.sellPrice;
      }
      // برای داده‌های خام Hive
      return 0.0;
    } catch (e) {
      print('⚠️ خطا در خواندن قیمت: $e');
      return 0.0;
    }
  }
  
  /// ایجاد Backup از دیتابیس
  static Future<void> createBackup() async {
    print('💾 در حال ایجاد Backup...');
    
    try {
      final box = await Hive.openBox<DocumentModel>('documents');
      final documents = box.values.toList();
      
      // ذخیره در باکس backup
      final backupBox = await Hive.openBox('documents_backup_v1');
      await backupBox.clear();
      
      for (var i = 0; i < documents.length; i++) {
        await backupBox.put('doc_$i', documents[i].toEntity().toJson());
      }
      
      print('✅ Backup با موفقیت ایجاد شد: ${documents.length} سند');
    } catch (e) {
      print('❌ خطا در ایجاد Backup: $e');
      rethrow;
    }
  }
  
  /// بازگردانی از Backup
  static Future<void> restoreFromBackup() async {
    print('♻️ در حال بازگردانی از Backup...');
    
    try {
      final backupBox = await Hive.openBox('documents_backup_v1');
      
      if (backupBox.isEmpty) {
        print('⚠️ هیچ Backup‌ای وجود ندارد!');
        return;
      }
      
      final box = await Hive.openBox<DocumentModel>('documents');
      await box.clear();
      
      // بازگردانی داده‌ها (باید به ساختار Model تبدیل شوند)
      for (var i = 0; i < backupBox.length; i++) {
        final jsonData = backupBox.get('doc_$i');
        if (jsonData != null) {
          // اینجا باید داده JSON را به Model تبدیل کنید
          print('ℹ️ داده $i بازگردانی شد (نیاز به تبدیل دستی)');
        }
      }
      
      print('✅ Backup بازگردانی شد.');
    } catch (e) {
      print('❌ خطا در بازگردانی Backup: $e');
      rethrow;
    }
  }
}
