import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_entity.dart';
import '../repositories/user_repository.dart';

class CreateUserUseCase {
  final UserRepository repository;

  CreateUserUseCase(this.repository);

  Future<Either<Failure, UserEntity>> call({
    required String username,
    required String password,
    required String fullName,
    required String role,
  }) async {
    return await repository.createUser(
      username: username,
      password: password,
      fullName: fullName,
      role: role,
    );
  }
}
