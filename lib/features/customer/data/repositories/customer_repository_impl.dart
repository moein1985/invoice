import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/customer_entity.dart';
import '../../domain/repositories/customer_repository.dart';
import '../datasources/customer_local_datasource.dart';
import '../models/customer_model.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  final CustomerLocalDataSource localDataSource;

  CustomerRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, List<CustomerEntity>>> getCustomers() async {
    try {
      final customers = await localDataSource.getCustomers();
      return Right(customers.map((model) => model.toEntity()).toList());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<CustomerEntity>>> searchCustomers(String query) async {
    try {
      final customers = await localDataSource.searchCustomers(query);
      return Right(customers.map((model) => model.toEntity()).toList());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, CustomerEntity>> getCustomerById(String id) async {
    try {
      final customer = await localDataSource.getCustomerById(id);
      return Right(customer.toEntity());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, CustomerEntity>> createCustomer(CustomerEntity customer) async {
    try {
      final customerModel = CustomerModel.fromEntity(customer);
      final savedCustomer = await localDataSource.saveCustomer(customerModel);
      return Right(savedCustomer.toEntity());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, CustomerEntity>> updateCustomer(CustomerEntity customer) async {
    try {
      final customerModel = CustomerModel.fromEntity(customer);
      final updatedCustomer = await localDataSource.updateCustomer(customerModel);
      return Right(updatedCustomer.toEntity());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCustomer(String id) async {
    try {
      await localDataSource.deleteCustomer(id);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, CustomerEntity>> toggleCustomerStatus(String id) async {
    try {
      final updatedCustomer = await localDataSource.toggleCustomerStatus(id);
      return Right(updatedCustomer.toEntity());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, CustomerEntity>> updateCustomerDebt(String id, double newDebt) async {
    try {
      final updatedCustomer = await localDataSource.updateCustomerDebt(id, newDebt);
      return Right(updatedCustomer.toEntity());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }
}
