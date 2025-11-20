import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/error/exceptions.dart';
import '../models/customer_model.dart';

abstract class CustomerRemoteDataSource {
  Future<List<CustomerModel>> getCustomers();
  Future<CustomerModel> getCustomerById(String id);
  Future<CustomerModel> createCustomer(CustomerModel customer);
  Future<CustomerModel> updateCustomer(CustomerModel customer);
  Future<void> deleteCustomer(String id);
}

class CustomerRemoteDataSourceImpl implements CustomerRemoteDataSource {
  final Dio dio;
  CustomerRemoteDataSourceImpl({required this.dio});

  CustomerModel _fromApi(Map<String, dynamic> json) {
    // استفاده از fromJson که قبلاً type conversion ها را مدیریت می‌کند
    return CustomerModel.fromJson(json);
  }

  Map<String, dynamic> _toApi(CustomerModel c) {
    // استفاده از toJson که قبلاً پیاده‌سازی شده
    return c.toJson();
  }

  @override
  Future<List<CustomerModel>> getCustomers() async {
    try {
      final res = await dio.get('/api/customers');
      
      // چک کردن response format
      if (res.data is Map && res.data.containsKey('data')) {
        // Backend returns {data: [], pagination: {}}
        final data = res.data['data'];
        if (data is List) {
          final list = data.cast<Map<String, dynamic>>();
          return list.map(_fromApi).toList();
        }
      } else if (res.data is List) {
        // Direct array response
        final list = (res.data as List).cast<Map<String, dynamic>>();
        return list.map(_fromApi).toList();
      }
      
      return [];
    } on DioException catch (e) {
      debugPrint('🔴 [CustomerDataSource] DioException: ${e.type} - ${e.message}');
      debugPrint('🔴 [CustomerDataSource] Response: ${e.response?.data}');
      throw CacheException('خطا در دریافت مشتریان');
    } catch (e, stackTrace) {
      debugPrint('🔴 [CustomerDataSource] Unexpected error: $e');
      debugPrint('🔴 [CustomerDataSource] StackTrace: $stackTrace');
      throw CacheException('خطای نامشخص: $e');
    }
  }

  @override
  Future<CustomerModel> getCustomerById(String id) async {
    try {
      final res = await dio.get('/api/customers/$id');
      return _fromApi(res.data as Map<String, dynamic>);
    } on DioException {
      throw CacheException('مشتری یافت نشد');
    }
  }

  @override
  Future<CustomerModel> createCustomer(CustomerModel customer) async {
    try {
      final res = await dio.post('/api/customers', data: _toApi(customer));
      return _fromApi(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      debugPrint('🔴 [CustomerDataSource] Create failed: ${e.type} - ${e.message}');
      debugPrint('🔴 [CustomerDataSource] Response: ${e.response?.data}');
      final msg = e.response?.data is Map && (e.response?.data['error'] != null)
          ? e.response?.data['error']
          : 'خطا در ایجاد مشتری';
      throw CacheException(msg.toString());
    }
  }

  @override
  Future<CustomerModel> updateCustomer(CustomerModel customer) async {
    try {
      final res = await dio.put('/api/customers/${customer.id}', data: _toApi(customer));
      return _fromApi(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      debugPrint('🔴 [CustomerDataSource] Update failed: ${e.type} - ${e.message}');
      debugPrint('🔴 [CustomerDataSource] Response: ${e.response?.data}');
      final msg = e.response?.data is Map && (e.response?.data['error'] != null)
          ? e.response?.data['error']
          : 'خطا در بروزرسانی مشتری';
      throw CacheException(msg.toString());
    }
  }

  @override
  Future<void> deleteCustomer(String id) async {
    try {
      await dio.delete('/api/customers/$id');
    } on DioException {
      throw CacheException('خطا در حذف مشتری');
    }
  }
}
