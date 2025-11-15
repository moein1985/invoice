import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  /// ورود کاربر
  Future<Either<Failure, UserEntity>> login({
    required String username,
    required String password,
  });

  /// خروج کاربر
  Future<Either<Failure, void>> logout();

  /// دریافت کاربر فعلی
  Future<Either<Failure, UserEntity?>> getCurrentUser();

  /// بررسی اینکه کاربر وارد شده یا نه
  Future<bool> isLoggedIn();
}