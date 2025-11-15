import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_entity.dart';

abstract class UserRepository {
  /// دریافت لیست همه کاربران
  Future<Either<Failure, List<UserEntity>>> getUsers();

  /// دریافت کاربر بر اساس ID
  Future<Either<Failure, UserEntity>> getUserById(String id);

  /// ایجاد کاربر جدید
  Future<Either<Failure, UserEntity>> createUser({
    required String username,
    required String password,
    required String fullName,
    required String role,
  });

  /// بروزرسانی کاربر
  Future<Either<Failure, UserEntity>> updateUser({
    required String id,
    String? username,
    String? password,
    String? fullName,
    String? role,
    bool? isActive,
  });

  /// حذف کاربر
  Future<Either<Failure, void>> deleteUser(String id);

  /// جستجوی کاربران
  Future<Either<Failure, List<UserEntity>>> searchUsers(String query);

  /// تغییر وضعیت فعال بودن کاربر
  Future<Either<Failure, UserEntity>> toggleUserStatus(String id);
}