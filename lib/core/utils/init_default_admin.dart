import 'package:hive/hive.dart';
import '../constants/hive_boxes.dart';
import '../../features/auth/data/models/user_model.dart';
import '../constants/user_roles.dart';
import 'package:flutter/foundation.dart';

/// مقداردهی اولیه ادمین پیش‌فرض
Future<void> initDefaultAdmin() async {
  final usersBox = await Hive.openBox<UserModel>(HiveBoxes.users);

  // بررسی اینکه آیا هیچ کاربری وجود ندارد
  if (usersBox.isEmpty) {
    // ایجاد ادمین پیش‌فرض
    final defaultAdmin = UserModel(
      id: '1',
      username: 'admin',
      password: 'admin123', // در پروژه واقعی باید hash شود
      fullName: 'مدیر سیستم',
      role: UserRoles.admin,
      isActive: true,
      createdAt: DateTime.now(),
    );

    await usersBox.put(defaultAdmin.id, defaultAdmin);
    debugPrint('✅ ادمین پیش‌فرض ایجاد شد - نام کاربری: admin - رمز عبور: admin123');
  }
}
