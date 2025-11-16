import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:invoice/features/customer/data/datasources/customer_local_datasource.dart';
import 'package:invoice/features/customer/data/models/customer_model.dart';
import 'package:invoice/features/customer/data/repositories/customer_repository_impl.dart';

class CustomerModelFake extends Fake implements CustomerModel {}

class MockCustomerLocal extends Mock implements CustomerLocalDataSource {}

void main() {
  setUpAll(() {
    registerFallbackValue(CustomerModelFake());
  });

  late MockCustomerLocal mockLocal;
  late CustomerRepositoryImpl repository;

  setUp(() async {
    mockLocal = MockCustomerLocal();
    repository = CustomerRepositoryImpl(localDataSource: mockLocal);
  });

  test('getCustomers returns Right(list) on success', () async {
    final m = CustomerModel(id: 'c1', name: 'C', phone: '0912', createdAt: DateTime.now());
    when(() => mockLocal.getCustomers()).thenAnswer((_) async => [m]);

    final res = await repository.getCustomers();
    expect(res.isRight(), isTrue);
  });

  test('createCustomer returns Right on success', () async {
    final m = CustomerModel(id: 'c2', name: 'New', phone: '0913', createdAt: DateTime.now());
    when(() => mockLocal.saveCustomer(any())).thenAnswer((_) async => m);
    final ent = m.toEntity();
    final res = await repository.createCustomer(ent);
    expect(res.isRight(), isTrue);
  });
}
