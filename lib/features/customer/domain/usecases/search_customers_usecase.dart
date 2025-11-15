import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/customer_entity.dart';
import '../repositories/customer_repository.dart';

class SearchCustomersUseCase {
  final CustomerRepository repository;

  SearchCustomersUseCase(this.repository);

  Future<Either<Failure, List<CustomerEntity>>> call(String query) async {
    if (query.isEmpty) {
      return await repository.getCustomers();
    }
    return await repository.searchCustomers(query);
  }
}