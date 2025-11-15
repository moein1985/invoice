part of 'customer_bloc.dart';

abstract class CustomerEvent {
  const CustomerEvent();
}

/// درخواست بارگذاری لیست مشتریان
class LoadCustomers extends CustomerEvent {
  const LoadCustomers();
}

/// درخواست جستجوی مشتریان
class SearchCustomers extends CustomerEvent {
  final String query;

  const SearchCustomers(this.query);
}

/// درخواست ایجاد مشتری جدید
class CreateCustomer extends CustomerEvent {
  final String name;
  final String phone;
  final String? email;
  final String? address;
  final String? company;
  final String? nationalId;
  final double? creditLimit;
  final double? currentDebt;

  const CreateCustomer({
    required this.name,
    required this.phone,
    this.email,
    this.address,
    this.company,
    this.nationalId,
    this.creditLimit,
    this.currentDebt,
  });
}

/// درخواست بروزرسانی مشتری
class UpdateCustomer extends CustomerEvent {
  final String id;
  final String? name;
  final String? phone;
  final String? email;
  final String? address;
  final String? company;
  final String? nationalId;
  final double? creditLimit;
  final double? currentDebt;
  final bool? isActive;

  const UpdateCustomer({
    required this.id,
    this.name,
    this.phone,
    this.email,
    this.address,
    this.company,
    this.nationalId,
    this.creditLimit,
    this.currentDebt,
    this.isActive,
  });
}

/// درخواست حذف مشتری
class DeleteCustomer extends CustomerEvent {
  final String customerId;

  const DeleteCustomer(this.customerId);
}

/// درخواست تغییر وضعیت مشتری
class ToggleCustomerStatus extends CustomerEvent {
  final String customerId;

  const ToggleCustomerStatus(this.customerId);
}
