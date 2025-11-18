import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:invoice/core/error/exceptions.dart';
import 'package:invoice/core/error/failures.dart';
import 'package:invoice/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:invoice/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:invoice/features/auth/data/models/user_model.dart';
import 'package:invoice/features/auth/data/repositories/auth_repository_impl.dart';

class MockAuthLocal extends Mock implements AuthLocalDataSource {}
class MockAuthRemote extends Mock implements AuthRemoteDataSource {}

void main() {
  late MockAuthLocal mockLocal;
  late MockAuthRemote mockRemote;
  late AuthRepositoryImpl repository;

  setUp(() {
    mockLocal = MockAuthLocal();
    mockRemote = MockAuthRemote();
    repository = AuthRepositoryImpl(localDataSource: mockLocal, remoteDataSource: mockRemote);
  });

  test('login returns Right on success', () async {
    final user = UserModel(id: 'u1', username: 'a', password: 'p', fullName: 'A', role: 'employee', isActive: true, createdAt: DateTime.now());
    when(() => mockLocal.login(username: 'a', password: 'p')).thenAnswer((_) async => user);

    final res = await repository.login(username: 'a', password: 'p');
    expect(res.isRight(), isTrue);
  });

  test('login returns Left(AuthFailure) on AuthException', () async {
    when(() => mockLocal.login(username: 'x', password: 'y')).thenThrow(AuthException('bad'));
    final res = await repository.login(username: 'x', password: 'y');
    expect(res.isLeft(), isTrue);
    res.fold((l) => expect(l, isA<AuthFailure>()), (r) => fail('expected left'));
  });

  test('logout returns Right on success', () async {
    when(() => mockRemote.logout()).thenAnswer((_) async => Future.value());
    final res = await repository.logout();
    expect(res.isRight(), isTrue);
  });

  test('getCurrentUser returns Right(user?)', () async {
    final user = UserModel(id: 'u2', username: 'b', password: 'p', fullName: 'B', role: 'employee', isActive: true, createdAt: DateTime.now());
    when(() => mockRemote.me()).thenAnswer((_) async => user);
    final res = await repository.getCurrentUser();
    expect(res.isRight(), isTrue);
  });
}
