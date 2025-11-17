import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:invoice/features/user_management/presentation/bloc/user_bloc.dart';
import 'package:invoice/features/user_management/presentation/bloc/user_event.dart';
import 'package:invoice/features/user_management/presentation/bloc/user_state.dart';
import 'package:invoice/features/user_management/domain/usecases/get_users_usecase.dart';
import 'package:invoice/features/user_management/domain/usecases/create_user_usecase.dart';
import 'package:invoice/features/user_management/domain/usecases/update_user_usecase.dart';
import 'package:invoice/features/user_management/domain/usecases/delete_user_usecase.dart';
import 'package:invoice/features/user_management/domain/usecases/search_users_usecase.dart';
import 'package:invoice/features/user_management/domain/usecases/toggle_user_status_usecase.dart';
import 'package:invoice/features/auth/domain/entities/user_entity.dart';
import 'package:dartz/dartz.dart';
import 'package:invoice/core/enums/user_role.dart';

class MockGetUsers extends Mock implements GetUsersUseCase {}
class MockCreateUser extends Mock implements CreateUserUseCase {}
class MockUpdateUser extends Mock implements UpdateUserUseCase {}
class MockDeleteUser extends Mock implements DeleteUserUseCase {}
class MockSearchUsers extends Mock implements SearchUsersUseCase {}
class MockToggleUserStatus extends Mock implements ToggleUserStatusUseCase {}

void main() {
  late MockGetUsers mockGetUsers;
  late MockCreateUser mockCreateUser;
  late MockUpdateUser mockUpdateUser;
  late MockDeleteUser mockDeleteUser;
  late MockSearchUsers mockSearchUsers;
  late MockToggleUserStatus mockToggleUserStatus;
  late UserBloc bloc;

  setUp(() {
    mockGetUsers = MockGetUsers();
    mockCreateUser = MockCreateUser();
    mockUpdateUser = MockUpdateUser();
    mockDeleteUser = MockDeleteUser();
    mockSearchUsers = MockSearchUsers();
    mockToggleUserStatus = MockToggleUserStatus();
    bloc = UserBloc(
      getUsersUseCase: mockGetUsers,
      createUserUseCase: mockCreateUser,
      updateUserUseCase: mockUpdateUser,
      deleteUserUseCase: mockDeleteUser,
      searchUsersUseCase: mockSearchUsers,
      toggleUserStatusUseCase: mockToggleUserStatus,
    );
  });

  test('emits [UserLoading, UsersLoaded] when load users succeeds', () async {
    final users = [
      UserEntity(id: '1', username: 'u1', password: '', fullName: 'U1', role: UserRole.employee, isActive: true, createdAt: DateTime.now())
    ];
    when(() => mockGetUsers()).thenAnswer((_) async => Right(users));

    final expected = [const UserLoading(), UsersLoaded(users)];
    expectLater(bloc.stream, emitsInOrder(expected));

    bloc.add(const LoadUsers());
  });

  test('emits [UserLoading, UserOperationSuccess] when create user succeeds', () async {
    final user = UserEntity(id: '2', username: 'u2', password: '', fullName: 'U2', role: UserRole.employee, isActive: true, createdAt: DateTime.now());
    when(() => mockCreateUser(username: any(named: 'username'), password: any(named: 'password'), fullName: any(named: 'fullName'), role: any(named: 'role'))).thenAnswer((_) async => Right(user));

    final expected = [const UserLoading(), const UserOperationSuccess('کاربر با موفقیت ایجاد شد')];
    expectLater(bloc.stream, emitsInOrder(expected));

    bloc.add(const CreateUser(username: 'u2', password: 'p', fullName: 'U2', role: 'employee'));
  });
}
