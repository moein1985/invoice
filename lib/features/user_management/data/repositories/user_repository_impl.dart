import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/user_remote_datasource.dart';

class UserRepositoryImpl implements UserRepository {  final UserRemoteDataSource remoteDataSource;

  UserRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<UserEntity>>> getUsers() async {
    try {
      try {
        final users = await remoteDataSource.getUsers();
        return Right(users.map((user) => user.toEntity()).toList());
      } catch (_) {
        final users = await remoteDataSource.getUsers();
        return Right(users.map((user) => user.toEntity()).toList());
      }
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('خطای نامشخص: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> getUserById(String id) async {
    try {
      try {
        final user = await remoteDataSource.getUserById(id);
        return Right(user.toEntity());
      } catch (_) {
        final user = await remoteDataSource.getUserById(id);
        return Right(user.toEntity());
      }
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
      try {
        final user = await remoteDataSource.createUser(
        username: username,
        password: password,
        fullName: fullName,
        role: role,
        );
        return Right(user.toEntity());
      } catch (_) {
        final user = await remoteDataSource.createUser(
          username: username,
          password: password,
          fullName: fullName,
          role: role,
        );
        return Right(user.toEntity());
      }
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
      try {
        final user = await remoteDataSource.updateUser(
        id: id,
        username: username,
        password: password,
        fullName: fullName,
        role: role,
        isActive: isActive,
        );
        return Right(user.toEntity());
      } catch (_) {
        final user = await remoteDataSource.updateUser(
          id: id,
          username: username,
          password: password,
          fullName: fullName,
          role: role,
          isActive: isActive,
        );
        return Right(user.toEntity());
      }
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('خطای نامشخص: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteUser(String id) async {
    try {
      try {
        await remoteDataSource.deleteUser(id);
      } catch (_) {
        await remoteDataSource.deleteUser(id);
      }
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
      // Backend ندارد جستجو؛ از getUsers و فیلتر کلاینتی
      try {
        final users = await remoteDataSource.getUsers();
        final filtered = users.where((u) =>
          u.username.toLowerCase().contains(query.toLowerCase()) ||
          u.fullName.toLowerCase().contains(query.toLowerCase())
        ).toList();
        return Right(filtered.map((e) => e.toEntity()).toList());
      } catch (_) {
        // TODO: Implement search in backend
        return const Right([]);
      }
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('خطای نامشخص: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> toggleUserStatus(String id) async {
    try {
      // روی سرور endpoint خاص ندارد؛ با updateUser isActive را برعکس می‌کنیم
      try {
        final current = await remoteDataSource.getUserById(id);
        final updated = await remoteDataSource.updateUser(id: id, isActive: !current.isActive);
        return Right(updated.toEntity());
      } catch (_) {
        return Left(CacheFailure('Toggle status failed'));
      }
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('خطای نامشخص: ${e.toString()}'));
    }
  }
}
