import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:invoice/core/constants/hive_boxes.dart';
import 'package:invoice/core/error/exceptions.dart';
import 'package:invoice/features/auth/data/models/user_model.dart';
import 'package:invoice/features/user_management/data/datasources/user_local_datasource.dart';

void main() {
  group('UserLocalDataSourceImpl', () {
    late Directory tempDir;
    late UserLocalDataSourceImpl ds;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('hive_user_test_');
      Hive.init(tempDir.path);
      if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(UserModelAdapter());
      ds = UserLocalDataSourceImpl();
    });

    tearDown(() async {
      if (Hive.isBoxOpen(HiveBoxes.users)) {
        final box = Hive.box<UserModel>(HiveBoxes.users);
        await box.clear();
        await box.close();
      }
      await tempDir.delete(recursive: true);
    });

    test('createUser and getUsers', () async {
      final created = await ds.createUser(
        username: 'bob',
        password: 'pass',
        fullName: 'Bob',
        role: 'user',
      );

      final users = await ds.getUsers();
      expect(users.length, equals(1));
      expect(users.first.username, equals('bob'));
      expect(created.username, equals('bob'));
    });

    test('createUser duplicates username throws', () async {
      await ds.createUser(username: 'bob', password: 'p', fullName: 'Bob', role: 'user');
      expect(
          () => ds.createUser(username: 'bob', password: 'x', fullName: 'B2', role: 'user'),
          throwsA(isA<CacheException>()));
    });

    test('getUserById returns and updateUser works', () async {
      final u = await ds.createUser(username: 'a', password: '1', fullName: 'A', role: 'user');
      final fetched = await ds.getUserById(u.id);
      expect(fetched.username, equals('a'));

      final updated = await ds.updateUser(id: u.id, username: 'aa');
      expect(updated.username, equals('aa'));
    });

    test('updateUser duplicate username throws', () async {
      await ds.createUser(username: 'u1', password: '1', fullName: 'U1', role: 'user');
      final u2 = await ds.createUser(username: 'u2', password: '2', fullName: 'U2', role: 'user');
      expect(() => ds.updateUser(id: u2.id, username: 'u1'), throwsA(isA<CacheException>()));
    });

    test('searchUsers and toggle and delete', () async {
      final a = await ds.createUser(username: 'alice', password: 'p', fullName: 'Alice', role: 'user');
      final b = await ds.createUser(username: 'bob', password: 'p', fullName: 'Bob Smith', role: 'user');

      final all = await ds.searchUsers('');
      expect(all.length, equals(2));

      final res = await ds.searchUsers('smith');
      expect(res.length, equals(1));
      expect(res.first.username, equals('bob'));

      final toggled = await ds.toggleUserStatus(a.id);
      expect(toggled.isActive, isFalse);

      await ds.deleteUser(b.id);
      final left = await ds.getUsers();
      expect(left.length, equals(1));
    });
  });
}
