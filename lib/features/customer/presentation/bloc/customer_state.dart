part of 'customer_bloc.dart';

abstract class CustomerState {
  const CustomerState();
}

class CustomerInitial extends CustomerState {}

class CustomerLoading extends CustomerState {}

class CustomersLoaded extends CustomerState {
  final List<CustomerEntity> customers;

  const CustomersLoaded(this.customers);
}

class CustomerOperationSuccess extends CustomerState {
  final String message;
  final CustomerEntity? customer;

  const CustomerOperationSuccess(this.message, [this.customer]);
}

class CustomerError extends CustomerState {
  final String message;

  const CustomerError(this.message);
}
