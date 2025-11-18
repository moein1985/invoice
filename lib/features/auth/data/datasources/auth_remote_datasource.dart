import 'package:dio/dio.dart';
import 'package:hive/hive.dart';

import '../../../../core/constants/hive_boxes.dart';
import '../../../../core/error/exceptions.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login({required String username, required String password});
  Future<UserModel> me();
  Future<void> logout();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio dio;

  AuthRemoteDataSourceImpl({required this.dio});

  @override
  Future<UserModel> login({required String username, required String password}) async {
    try {
      final response = await dio.post('/api/auth/login', data: {
        'username': username,
        'password': password,
      });

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

      final authBox = Hive.box(HiveBoxes.auth);
      await authBox.put('token', token);
      await authBox.put('currentUserId', user.id);
      await authBox.put('isLoggedIn', true);

      return user;
    } on DioException catch (e) {
      final message = e.response?.data is Map && (e.response?.data['error'] != null)
          ? e.response?.data['error']
          : 'خطا در ارتباط با سرور';
      throw AuthException(message.toString());
    } catch (e) {
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
    final authBox = Hive.box(HiveBoxes.auth);
    await authBox.delete('token');
    await authBox.put('isLoggedIn', false);
    await authBox.delete('currentUserId');
  }
}
