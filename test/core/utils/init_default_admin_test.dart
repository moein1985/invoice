import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:invoice/core/utils/init_default_admin.dart';
import 'package:invoice/features/auth/data/models/user_model.dart';
import 'package:invoice/core/constants/hive_boxes.dart';

void main() {
  group('initDefaultAdmin', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('hive_test_');
      Hive.init(tempDir.path);
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(UserModelAdapter());
      }
    });

    tearDown(() async {
      if (Hive.isBoxOpen(HiveBoxes.users)) {
        await Hive.box<UserModel>(HiveBoxes.users).clear();
        await Hive.box<UserModel>(HiveBoxes.users).close();
      }
      await tempDir.delete(recursive: true);
    });

    test('creates default admin when users box is empty', () async {
      // ensure no box
      if (Hive.isBoxOpen(HiveBoxes.users)) {
        await Hive.box<UserModel>(HiveBoxes.users).clear();
        await Hive.box<UserModel>(HiveBoxes.users).close();
      }

      await initDefaultAdmin();

      expect(Hive.isBoxOpen(HiveBoxes.users), isTrue);
      final box = Hive.box<UserModel>(HiveBoxes.users);
      expect(box.isNotEmpty, isTrue);
      final admin = box.get('1') as UserModel?;
      expect(admin, isNotNull);
      expect(admin!.username, equals('admin'));
      expect(admin.role, equals('admin'));
    });
  });
}
