import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:invoice/features/customer/data/models/customer_call_data.dart';
import 'package:invoice/features/customer/domain/entities/customer_entity.dart';
import 'package:invoice/features/document/domain/entities/document_entity.dart';

/// سرویس مدیریت اطلاع‌رسانی تماس‌ها و جستجوی مشتری
class CallNotificationService {
  final Dio _dio;
  
  CallNotificationService(this._dio);

  /// جستجوی مشتری با شماره تلفن
  Future<CustomerCallData?> lookupCustomer(String phoneNumber) async {
    try {
      debugPrint('🔍 جستجوی مشتری با شماره: $phoneNumber');
      
      // حذف کاراکترهای اضافی از شماره
      final cleanNumber = _cleanPhoneNumber(phoneNumber);
      
      final response = await _dio.get(
        '/customers/by-phone/$cleanNumber',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        debugPrint('✅ مشتری پیدا شد: ${response.data['customer']['name']}');
        
        return CustomerCallData(
          customer: CustomerEntity.fromJson(response.data['customer']),
          lastDocument: response.data['lastDocument'] != null
              ? DocumentEntity.fromJson(response.data['lastDocument'])
              : null,
          phoneNumber: cleanNumber,
        );
      }
      
      return null;
      
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        debugPrint('⚠️ مشتری با شماره $phoneNumber یافت نشد');
        return null;
      }
      
      debugPrint('❌ خطا در جستجوی مشتری: ${e.message}');
      return null;
      
    } catch (e) {
      debugPrint('❌ خطای غیرمنتظره در جستجوی مشتری: $e');
      return null;
    }
  }

  /// پاکسازی شماره تلفن (حذف فاصله، خط تیره، و...)
  String _cleanPhoneNumber(String phoneNumber) {
    // حذف تمام کاراکترهای غیر عددی
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    
    // اگر با 0098 شروع شود، به 0 تبدیل کن
    if (cleaned.startsWith('0098')) {
      cleaned = '0${cleaned.substring(4)}';
    }
    // اگر با 98 شروع شود (بدون 00)
    else if (cleaned.startsWith('98') && cleaned.length > 10) {
      cleaned = '0${cleaned.substring(2)}';
    }
    
    return cleaned;
  }

  /// ذخیره تاریخچه تماس (اختیاری - برای آینده)
  Future<void> saveCallHistory({
    required String phoneNumber,
    required String? customerName,
    required String direction,
    required int durationSeconds,
  }) async {
    try {
      // این API را در آینده می‌توانید پیاده کنید
      await _dio.post('/call-history', data: {
        'phoneNumber': phoneNumber,
        'customerName': customerName,
        'direction': direction,
        'duration': durationSeconds,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      debugPrint('✅ تاریخچه تماس ذخیره شد');
    } catch (e) {
      debugPrint('⚠️ خطا در ذخیره تاریخچه: $e');
      // عدم ذخیره تاریخچه نباید مانع کار شود
    }
  }
}
