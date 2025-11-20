import 'package:dio/dio.dart';
import '../../../../core/error/exceptions.dart';
import '../../../auth/data/models/user_model.dart';

abstract class UserRemoteDataSource {
  Future<List<UserModel>> getUsers();
  Future<UserModel> getUserById(String id);
  Future<UserModel> createUser({
    required String username,
    required String password,
    required String fullName,
    required String role,
  });
  Future<UserModel> updateUser({
    required String id,
    String? username,
    String? password,
    String? fullName,
    String? role,
    bool? isActive,
  });
  Future<void> deleteUser(String id);
}

class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  final Dio dio;
  UserRemoteDataSourceImpl({required this.dio});

  UserModel _fromApi(Map<String, dynamic> json) {
    // استفاده از fromJson که قبلاً type conversion ها را مدیریت می‌کند
    return UserModel.fromJson(json);
  }

  @override
  Future<List<UserModel>> getUsers() async {
    try {
      final res = await dio.get('/api/users');
      
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
    } on DioException {
      throw CacheException('خطا در دریافت کاربران');
    }
  }

  @override
  Future<UserModel> getUserById(String id) async {
    try {
      final res = await dio.get('/api/users/$id');
      return _fromApi(res.data as Map<String, dynamic>);
    } on DioException {
      throw CacheException('کاربر یافت نشد');
    }
  }

  @override
  Future<UserModel> createUser({
    required String username,
    required String password,
    required String fullName,
    required String role,
  }) async {
    try {
      final res = await dio.post('/api/users', data: {
        'username': username,
        'password': password,
        'fullName': fullName,
        'role': role,
      });
      return _fromApi(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final msg = e.response?.data is Map && (e.response?.data['error'] != null)
          ? e.response?.data['error']
          : 'خطا در ایجاد کاربر';
      throw CacheException(msg.toString());
    }
  }

  @override
  Future<UserModel> updateUser({
    required String id,
    String? username,
    String? password,
    String? fullName,
    String? role,
    bool? isActive,
  }) async {
    try {
      final res = await dio.put('/api/users/$id', data: {
        if (fullName != null) 'fullName': fullName,
        if (role != null) 'role': role,
        if (isActive != null) 'isActive': isActive,
      });
      return _fromApi(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final msg = e.response?.data is Map && (e.response?.data['error'] != null)
          ? e.response?.data['error']
          : 'خطا در بروزرسانی کاربر';
      throw CacheException(msg.toString());
    }
  }

  @override
  Future<void> deleteUser(String id) async {
    try {
      await dio.delete('/api/users/$id');
    } on DioException {
      throw CacheException('خطا در حذف کاربر');
    }
  }
}
