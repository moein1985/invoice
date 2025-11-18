import 'package:flutter_test/flutter_test.dart';
import 'package:invoice/features/auth/data/models/user_model.dart';

void main() {
  group('UserModel', () {
    test('toJson and fromJson round-trip', () {
      final now = DateTime.parse('2023-11-07T12:00:00Z');
      final model = UserModel(
        id: 'u1',
        username: 'bob',
        password: 'pass',
        fullName: 'Bob',
        role: 'employee',
        isActive: true,
        createdAt: now,
      );

      final json = model.toJson();
      final restored = UserModel.fromJson(json);
      expect(restored.id, equals(model.id));
      expect(restored.username, equals(model.username));
      expect(restored.createdAt.toUtc(), equals(model.createdAt.toUtc()));
    });

    test('copyWith changes fields', () {
      final now = DateTime.now();
      final model = UserModel(
        id: 'u1',
        username: 'bob',
        password: 'pass',
        fullName: 'Bob',
        role: 'employee',
        isActive: true,
        createdAt: now,
      );

      final changed = model.copyWith(username: 'alice', isActive: false);
      expect(changed.username, equals('alice'));
      expect(changed.isActive, isFalse);
      expect(changed.id, equals(model.id));
    });
  });
}
