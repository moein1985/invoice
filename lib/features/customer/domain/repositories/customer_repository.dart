import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/customer_entity.dart';

abstract class CustomerRepository {
  /// دریافت لیست همه مشتریان
  Future<Either<Failure, List<CustomerEntity>>> getCustomers();

  /// جستجوی مشتریان بر اساس نام یا شماره تلفن
  Future<Either<Failure, List<CustomerEntity>>> searchCustomers(String query);

  /// دریافت مشتری بر اساس ID
  Future<Either<Failure, CustomerEntity>> getCustomerById(String id);

  /// ایجاد مشتری جدید
  Future<Either<Failure, CustomerEntity>> createCustomer(CustomerEntity customer);

  /// بروزرسانی مشتری موجود
  Future<Either<Failure, CustomerEntity>> updateCustomer(CustomerEntity customer);

  /// حذف مشتری
  Future<Either<Failure, void>> deleteCustomer(String id);

  /// تغییر وضعیت فعال/غیرفعال مشتری
  Future<Either<Failure, CustomerEntity>> toggleCustomerStatus(String id);

  /// بروزرسانی بدهی مشتری
  Future<Either<Failure, CustomerEntity>> updateCustomerDebt(String id, double newDebt);
}
