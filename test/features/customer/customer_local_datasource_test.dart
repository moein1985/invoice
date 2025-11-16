import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:invoice/features/customer/data/datasources/customer_local_datasource.dart';
import 'package:invoice/features/customer/data/models/customer_model.dart';

void main() {
  group('CustomerLocalDataSourceImpl', () {
    late Directory tempDir;
    late CustomerLocalDataSourceImpl ds;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('hive_customer_test_');
      Hive.init(tempDir.path);
      if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(CustomerModelAdapter());
      ds = CustomerLocalDataSourceImpl();
    });

    tearDown(() async {
      if (Hive.isBoxOpen(CustomerLocalDataSourceImpl.boxName)) {
        final box = Hive.box<CustomerModel>(CustomerLocalDataSourceImpl.boxName);
        await box.clear();
        await box.close();
      }
      await tempDir.delete(recursive: true);
    });

    test('saveCustomer and getCustomers', () async {
      final customer = CustomerModel(
        id: 'c1',
        name: 'Cust',
        phone: '0912',
        createdAt: DateTime.now(),
      );

      final saved = await ds.saveCustomer(customer);
      expect(saved.id, equals('c1'));

      final list = await ds.getCustomers();
      expect(list.length, equals(1));
    });

    test('toggleCustomerStatus and updateCustomerDebt', () async {
      final customer = CustomerModel(
        id: 'c2',
        name: 'C2',
        phone: '0913',
        createdAt: DateTime.now(),
      );
      await ds.saveCustomer(customer);

      final toggled = await ds.toggleCustomerStatus('c2');
      expect(toggled.isActive, equals(false));

      final updatedDebt = await ds.updateCustomerDebt('c2', 123.45);
      expect(updatedDebt.currentDebt, equals(123.45));
    });
  });
}
