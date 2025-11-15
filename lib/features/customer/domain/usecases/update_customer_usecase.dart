import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/customer_entity.dart';
import '../repositories/customer_repository.dart';

class UpdateCustomerUseCase {
  final CustomerRepository repository;

  UpdateCustomerUseCase(this.repository);

  Future<Either<Failure, CustomerEntity>> call({
    required String id,
    String? name,
    String? phone,
    String? email,
    String? address,
    String? company,
    String? nationalId,
    double? creditLimit,
    double? currentDebt,
    bool? isActive,
  }) async {
    // ابتدا مشتری فعلی را دریافت می‌کنیم
    final currentResult = await repository.getCustomerById(id);
    if (currentResult.isLeft()) {
      return currentResult;
    }

    final currentCustomer = currentResult.getOrElse(() => throw Exception('Customer not found'));

    final updatedCustomer = CustomerEntity(
      id: currentCustomer.id,
      name: name ?? currentCustomer.name,
      phone: phone ?? currentCustomer.phone,
      email: email ?? currentCustomer.email,
      address: address ?? currentCustomer.address,
      company: company ?? currentCustomer.company,
      nationalId: nationalId ?? currentCustomer.nationalId,
      creditLimit: creditLimit ?? currentCustomer.creditLimit,
      currentDebt: currentDebt ?? currentCustomer.currentDebt,
      isActive: isActive ?? currentCustomer.isActive,
      createdAt: currentCustomer.createdAt,
      lastTransaction: currentCustomer.lastTransaction,
    );

    return await repository.updateCustomer(updatedCustomer);
  }
}