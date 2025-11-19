import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/services/api_client.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login({required String username, required String password});
  Future<UserModel> me();
  Future<void> logout();
  Future<bool> isLoggedIn();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio dio;

  AuthRemoteDataSourceImpl({required this.dio});

  @override
  Future<UserModel> login({required String username, required String password}) async {
    try {
      if (kDebugMode) {
        print('🔵 Login attempt - URL: ${dio.options.baseUrl}/api/auth/login');
      }
      if (kDebugMode) {
        print('🔵 Username: $username');
      }
      if (kDebugMode) {
        print('🔵 Dio baseUrl: ${dio.options.baseUrl}');
      }
      if (kDebugMode) {
        print('🔵 Dio timeout: ${dio.options.connectTimeout}');
      }
      
      final response = await dio.post('/api/auth/login', data: {
        'username': username,
        'password': password,
      });
      
      if (kDebugMode) {
        print('✅ Response received: ${response.statusCode}');
      }

      final data = response.data as Map<String, dynamic>;
      final token = data['token'];
      final user = UserModel.fromJson({
        'id': data['user']['id'],
        'username': data['user']['username'],
        // Backend does not return password; store empty
        'password': '',
        'fullName': data['user']['fullName'],
        'role': data['user']['role'],
        'isActive': data['user']['isActive'] ?? true,
        'createdAt': data['user']['createdAt'],
        'lastLogin': null,
      });

      ApiClient.setToken(token);

      return user;
    } on DioException catch (e) {
      if (kDebugMode) {
        print('🔴 DioException: ${e.type}');
      }
      if (kDebugMode) {
        print('🔴 Response: ${e.response?.statusCode} - ${e.response?.data}');
      }
      if (kDebugMode) {
        print('🔴 Message: ${e.message}');
      }
      
      // Check response status code
      if (e.response != null) {
        final statusCode = e.response!.statusCode;
        final responseData = e.response!.data;
        
        // Handle specific status codes
        if (statusCode == 401 || statusCode == 403) {
          // Authentication failed
          final message = responseData is Map && responseData['error'] != null
              ? responseData['error']
              : 'نام کاربری یا رمز عبور اشتباه است';
          throw AuthException(message.toString());
        } else if (statusCode == 404) {
          throw AuthException('سرویس مورد نظر یافت نشد');
        } else if (statusCode! >= 500) {
          throw AuthException('خطای سرور. لطفا بعدا تلاش کنید');
        } else {
          // Other errors
          final message = responseData is Map && responseData['error'] != null
              ? responseData['error']
              : 'خطا در ارتباط با سرور';
          throw AuthException(message.toString());
        }
      } else {
        // No response (network error, timeout, etc.)
        throw AuthException('خطا در ارتباط با سرور. لطفا اتصال اینترنت خود را بررسی کنید');
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      if (kDebugMode) {
        print('🔴 Unexpected error: $e');
      }
      throw AuthException('خطای نامشخص: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> me() async {
    try {
      final response = await dio.get('/api/auth/me');
      final u = response.data as Map<String, dynamic>;
      return UserModel.fromJson({
        'id': u['id'],
        'username': u['username'],
        'password': '',
        'fullName': u['fullName'],
        'role': u['role'],
        'isActive': u['isActive'] ?? true,
        'createdAt': u['createdAt'],
        'lastLogin': null,
      });
    } on DioException {
      throw AuthException('نشست معتبر نیست');
    } catch (e) {
      throw AuthException('خطای نامشخص: ${e.toString()}');
    }
  }

  @override
  Future<void> logout() async {
    ApiClient.setToken(null);
  }

  @override
  Future<bool> isLoggedIn() async {
    return ApiClient.isLoggedIn;
  }
}
