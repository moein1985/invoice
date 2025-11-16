import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:invoice/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:invoice/features/auth/presentation/bloc/auth_event.dart';
import 'package:invoice/features/auth/presentation/bloc/auth_state.dart';
import 'package:invoice/features/auth/domain/usecases/login_usecase.dart';
import 'package:invoice/features/auth/domain/usecases/logout_usecase.dart';
import 'package:invoice/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:invoice/features/auth/domain/entities/user_entity.dart';
import 'package:dartz/dartz.dart';

class MockLoginUseCase extends Mock implements LoginUseCase {}
class MockLogoutUseCase extends Mock implements LogoutUseCase {}
class MockGetCurrentUseCase extends Mock implements GetCurrentUserUseCase {}

void main() {
  late MockLoginUseCase mockLogin;
  late MockLogoutUseCase mockLogout;
  late MockGetCurrentUseCase mockGetCurrent;
  late AuthBloc bloc;

  setUp(() {
    mockLogin = MockLoginUseCase();
    mockLogout = MockLogoutUseCase();
    mockGetCurrent = MockGetCurrentUseCase();
    bloc = AuthBloc(loginUseCase: mockLogin, logoutUseCase: mockLogout, getCurrentUserUseCase: mockGetCurrent);
  });

  test('emits [AuthLoading, Authenticated] when login succeeds', () async {
    final user = UserEntity(id: 'u1', username: 'a', password: '', fullName: 'A', role: 'user', isActive: true, createdAt: DateTime.now());
    when(() => mockLogin(username: any(named: 'username'), password: any(named: 'password'))).thenAnswer((_) async => Right(user));

    final expected = [const AuthLoading(), Authenticated(user)];

    expectLater(bloc.stream, emitsInOrder(expected));
    bloc.add(const LoginRequested(username: 'a', password: 'p'));
  });

  test('emits [AuthLoading, Unauthenticated] when logout succeeds', () async {
    when(() => mockLogout()).thenAnswer((_) async => const Right(null));

    final expected = [const AuthLoading(), const Unauthenticated()];
    expectLater(bloc.stream, emitsInOrder(expected));
    bloc.add(const LogoutRequested());
  });
}
