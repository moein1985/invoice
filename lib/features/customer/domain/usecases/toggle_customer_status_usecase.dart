import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/customer_entity.dart';
import '../repositories/customer_repository.dart';

class ToggleCustomerStatusUseCase {
  final CustomerRepository repository;

  ToggleCustomerStatusUseCase(this.repository);

  Future<Either<Failure, CustomerEntity>> call(String customerId) async {
    return await repository.toggleCustomerStatus(customerId);
  }
}