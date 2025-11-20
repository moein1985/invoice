import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/customer_entity.dart';
import '../../domain/repositories/customer_repository.dart';
import '../datasources/customer_remote_datasource.dart';
import '../models/customer_model.dart';

class CustomerRepositoryImpl implements CustomerRepository {  final CustomerRemoteDataSource remoteDataSource;

  CustomerRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<CustomerEntity>>> getCustomers() async {
    try {
      try {
        final customers = await remoteDataSource.getCustomers();
        return Right(customers.map((model) => model.toEntity()).toList());
      } catch (_) {
        final customers = await remoteDataSource.getCustomers();
        return Right(customers.map((model) => model.toEntity()).toList());
      }
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<CustomerEntity>>> searchCustomers(String query) async {
    try {
      // Backend جستجوی مستقیم ندارد؛ از لیست و فیلتر
      try {
        final customers = await remoteDataSource.getCustomers();
        final q = query.toLowerCase();
        final filtered = customers.where((c) =>
          c.name.toLowerCase().contains(q) || (c.phone?.contains(query) ?? false) ||
          (c.address?.toLowerCase().contains(q) ?? false)
        ).toList();
        return Right(filtered.map((e) => e.toEntity()).toList());
      } catch (_) {
        // TODO: Implement searchCustomers in backend API
        return const Right([]);
      }
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, CustomerEntity>> getCustomerById(String id) async {
    try {
      try {
        final customer = await remoteDataSource.getCustomerById(id);
        return Right(customer.toEntity());
      } catch (_) {
        final customer = await remoteDataSource.getCustomerById(id);
        return Right(customer.toEntity());
      }
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, CustomerEntity>> createCustomer(CustomerEntity customer) async {
    try {
      final m = CustomerModel.fromEntity(customer);
      final saved = await remoteDataSource.createCustomer(m);
      return Right(saved.toEntity());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, CustomerEntity>> updateCustomer(CustomerEntity customer) async {
    try {
      final m = CustomerModel.fromEntity(customer);
      try {
        final updated = await remoteDataSource.updateCustomer(m);
        return Right(updated.toEntity());
      } catch (_) {
        final updatedCustomer = await remoteDataSource.updateCustomer(m);
        return Right(updatedCustomer.toEntity());
      }
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCustomer(String id) async {
    try {
      try {
        await remoteDataSource.deleteCustomer(id);
      } catch (_) {
        await remoteDataSource.deleteCustomer(id);
      }
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, CustomerEntity>> toggleCustomerStatus(String id) async {
    try {
      // از سرور با update isActive معکوس پیاده‌سازی می‌کنیم
      try {
        final current = await remoteDataSource.getCustomerById(id);
        final toggled = current.copyWith(
          isActive: !(current.isActive ?? true),
        );
        final updated = await remoteDataSource.updateCustomer(toggled);
        return Right(updated.toEntity());
      } catch (_) {
        return Left(CacheFailure('Toggle status not implemented'));
      }
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, CustomerEntity>> updateCustomerDebt(String id, double newDebt) async {
    // TODO: Implement debt management in backend
    return Left(CacheFailure('Update debt not implemented'));
  }
}
