import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invoice/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:invoice/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:invoice/features/dashboard/domain/usecases/get_dashboard_data_usecase.dart';
import 'package:invoice/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:invoice/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:invoice/core/error/failures.dart';
import 'package:invoice/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:invoice/features/auth/domain/usecases/login_usecase.dart';
import 'package:invoice/features/auth/domain/usecases/logout_usecase.dart';
import 'package:invoice/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:invoice/features/auth/domain/repositories/auth_repository.dart';
import 'package:invoice/features/auth/domain/entities/user_entity.dart';

class _FakeDashboardRepo implements DashboardRepository {
  @override
  Future<Either<Failure, DashboardEntity>> getDashboardData(String userId) async {
    return Right(DashboardEntity(
      totalInvoices: 0,
      totalRevenue: 0,
      totalCustomers: 0,
      pendingInvoices: 0,
      monthlyRevenue: 0,
      monthlyData: const [],
      recentInvoices: const [],
    ));
  }
}

DashboardBloc _buildDashboardBloc() {
  final repo = _FakeDashboardRepo();
  final usecase = GetDashboardDataUseCase(repo);
  return DashboardBloc(getDashboardDataUseCase: usecase);
}

AuthBloc _buildAuthBloc() {
  final repo = _FakeAuthRepo();
  final login = LoginUseCase(repo);
  final logout = LogoutUseCase(repo);
  final getCurrent = GetCurrentUserUseCase(repo);
  return AuthBloc(loginUseCase: login, logoutUseCase: logout, getCurrentUserUseCase: getCurrent);
}

class _FakeAuthRepo implements AuthRepository {
  @override
  Future<Either<Failure, UserEntity>> login({required String username, required String password}) async {
    return Right(UserEntity(id: 'u1', username: username, password: '', fullName: 'User', role: 'user', isActive: true, createdAt: DateTime.now()));
  }

  @override
  Future<Either<Failure, void>> logout() async => const Right(null);

  @override
  Future<Either<Failure, UserEntity?>> getCurrentUser() async => const Right(null);

  @override
  Future<bool> isLoggedIn() async => false;
}

void main() {
  testWidgets('DashboardPage builds and shows title', (tester) async {
    final bloc = _buildDashboardBloc();

    final authBloc = _buildAuthBloc();

    await tester.pumpWidget(
      MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: authBloc),
            BlocProvider.value(value: bloc),
          ],
          child: const DashboardPage(),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('داشبورد'), findsOneWidget);
  });
}
