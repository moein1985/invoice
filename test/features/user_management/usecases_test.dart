import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:invoice/core/error/failures.dart';
import 'package:invoice/features/user_management/domain/entities/user_entity.dart';
import 'package:invoice/features/user_management/domain/repositories/user_repository.dart';
import 'package:invoice/features/user_management/domain/usecases/create_user_usecase.dart';
import 'package:invoice/features/user_management/domain/usecases/delete_user_usecase.dart';
import 'package:invoice/features/user_management/domain/usecases/get_users_usecase.dart';
import 'package:invoice/features/user_management/domain/usecases/search_users_usecase.dart';
import 'package:invoice/features/user_management/domain/usecases/toggle_user_status_usecase.dart';
import 'package:invoice/features/user_management/domain/usecases/update_user_usecase.dart';

class MockUserRepository extends Mock implements UserRepository {}

// Use the concrete UserEntity for test instances

void main() {
  late MockUserRepository mockRepo;
  late GetUsersUseCase getUsers;
  late CreateUserUseCase createUser;
  late UpdateUserUseCase updateUser;
  late DeleteUserUseCase deleteUser;
  late SearchUsersUseCase searchUsers;
  late ToggleUserStatusUseCase toggleStatus;

  setUp(() {
    mockRepo = MockUserRepository();
    getUsers = GetUsersUseCase(mockRepo);
    createUser = CreateUserUseCase(mockRepo);
    updateUser = UpdateUserUseCase(mockRepo);
    deleteUser = DeleteUserUseCase(mockRepo);
    searchUsers = SearchUsersUseCase(mockRepo);
    toggleStatus = ToggleUserStatusUseCase(mockRepo);
  });

  test('GetUsersUseCase returns list on success', () async {
    final u = UserEntity(id: '1', username: 'a', password: '', fullName: 'A', role: 'user', isActive: true, createdAt: DateTime.now());
    when(() => mockRepo.getUsers()).thenAnswer((_) async => Right([u]));

    final res = await getUsers();
    expect(res.isRight(), isTrue);
    res.fold((l) => fail('expected right'), (r) => expect(r.length, equals(1)));
  });

  test('CreateUserUseCase returns user on success', () async {
    final u = UserEntity(id: '2', username: 'bob', password: '', fullName: 'Bob', role: 'user', isActive: true, createdAt: DateTime.now());
    when(() => mockRepo.createUser(username: any(named: 'username'), password: any(named: 'password'), fullName: any(named: 'fullName'), role: any(named: 'role')))
        .thenAnswer((_) async => Right(u));

    final res = await createUser(username: 'bob', password: 'p', fullName: 'Bob', role: 'user');
    expect(res.isRight(), isTrue);
  });

  test('UpdateUserUseCase returns failure on repo failure', () async {
    when(() => mockRepo.updateUser(id: any(named: 'id'))).thenAnswer((_) async => Left(CacheFailure('err')));

    final res = await updateUser(id: '1');
    expect(res.isLeft(), isTrue);
  });

  test('DeleteUserUseCase returns success', () async {
    when(() => mockRepo.deleteUser(any())).thenAnswer((_) async => const Right(null));
    final res = await deleteUser('1');
    expect(res.isRight(), isTrue);
  });

  test('SearchUsersUseCase delegates to repo', () async {
    when(() => mockRepo.searchUsers('q')).thenAnswer((_) async => Right(<UserEntity>[]));
    final res = await searchUsers('q');
    expect(res.isRight(), isTrue);
  });

  test('ToggleUserStatusUseCase returns user on success', () async {
    final u = UserEntity(id: '3', username: 'c', password: '', fullName: 'C', role: 'user', isActive: true, createdAt: DateTime.now());
    when(() => mockRepo.toggleUserStatus('3')).thenAnswer((_) async => Right(u));
    final res = await toggleStatus('3');
    expect(res.isRight(), isTrue);
  });
}
