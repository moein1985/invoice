import 'package:hive/hive.dart';

import '../../../../core/constants/hive_boxes.dart';
import '../../../../core/error/exceptions.dart';
import '../models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<UserModel> login({required String username, required String password});
  Future<void> logout();
  Future<UserModel?> getCurrentUser();
  Future<bool> isLoggedIn();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  @override
  Future<UserModel> login({required String username, required String password}) async {
    try {
      final usersBox = Hive.box<UserModel>(HiveBoxes.users);
      UserModel? foundUser;
      for (var user in usersBox.values) {
        if (user.username == username && user.password == password) {
          foundUser = user;
          break;
        }
      }
      if (foundUser == null) throw AuthException('??? ?????? ?? ??? ???? ?????? ???');
      if (!foundUser.isActive) throw AuthException('??? ????? ??????? ??? ???');
      final updatedUser = foundUser.copyWith(lastLogin: DateTime.now());
      await usersBox.put(updatedUser.id, updatedUser);
      final authBox = Hive.box(HiveBoxes.auth);
      await authBox.put('currentUserId', updatedUser.id);
      await authBox.put('isLoggedIn', true);
      return updatedUser;
    } catch (e) {
      if (e is AuthException) rethrow;
      throw CacheException('??? ?? ???? ?? ?????: ${e.toString()}');
    }
  }

  @override
  Future<void> logout() async {
    try {
      final authBox = Hive.box(HiveBoxes.auth);
      await authBox.delete('currentUserId');
      await authBox.put('isLoggedIn', false);
    } catch (e) {
      throw CacheException('??? ?? ???? ?? ?????: ${e.toString()}');
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final authBox = Hive.box(HiveBoxes.auth);
      final currentUserId = authBox.get('currentUserId');
      if (currentUserId == null) return null;
      final usersBox = Hive.box<UserModel>(HiveBoxes.users);
      return usersBox.get(currentUserId);
    } catch (e) {
      throw CacheException('??? ?? ?????? ????? ????: ${e.toString()}');
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    try {
      final authBox = Hive.box(HiveBoxes.auth);
      return authBox.get('isLoggedIn', defaultValue: false);
    } catch (e) {
      return false;
    }
  }
}

