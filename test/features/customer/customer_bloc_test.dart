import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:invoice/features/customer/presentation/bloc/customer_bloc.dart';
import 'package:invoice/features/customer/domain/usecases/get_customers_usecase.dart';
import 'package:invoice/features/customer/domain/usecases/create_customer_usecase.dart';
import 'package:invoice/features/customer/domain/usecases/update_customer_usecase.dart';
import 'package:invoice/features/customer/domain/usecases/delete_customer_usecase.dart';
import 'package:invoice/features/customer/domain/usecases/search_customers_usecase.dart';
import 'package:invoice/features/customer/domain/usecases/toggle_customer_status_usecase.dart';
import 'package:invoice/features/customer/domain/entities/customer_entity.dart';

class MockGetCustomers extends Mock implements GetCustomersUseCase {}
class MockCreateCustomer extends Mock implements CreateCustomerUseCase {}
class MockUpdateCustomer extends Mock implements UpdateCustomerUseCase {}
class MockDeleteCustomer extends Mock implements DeleteCustomerUseCase {}
class MockSearchCustomers extends Mock implements SearchCustomersUseCase {}
class MockToggleCustomerStatus extends Mock implements ToggleCustomerStatusUseCase {}

void main() {
  late MockGetCustomers mockGetCustomers;
  late MockCreateCustomer mockCreateCustomer;
  late CustomerBloc bloc;

  setUp(() {
    mockGetCustomers = MockGetCustomers();
    mockCreateCustomer = MockCreateCustomer();
    final mockUpdateCustomer = MockUpdateCustomer();
    final mockDeleteCustomer = MockDeleteCustomer();
    final mockSearchCustomers = MockSearchCustomers();
    final mockToggleCustomerStatus = MockToggleCustomerStatus();

    bloc = CustomerBloc(
      getCustomersUseCase: mockGetCustomers,
      createCustomerUseCase: mockCreateCustomer,
      updateCustomerUseCase: mockUpdateCustomer,
      deleteCustomerUseCase: mockDeleteCustomer,
      searchCustomersUseCase: mockSearchCustomers,
      toggleCustomerStatusUseCase: mockToggleCustomerStatus,
    );
  });

  test('emits [CustomerLoading, CustomersLoaded] when LoadCustomers succeeds', () async {
    final customer = CustomerEntity(id: 'c1', name: 'Name', phone: '0912', createdAt: DateTime(2023));
    when(() => mockGetCustomers()).thenAnswer((_) async => Right([customer]));

    final future = expectLater(bloc.stream, emitsInOrder([isA<CustomerLoading>(), isA<CustomersLoaded>()]));

    bloc.add(LoadCustomers());
    await future;
  });

  test('emits [CustomerLoading, CustomerOperationSuccess] when CreateCustomer succeeds', () async {
    final customer = CustomerEntity(id: 'c2', name: 'New', phone: '0913', createdAt: DateTime(2024));
    when(() => mockCreateCustomer(
      name: any(named: 'name'),
      phone: any(named: 'phone'),
      email: any(named: 'email'),
      address: any(named: 'address'),
      company: any(named: 'company'),
      nationalId: any(named: 'nationalId'),
      creditLimit: any(named: 'creditLimit'),
      currentDebt: any(named: 'currentDebt'),
    )).thenAnswer((_) async => Right(customer));

    final future = expectLater(bloc.stream, emitsInOrder([isA<CustomerLoading>(), isA<CustomerOperationSuccess>()]));

    bloc.add(const CreateCustomer(name: 'New', phone: '0913'));
    await future;
  });
}
