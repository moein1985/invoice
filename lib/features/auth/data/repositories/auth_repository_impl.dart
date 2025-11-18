import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthLocalDataSource localDataSource;
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.localDataSource, required this.remoteDataSource});

  @override
  Future<Either<Failure, UserEntity>> login({
    required String username,
    required String password,
  }) async {
    try {
      // Prefer remote login; fallback to local if remote fails
      final user = await remoteDataSource.login(username: username, password: password);
      return Right(user.toEntity());
    } on AuthException catch (e) {
      // Fallback to local (offline) login
      try {
        final user = await localDataSource.login(username: username, password: password);
        return Right(user.toEntity());
      } on Exception {
        return Left(AuthFailure(e.message));
      }
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      // Fallback to local on unknown/connection errors
      try {
        final user = await localDataSource.login(username: username, password: password);
        return Right(user.toEntity());
      } catch (_) {
        return Left(AuthFailure('خطای نامشخص: ${e.toString()}'));
      }
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await remoteDataSource.logout();
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
      // Validate token and get user from backend
      final user = await remoteDataSource.me();
      return Right(user.toEntity());
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

