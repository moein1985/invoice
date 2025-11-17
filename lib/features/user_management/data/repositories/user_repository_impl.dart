import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/user_local_datasource.dart';

class UserRepositoryImpl implements UserRepository {
  final UserLocalDataSource localDataSource;

  UserRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, List<UserEntity>>> getUsers() async {
    try {
      final users = await localDataSource.getUsers();
      return Right(users.map((user) => user.toEntity()).toList());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('خطای نامشخص: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> getUserById(String id) async {
    try {
      final user = await localDataSource.getUserById(id);
      return Right(user.toEntity());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('خطای نامشخص: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> createUser({
    required String username,
    required String password,
    required String fullName,
    required String role,
  }) async {
    try {
      final user = await localDataSource.createUser(
        username: username,
        password: password,
        fullName: fullName,
        role: role,
      );
      return Right(user.toEntity());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('خطای نامشخص: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> updateUser({
    required String id,
    String? username,
    String? password,
    String? fullName,
    String? role,
    bool? isActive,
  }) async {
    try {
      final user = await localDataSource.updateUser(
        id: id,
        username: username,
        password: password,
        fullName: fullName,
        role: role,
        isActive: isActive,
      );
      return Right(user.toEntity());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('خطای نامشخص: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteUser(String id) async {
    try {
      await localDataSource.deleteUser(id);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('خطای نامشخص: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<UserEntity>>> searchUsers(String query) async {
    try {
      final users = await localDataSource.searchUsers(query);
      return Right(users.map((user) => user.toEntity()).toList());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('خطای نامشخص: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> toggleUserStatus(String id) async {
    try {
      final user = await localDataSource.toggleUserStatus(id);
      return Right(user.toEntity());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('خطای نامشخص: ${e.toString()}'));
    }
  }
}
