import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:invoice/core/error/exceptions.dart';
import 'package:invoice/core/error/failures.dart';
import 'package:invoice/features/auth/data/models/user_model.dart';
import 'package:invoice/features/user_management/data/datasources/user_local_datasource.dart';
import 'package:invoice/features/user_management/data/repositories/user_repository_impl.dart';

class MockUserLocalDataSource extends Mock implements UserLocalDataSource {}

void main() {
  late MockUserLocalDataSource mockLocal;
  late UserRepositoryImpl repository;

  setUp(() {
    mockLocal = MockUserLocalDataSource();
    repository = UserRepositoryImpl(localDataSource: mockLocal);
  });

  group('getUsers', () {
    test('returns Right(list) when local datasource succeeds', () async {
      final u = UserModel(
        id: '1',
        username: 'a',
        password: 'p',
        fullName: 'A',
        role: 'user',
        isActive: true,
        createdAt: DateTime.now(),
      );
      when(() => mockLocal.getUsers()).thenAnswer((_) async => [u]);

      final res = await repository.getUsers();
      expect(res.isRight(), isTrue);
      res.fold((l) => fail('expected right'), (r) => expect(r.length, equals(1)));
    });

    test('returns Left(CacheFailure) when datasource throws CacheException', () async {
      when(() => mockLocal.getUsers()).thenThrow(CacheException('err'));

      final res = await repository.getUsers();
      expect(res.isLeft(), isTrue);
      res.fold((l) => expect(l, isA<CacheFailure>()), (r) => fail('expected left'));
    });
  });

  group('createUser', () {
    test('returns Right(User) on success', () async {
      final u = UserModel(
        id: '2',
        username: 'bob',
        password: 'p',
        fullName: 'Bob',
        role: 'user',
        isActive: true,
        createdAt: DateTime.now(),
      );
      when(() => mockLocal.createUser(username: any(named: 'username'), password: any(named: 'password'), fullName: any(named: 'fullName'), role: any(named: 'role')))
          .thenAnswer((_) async => u);

      final res = await repository.createUser(username: 'bob', password: 'p', fullName: 'Bob', role: 'user');
      expect(res.isRight(), isTrue);
      res.fold((l) => fail('expected right'), (r) => expect(r.username, equals('bob')));
    });
  });
}
