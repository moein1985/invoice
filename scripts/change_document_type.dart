import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';

/// اسکریپت تغییر نوع سند
/// 
/// این اسکریپت نوع سند PRO-1001 را از proforma به tempProforma تغییر می‌دهد
/// برای استفاده: dart run scripts/change_document_type.dart

void main() async {
  print('🔄 تغییر نوع سند PRO-1001 به tempProforma...\n');
  
  try {
    // مقداردهی Hive
    final documentsPath = 'C:\\Users\\Moein\\Documents';
    Hive.init(documentsPath);
    
    // باز کردن باکس documents
    final box = await Hive.openBox('documents');
    
    print('📦 باکس documents باز شد');
    print('تعداد اسناد: ${box.length}\n');
    
    // یافتن سند PRO-1001
    Map<dynamic, dynamic>? targetDoc;
    dynamic targetKey;
    
    for (var key in box.keys) {
      final doc = box.get(key) as Map?;
      if (doc != null && doc['documentNumber'] == 'PRO-1001') {
        targetDoc = doc;
        targetKey = key;
        break;
      }
    }
    
    if (targetDoc == null) {
      print('❌ سند PRO-1001 یافت نشد!');
      exit(1);
    }
    
    print('✅ سند PRO-1001 یافت شد');
    print('نوع فعلی: ${targetDoc['documentType']}\n');
    
    // تغییر نوع به tempProforma
    targetDoc['documentType'] = 0; // 0 = tempProforma
    
    // ذخیره تغییرات
    await box.put(targetKey, targetDoc);
    
    print('✅ نوع سند به tempProforma تغییر یافت');
    print('لطفاً برنامه را Hot Reload کنید (فشردن r در terminal)\n');
    
    await box.close();
    
  } catch (e) {
    print('❌ خطا: $e');
    exit(1);
  }
  
  exit(0);
}
