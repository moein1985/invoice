import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:invoice/core/error/failures.dart';
import 'package:invoice/features/auth/domain/entities/user_entity.dart';
import 'package:invoice/features/auth/domain/repositories/auth_repository.dart';
import 'package:invoice/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:invoice/features/auth/domain/usecases/login_usecase.dart';
import 'package:invoice/features/auth/domain/usecases/logout_usecase.dart';

class MockAuthRepo extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepo mockRepo;
  late LoginUseCase loginUseCase;
  late LogoutUseCase logoutUseCase;
  late GetCurrentUserUseCase getCurrentUseCase;

  setUp(() {
    mockRepo = MockAuthRepo();
    loginUseCase = LoginUseCase(mockRepo);
    logoutUseCase = LogoutUseCase(mockRepo);
    getCurrentUseCase = GetCurrentUserUseCase(mockRepo);
  });

  test('LoginUseCase returns user on success', () async {
    final user = UserEntity(id: 'u1', username: 'u', password: '', fullName: 'U', role: 'user', isActive: true, createdAt: DateTime.now());
    when(() => mockRepo.login(username: any(named: 'username'), password: any(named: 'password')))
        .thenAnswer((_) async => Right(user));

    final res = await loginUseCase(username: 'u', password: 'p');
    expect(res.isRight(), isTrue);
  });

  test('LoginUseCase returns AuthFailure on auth error', () async {
    when(() => mockRepo.login(username: any(named: 'username'), password: any(named: 'password')))
        .thenAnswer((_) async => Left(AuthFailure('bad')));

    final res = await loginUseCase(username: 'u', password: 'p');
    expect(res.isLeft(), isTrue);
  });

  test('LogoutUseCase delegates to repository', () async {
    when(() => mockRepo.logout()).thenAnswer((_) async => const Right(null));
    final res = await logoutUseCase();
    expect(res.isRight(), isTrue);
  });

  test('GetCurrentUserUseCase returns user or null', () async {
    final user = UserEntity(id: 'u2', username: 'c', password: '', fullName: 'C', role: 'user', isActive: true, createdAt: DateTime.now());
    when(() => mockRepo.getCurrentUser()).thenAnswer((_) async => Right(user));
    final res = await getCurrentUseCase();
    expect(res.isRight(), isTrue);
  });
}
