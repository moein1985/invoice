import 'package:dio/dio.dart';
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
    // Map backend minimal fields to model, keep optionals default
    return CustomerModel(
      id: json['id'],
      name: json['name'],
      phone: json['phone'] ?? '',
      email: null,
      address: json['address'],
      company: null,
      nationalId: null,
      creditLimit: 0.0,
      currentDebt: 0.0,
      isActive: json['isActive'] ?? json['is_active'] ?? true,
      createdAt: DateTime.parse((json['createdAt'] ?? json['created_at']).toString()),
      lastTransaction: null,
    );
  }

  Map<String, dynamic> _toApi(CustomerModel c) {
    return {
      'name': c.name,
      'phone': c.phone,
      'address': c.address,
    };
  }

  @override
  Future<List<CustomerModel>> getCustomers() async {
    try {
      final res = await dio.get('/api/customers');
      final list = (res.data as List).cast<Map<String, dynamic>>();
      return list.map(_fromApi).toList();
    } on DioException {
      throw CacheException('خطا در دریافت مشتریان');
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
