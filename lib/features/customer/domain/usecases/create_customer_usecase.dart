import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/customer_entity.dart';
import '../repositories/customer_repository.dart';

class CreateCustomerUseCase {
  final CustomerRepository repository;

  CreateCustomerUseCase(this.repository);

  Future<Either<Failure, CustomerEntity>> call({
    required String name,
    required String phone,
    String? email,
    String? address,
    String? company,
    String? nationalId,
    double? creditLimit,
    double? currentDebt,
  }) async {
    final customer = CustomerEntity(
      id: DateTime.now().toString(),
      name: name,
      phone: phone,
      email: email,
      address: address,
      company: company,
      nationalId: nationalId,
      creditLimit: creditLimit ?? 0.0,
      currentDebt: currentDebt ?? 0.0,
      isActive: true,
      createdAt: DateTime.now(),
    );

    return await repository.createCustomer(customer);
  }
}