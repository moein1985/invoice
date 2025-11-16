import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:invoice/core/error/failures.dart';
import 'package:invoice/features/customer/domain/entities/customer_entity.dart';
import 'package:invoice/features/customer/domain/repositories/customer_repository.dart';
import 'package:invoice/features/customer/domain/usecases/create_customer_usecase.dart';
import 'package:invoice/features/customer/domain/usecases/get_customers_usecase.dart';
import 'package:invoice/features/customer/domain/usecases/toggle_customer_status_usecase.dart';
import 'package:invoice/features/customer/domain/usecases/update_customer_usecase.dart';

class CustomerEntityFake extends Fake implements CustomerEntity {}

class MockCustomerRepo extends Mock implements CustomerRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(CustomerEntityFake());
  });

  late MockCustomerRepo mockRepo;
  late GetCustomersUseCase getCustomers;
  late CreateCustomerUseCase createCustomer;
  late ToggleCustomerStatusUseCase toggleStatus;
  late UpdateCustomerUseCase updateCustomer;

  setUp(() {
    mockRepo = MockCustomerRepo();
    getCustomers = GetCustomersUseCase(mockRepo);
    createCustomer = CreateCustomerUseCase(mockRepo);
    toggleStatus = ToggleCustomerStatusUseCase(mockRepo);
    updateCustomer = UpdateCustomerUseCase(mockRepo);
  });

  test('GetCustomersUseCase returns list on success', () async {
    final c = CustomerEntity(id: 'c1', name: 'C', phone: '0912', createdAt: DateTime.now());
    when(() => mockRepo.getCustomers()).thenAnswer((_) async => Right([c]));
    final res = await getCustomers();
    expect(res.isRight(), isTrue);
  });

  test('CreateCustomerUseCase delegates to repo', () async {
    final c = CustomerEntity(id: 'c2', name: 'New', phone: '0913', createdAt: DateTime.now());
    when(() => mockRepo.createCustomer(any())).thenAnswer((_) async => Right(c));
    final res = await createCustomer(name: 'New', phone: '0913');
    expect(res.isRight(), isTrue);
  });

  test('ToggleCustomerStatusUseCase returns updated customer', () async {
    final c = CustomerEntity(id: 'c3', name: 'C3', phone: '0914', createdAt: DateTime.now());
    when(() => mockRepo.toggleCustomerStatus('c3')).thenAnswer((_) async => Right(c));
    final res = await toggleStatus('c3');
    expect(res.isRight(), isTrue);
  });

  test('UpdateCustomerUseCase returns failure when repo fails', () async {
    final current = CustomerEntity(id: 'c4', name: 'X', phone: '0', createdAt: DateTime.now());
    when(() => mockRepo.getCustomerById('c4')).thenAnswer((_) async => Right(current));
    when(() => mockRepo.updateCustomer(any())).thenAnswer((_) async => Left(CacheFailure('err')));

    final res = await updateCustomer(id: 'c4', name: 'NewName');
    expect(res.isLeft(), isTrue);
  });
}
