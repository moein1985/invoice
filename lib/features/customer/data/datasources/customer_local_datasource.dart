import 'package:hive/hive.dart';
import '../../../../core/error/exceptions.dart';
import '../models/customer_model.dart';

abstract class CustomerLocalDataSource {
  /// دریافت لیست همه مشتریان
  Future<List<CustomerModel>> getCustomers();

  /// جستجوی مشتریان
  Future<List<CustomerModel>> searchCustomers(String query);

  /// دریافت مشتری بر اساس ID
  Future<CustomerModel> getCustomerById(String id);

  /// ذخیره مشتری جدید
  Future<CustomerModel> saveCustomer(CustomerModel customer);

  /// بروزرسانی مشتری موجود
  Future<CustomerModel> updateCustomer(CustomerModel customer);

  /// حذف مشتری
  Future<void> deleteCustomer(String id);

  /// تغییر وضعیت فعال/غیرفعال مشتری
  Future<CustomerModel> toggleCustomerStatus(String id);

  /// بروزرسانی بدهی مشتری
  Future<CustomerModel> updateCustomerDebt(String id, double newDebt);
}

class CustomerLocalDataSourceImpl implements CustomerLocalDataSource {
  static const String boxName = 'customers';

  @override
  Future<List<CustomerModel>> getCustomers() async {
    try {
      final box = await Hive.openBox<CustomerModel>(boxName);
      return box.values.toList();
    } catch (e) {
      throw CacheException('خطا در دریافت لیست مشتریان');
    }
  }

  @override
  Future<List<CustomerModel>> searchCustomers(String query) async {
    try {
      final box = await Hive.openBox<CustomerModel>(boxName);
      final customers = box.values.toList();

      if (query.isEmpty) {
        return customers;
      }

      final lowerQuery = query.toLowerCase();
      return customers.where((customer) {
        return customer.name.toLowerCase().contains(lowerQuery) ||
               customer.phone.contains(query) ||
               (customer.email?.toLowerCase().contains(lowerQuery) ?? false) ||
               (customer.company?.toLowerCase().contains(lowerQuery) ?? false);
      }).toList();
    } catch (e) {
      throw CacheException('خطا در جستجوی مشتریان');
    }
  }

  @override
  Future<CustomerModel> getCustomerById(String id) async {
    try {
      final box = await Hive.openBox<CustomerModel>(boxName);
      final customer = box.get(id);

      if (customer == null) {
        throw CacheException('مشتری یافت نشد');
      }

      return customer;
    } catch (e) {
      throw CacheException('خطا در دریافت مشتری');
    }
  }

  @override
  Future<CustomerModel> saveCustomer(CustomerModel customer) async {
    try {
      final box = await Hive.openBox<CustomerModel>(boxName);
      await box.put(customer.id, customer);
      return customer;
    } catch (e) {
      throw CacheException('خطا در ذخیره مشتری');
    }
  }

  @override
  Future<CustomerModel> updateCustomer(CustomerModel customer) async {
    try {
      final box = await Hive.openBox<CustomerModel>(boxName);
      await box.put(customer.id, customer);
      return customer;
    } catch (e) {
      throw CacheException('خطا در بروزرسانی مشتری');
    }
  }

  @override
  Future<void> deleteCustomer(String id) async {
    try {
      final box = await Hive.openBox<CustomerModel>(boxName);
      await box.delete(id);
    } catch (e) {
      throw CacheException('خطا در حذف مشتری');
    }
  }

  @override
  Future<CustomerModel> toggleCustomerStatus(String id) async {
    try {
      final box = await Hive.openBox<CustomerModel>(boxName);
      final customer = box.get(id);

      if (customer == null) {
        throw CacheException('مشتری یافت نشد');
      }

      final updatedCustomer = CustomerModel(
        id: customer.id,
        name: customer.name,
        phone: customer.phone,
        email: customer.email,
        address: customer.address,
        company: customer.company,
        nationalId: customer.nationalId,
        creditLimit: customer.creditLimit,
        currentDebt: customer.currentDebt,
        isActive: !customer.isActive,
        createdAt: customer.createdAt,
        lastTransaction: customer.lastTransaction,
      );

      await box.put(id, updatedCustomer);
      return updatedCustomer;
    } catch (e) {
      throw CacheException('خطا در تغییر وضعیت مشتری');
    }
  }

  @override
  Future<CustomerModel> updateCustomerDebt(String id, double newDebt) async {
    try {
      final box = await Hive.openBox<CustomerModel>(boxName);
      final customer = box.get(id);

      if (customer == null) {
        throw CacheException('مشتری یافت نشد');
      }

      final updatedCustomer = CustomerModel(
        id: customer.id,
        name: customer.name,
        phone: customer.phone,
        email: customer.email,
        address: customer.address,
        company: customer.company,
        nationalId: customer.nationalId,
        creditLimit: customer.creditLimit,
        currentDebt: newDebt,
        isActive: customer.isActive,
        createdAt: customer.createdAt,
        lastTransaction: DateTime.now(),
      );

      await box.put(id, updatedCustomer);
      return updatedCustomer;
    } catch (e) {
      throw CacheException('خطا در بروزرسانی بدهی مشتری');
    }
  }
}
