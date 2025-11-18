import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// اسکریپت پاک کردن دیتابیس
/// 
/// این اسکریپت تمام باکس‌های Hive را پاک می‌کند
/// برای استفاده: dart run scripts/clear_database.dart

void main() async {
  if (kDebugMode) {
    print('🗑️  شروع پاک‌سازی دیتابیس...');
  }
  
  try {
    // مقداردهی Hive
    await Hive.initFlutter();
    
    // لیست باکس‌ها
    final boxes = [
      'auth',
      'currentUser',
      'customers',
      'documents',
    ];
    
    if (kDebugMode) {
      print('\n📦 باکس‌های موجود:');
    }
    for (var boxName in boxes) {
      final boxExists = await Hive.boxExists(boxName);
      if (kDebugMode) {
        print('  - $boxName: ${boxExists ? "✓ وجود دارد" : "✗ وجود ندارد"}');
      }
    }
    
    if (kDebugMode) {
      print('\n⚠️  آیا مطمئن هستید که می‌خواهید تمام داده‌ها را پاک کنید؟');
    }
    if (kDebugMode) {
      print('این عملیات قابل بازگشت نیست!');
    }
    if (kDebugMode) {
      print('\nبرای ادامه "yes" تایپ کنید: ');
    }
    
    final input = stdin.readLineSync();
    
    if (input?.toLowerCase() != 'yes') {
      if (kDebugMode) {
        print('\n❌ عملیات لغو شد.');
      }
      return;
    }
    
    if (kDebugMode) {
      print('\n🔥 در حال پاک کردن...\n');
    }
    
    for (var boxName in boxes) {
      try {
        await Hive.deleteBoxFromDisk(boxName);
        if (kDebugMode) {
          print('  ✅ $boxName پاک شد');
        }
      } catch (e) {
        if (kDebugMode) {
          print('  ⚠️  خطا در پاک کردن $boxName: $e');
        }
      }
    }
    
    if (kDebugMode) {
      print('\n✅ دیتابیس با موفقیت پاک شد!');
    }
    if (kDebugMode) {
      print('حالا می‌توانید برنامه را دوباره اجرا کنید.\n');
    }
    
  } catch (e) {
    if (kDebugMode) {
      print('\n❌ خطا: $e');
    }
    exit(1);
  }
  
  exit(0);
}
