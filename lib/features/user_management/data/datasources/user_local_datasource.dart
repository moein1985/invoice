import 'package:hive/hive.dart';
import '../../../../core/constants/hive_boxes.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/utils/logger.dart';
import '../../../auth/data/models/user_model.dart';

abstract class UserLocalDataSource {
  /// دریافت لیست همه کاربران
  Future<List<UserModel>> getUsers();

  /// دریافت کاربر بر اساس ID
  Future<UserModel> getUserById(String id);

  /// ایجاد کاربر جدید
  Future<UserModel> createUser({
    required String username,
    required String password,
    required String fullName,
    required String role,
  });

  /// بروزرسانی کاربر
  Future<UserModel> updateUser({
    required String id,
    String? username,
    String? password,
    String? fullName,
    String? role,
    bool? isActive,
  });

  /// حذف کاربر
  Future<void> deleteUser(String id);

  /// جستجوی کاربران
  Future<List<UserModel>> searchUsers(String query);

  /// تغییر وضعیت فعال بودن کاربر
  Future<UserModel> toggleUserStatus(String id);
}

class UserLocalDataSourceImpl implements UserLocalDataSource {
  static const _logTag = 'UserLocalDataSource';

  Future<Box<UserModel>> _getUsersBox() async {
    if (Hive.isBoxOpen(HiveBoxes.users)) {
      AppLogger.debug('Reusing already opened users box', _logTag);
      return Hive.box<UserModel>(HiveBoxes.users);
    }

    try {
      AppLogger.info('Opening users box for the first time', _logTag);
      return await Hive.openBox<UserModel>(HiveBoxes.users);
    } on HiveError catch (e) {
      // در سناریوهایی مثل hot-restart ممکن است باکس باز باشد اما isBoxOpen هنوز false برگرداند
      if (e.message.contains('already open')) {
        AppLogger.warning('users_box reported as already open; reusing existing instance', _logTag);
        return Hive.box<UserModel>(HiveBoxes.users);
      }
      rethrow;
    }
  }

  @override
  Future<List<UserModel>> getUsers() async {
    try {
      final usersBox = await _getUsersBox();
      return usersBox.values.toList();
    } catch (e) {
      throw CacheException('خطا در دریافت لیست کاربران: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> getUserById(String id) async {
    try {
      final usersBox = await _getUsersBox();
      final user = usersBox.get(id);

      if (user == null) {
        throw CacheException('کاربر یافت نشد');
      }

      return user;
    } catch (e) {
      if (e is CacheException) rethrow;
      throw CacheException('خطا در دریافت کاربر: ${e.toString()}');
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
      final usersBox = await _getUsersBox();

      // بررسی وجود نام کاربری تکراری
      final existingUsers = usersBox.values.where((user) => user.username == username);
      if (existingUsers.isNotEmpty) {
        throw CacheException('نام کاربری تکراری است');
      }

      final newUser = UserModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        username: username,
        password: password, // در پروژه واقعی باید hash شود
        fullName: fullName,
        role: role,
        isActive: true,
        createdAt: DateTime.now(),
      );

      await usersBox.put(newUser.id, newUser);
      return newUser;
    } catch (e) {
      if (e is CacheException) rethrow;
      throw CacheException('خطا در ایجاد کاربر: ${e.toString()}');
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
      final usersBox = await _getUsersBox();
      final existingUser = usersBox.get(id);

      if (existingUser == null) {
        throw CacheException('کاربر یافت نشد');
      }

      // بررسی وجود نام کاربری تکراری در صورت تغییر نام کاربری
      if (username != null && username != existingUser.username) {
        final existingUsers = usersBox.values.where((user) =>
            user.username == username && user.id != id);
        if (existingUsers.isNotEmpty) {
          throw CacheException('نام کاربری تکراری است');
        }
      }

      final updatedUser = existingUser.copyWith(
        username: username,
        password: password,
        fullName: fullName,
        role: role,
        isActive: isActive,
      );

      await usersBox.put(id, updatedUser);
      return updatedUser;
    } catch (e) {
      if (e is CacheException) rethrow;
      throw CacheException('خطا در بروزرسانی کاربر: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteUser(String id) async {
    try {
      final usersBox = await _getUsersBox();
      await usersBox.delete(id);
    } catch (e) {
      throw CacheException('خطا در حذف کاربر: ${e.toString()}');
    }
  }

  @override
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      final usersBox = await _getUsersBox();
      final allUsers = usersBox.values.toList();

      if (query.isEmpty) {
        return allUsers;
      }

      return allUsers.where((user) =>
          user.username.toLowerCase().contains(query.toLowerCase()) ||
          user.fullName.toLowerCase().contains(query.toLowerCase())).toList();
    } catch (e) {
      throw CacheException('خطا در جستجوی کاربران: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> toggleUserStatus(String id) async {
    try {
      final usersBox = await _getUsersBox();
      final user = usersBox.get(id);

      if (user == null) {
        throw CacheException('کاربر یافت نشد');
      }

      final updatedUser = user.copyWith(isActive: !user.isActive);
      await usersBox.put(id, updatedUser);

      return updatedUser;
    } catch (e) {
      if (e is CacheException) rethrow;
      throw CacheException('خطا در تغییر وضعیت کاربر: ${e.toString()}');
    }
  }
}
