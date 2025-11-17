import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, UserEntity>> login({
    required String username,
    required String password,
  }) async {
    try {
      final user = await localDataSource.login(
        username: username,
        password: password,
      );
      return Right(user.toEntity());
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(AuthFailure('خطای نامشخص: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await localDataSource.logout();
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('خطای نامشخص: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, UserEntity?>> getCurrentUser() async {
    try {
      final user = await localDataSource.getCurrentUser();
      return Right(user?.toEntity());
    } on CacheException catch (e) {

      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('خطای نامشخص: ${e.toString()}'));
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    return await localDataSource.isLoggedIn();
  }
}

