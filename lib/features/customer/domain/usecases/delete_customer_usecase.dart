import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/customer_repository.dart';

class DeleteCustomerUseCase {
  final CustomerRepository repository;

  DeleteCustomerUseCase(this.repository);

  Future<Either<Failure, void>> call(String customerId) async {
    return await repository.deleteCustomer(customerId);
  }
}