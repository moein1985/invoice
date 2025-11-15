import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_entity.dart';
import '../repositories/user_repository.dart';

class ToggleUserStatusUseCase {
  final UserRepository repository;

  ToggleUserStatusUseCase(this.repository);

  Future<Either<Failure, UserEntity>> call(String id) async {
    return await repository.toggleUserStatus(id);
  }
}
