import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:invoice/core/constants/hive_boxes.dart';
import 'package:invoice/core/error/exceptions.dart';
import 'package:invoice/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:invoice/features/auth/data/models/user_model.dart';
import 'package:invoice/core/enums/user_role.dart';

void main() {
  group('AuthLocalDataSourceImpl', () {
    late Directory tempDir;
    late AuthLocalDataSourceImpl ds;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('hive_auth_test_');
      Hive.init(tempDir.path);
      if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(UserModelAdapter());
      // ensure auth box exists
      await Hive.openBox(HiveBoxes.auth);
      ds = AuthLocalDataSourceImpl();
    });

    tearDown(() async {
      if (Hive.isBoxOpen(HiveBoxes.auth)) {
        await Hive.box(HiveBoxes.auth).clear();
        await Hive.box(HiveBoxes.auth).close();
      }
      if (Hive.isBoxOpen(HiveBoxes.users)) {
        await Hive.box<UserModel>(HiveBoxes.users).clear();
        await Hive.box<UserModel>(HiveBoxes.users).close();
      }
      await tempDir.delete(recursive: true);
    });

    test('login success and sets authBox', () async {
      // create user in users box
      final usersBox = await Hive.openBox<UserModel>(HiveBoxes.users);
      final user = UserModel(
        id: 'u1',
        username: 'test',
        password: 'pass',
        fullName: 'Test',
        role: 'employee',
        isActive: true,
        createdAt: DateTime.now(),
      );
      await usersBox.put(user.id, user);

      final logged = await ds.login(username: 'test', password: 'pass');
      expect(logged.username, equals('test'));
      final authBox = Hive.box(HiveBoxes.auth);
      expect(authBox.get('currentUserId'), equals(logged.id));
      expect(authBox.get('isLoggedIn'), equals(true));
    });

    test('login wrong credentials throws AuthException', () async {
      final usersBox = await Hive.openBox<UserModel>(HiveBoxes.users);
      final user = UserModel(
        id: 'u2',
        username: 'u',
        password: 'p',
        fullName: 'U',
        role: 'employee',
        isActive: true,
        createdAt: DateTime.now(),
      );
      await usersBox.put(user.id, user);

      expect(() => ds.login(username: 'u', password: 'wrong'), throwsA(isA<AuthException>()));
    });

    test('logout clears auth box', () async {
      final authBox = await Hive.openBox(HiveBoxes.auth);
      await authBox.put('currentUserId', 'x');
      await authBox.put('isLoggedIn', true);

      await ds.logout();
      expect(authBox.get('currentUserId'), isNull);
      expect(authBox.get('isLoggedIn'), equals(false));
    });

    test('getCurrentUser and isLoggedIn work', () async {
      final usersBox = await Hive.openBox<UserModel>(HiveBoxes.users);
      final authBox = await Hive.openBox(HiveBoxes.auth);
      final user = UserModel(
        id: 'u3',
        username: 'cur',
        password: 'p',
        fullName: 'Cur',
        role: 'employee',
        isActive: true,
        createdAt: DateTime.now(),
      );
      await usersBox.put(user.id, user);
      await authBox.put('currentUserId', user.id);
      await authBox.put('isLoggedIn', true);

      final current = await ds.getCurrentUser();
      expect(current?.id, equals(user.id));
      final loggedIn = await ds.isLoggedIn();
      expect(loggedIn, isTrue);
    });
  });
}
