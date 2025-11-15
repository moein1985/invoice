import 'package:hive/hive.dart';
import '../../../../core/constants/hive_boxes.dart';
import '../../../../core/error/exceptions.dart';
import '../models/user_model.dart';

abstract class AuthLocalDataSource {
  /// ورود کاربر
  Future<UserModel> login({
    required String username,
    required String password,
  });

  /// خروج کاربر
  Future<void> logout();

  /// دریافت کاربر فعلی
  Future<UserModel?> getCurrentUser();

  /// بررسی اینکه کاربر وارد شده یا نه
  Future<bool> isLoggedIn();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  @override
  Future<UserModel> login({
    required String username,
    required String password,
  }) async {
    try {
      final usersBox = await Hive.openBox<UserModel>(HiveBoxes.users);
      
      // جستجوی کاربر
      UserModel? foundUser;
      for (var user in usersBox.values) {
        if (user.username == username && user.password == password) {
          foundUser = user;
          break;
        }
      }

      if (foundUser == null) {
        throw AuthException('نام کاربری یا رمز عبور اشتباه است');
      }

      if (!foundUser.isActive) {
        throw AuthException('این کاربر غیرفعال شده است');
      }

      // به‌روزرسانی زمان آخرین ورود
      final updatedUser = foundUser.copyWith(lastLogin: DateTime.now());
      await usersBox.put(updatedUser.id, updatedUser);

      // ذخیره وضعیت ورود
      final authBox = await Hive.openBox(HiveBoxes.auth);
      await authBox.put('currentUserId', updatedUser.id);
      await authBox.put('isLoggedIn', true);

      return updatedUser;
    } catch (e) {
      if (e is AuthException) rethrow;
      throw CacheException('خطا در ورود به سیستم: ${e.toString()}');
    }
  }

  @override
  Future<void> logout() async {
    try {
      final authBox = await Hive.openBox(HiveBoxes.auth);
      await authBox.delete('currentUserId');
      await authBox.put('isLoggedIn', false);
    } catch (e) {
      throw CacheException('خطا در خروج از سیستم: ${e.toString()}');
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final authBox = await Hive.openBox(HiveBoxes.auth);
      final currentUserId = authBox.get('currentUserId');

      if (currentUserId == null) {
        return null;
      }

      final usersBox = await Hive.openBox<UserModel>(HiveBoxes.users);
      return usersBox.get(currentUserId);
    } catch (e) {
      throw CacheException('خطا در دریافت کاربر فعلی: ${e.toString()}');
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    try {
      final authBox = await Hive.openBox(HiveBoxes.auth);
      return authBox.get('isLoggedIn', defaultValue: false);
    } catch (e) {
      return false;
    }
  }
}
