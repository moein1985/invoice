import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invoice/features/auth/presentation/pages/login_page.dart';
// auth_event/state imports not required here
import 'package:invoice/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:invoice/features/auth/domain/usecases/login_usecase.dart';
import 'package:invoice/features/auth/domain/usecases/logout_usecase.dart';
import 'package:invoice/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:invoice/features/auth/domain/repositories/auth_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:invoice/features/auth/domain/entities/user_entity.dart';
import 'package:invoice/core/error/failures.dart';
import 'package:invoice/core/enums/user_role.dart';

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<Either<Failure, UserEntity>> login({required String username, required String password}) async {
    return Right(UserEntity(id: 'u1', username: username, password: '', fullName: 'User', role: UserRole.employee, isActive: true, createdAt: DateTime.now()));
  }

  @override
  Future<Either<Failure, void>> logout() async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, UserEntity?>> getCurrentUser() async {
    return const Right(null);
  }

  @override
  Future<bool> isLoggedIn() async => false;
}

// Build a real AuthBloc using fake repository so widget can read it.
AuthBloc _buildAuthBloc() {
  final repo = _FakeAuthRepository();
  final login = LoginUseCase(repo);
  final logout = LogoutUseCase(repo);
  final getCurrent = GetCurrentUserUseCase(repo);
  return AuthBloc(loginUseCase: login, logoutUseCase: logout, getCurrentUserUseCase: getCurrent);
}

void main() {
  testWidgets('LoginPage shows username, password and login button', (tester) async {
    final fakeAuth = _buildAuthBloc();

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<AuthBloc>.value(
          value: fakeAuth,
          child: const LoginPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('نام کاربری'), findsOneWidget);
    expect(find.text('رمز عبور'), findsOneWidget);
    expect(find.text('ورود'), findsOneWidget);
  });
}
