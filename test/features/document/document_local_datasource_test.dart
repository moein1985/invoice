import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:invoice/core/constants/hive_boxes.dart';
import 'package:invoice/features/document/data/datasources/document_local_datasource.dart';
import 'package:invoice/features/document/data/models/document_item_model.dart';
import 'package:invoice/features/document/data/models/document_model.dart';

void main() {
  group('DocumentLocalDataSourceImpl', () {
    late Directory tempDir;
    late DocumentLocalDataSourceImpl ds;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('hive_doc_test_');
      Hive.init(tempDir.path);
      if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(DocumentModelAdapter());
      if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(DocumentItemModelAdapter());
      await Hive.openBox<DocumentModel>(HiveBoxes.documents);
      ds = DocumentLocalDataSourceImpl();
    });

    tearDown(() async {
      if (Hive.isBoxOpen(HiveBoxes.documents)) {
        final box = Hive.box<DocumentModel>(HiveBoxes.documents);
        await box.clear();
        await box.close();
      }
      await tempDir.delete(recursive: true);
    });

    test('createDocument and getDocumentById', () async {
      final item = DocumentItemModel(
        id: 'i1',
        productName: 'P',
        quantity: 1,
        unit: 'عدد',
        purchasePrice: 8.0,
        sellPrice: 10.0,
        totalPrice: 10.0,
        profitPercentage: 25.0,
        supplier: 'S',
      );

      final doc = DocumentModel(
        id: 'd1',
        userId: 'u1',
        documentNumber: 'INV-1001',
        documentTypeString: 'invoice',
        customerId: 'c1',
        documentDate: DateTime.now(),
        items: [item],
        totalAmount: 10.0,
        discount: 0.0,
        finalAmount: 10.0,
        statusString: 'unpaid',
        notes: 'note',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        approvalStatus: 'notRequired',
      );

      await ds.createDocument(doc);
      final fetched = await ds.getDocumentById('d1');
      expect(fetched.documentNumber, equals('INV-1001'));
    });

    test('getNextDocumentNumber when none returns prefix-1001 and increments', () async {
      final next = await ds.getNextDocumentNumber('invoice');
      expect(next, equals('INV-1001'));

      final item = DocumentItemModel(
        id: 'i1',
        productName: 'item',
        quantity: 1,
        unit: 'عدد',
        purchasePrice: 4,
        sellPrice: 5,
        totalPrice: 5,
        profitPercentage: 25,
        supplier: 'supp',
      );

      final doc = DocumentModel(
        id: 'd2',
        userId: 'u1',
        documentNumber: next,
        documentTypeString: 'invoice',
        customerId: 'c1',
        documentDate: DateTime.now(),
        items: [item],
        totalAmount: 5,
        discount: 0,
        finalAmount: 5,
        statusString: 'unpaid',
        notes: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        approvalStatus: 'notRequired',
      );

      await ds.createDocument(doc);
      final next2 = await ds.getNextDocumentNumber('invoice');
      expect(next2, equals('INV-1002'));
    });

    test('searchDocuments filters by query and type', () async {
      final item = DocumentItemModel(
        id: 'i1',
        productName: 'Item',
        quantity: 1,
        unit: 'عدد',
        purchasePrice: 0.8,
        sellPrice: 1,
        totalPrice: 1,
        profitPercentage: 25,
        supplier: 'Sup',
      );

      final proforma = DocumentModel(
        id: 'p1',
        userId: 'u1',
        documentNumber: 'PRO-1001',
        documentTypeString: 'proforma',
        customerId: 'c1',
        documentDate: DateTime.now().subtract(Duration(days: 2)),
        items: [item],
        totalAmount: 1,
        discount: 0,
        finalAmount: 1,
        statusString: 'unpaid',
        notes: 'special',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        approvalStatus: 'notRequired',
      );

      await ds.createDocument(proforma);

      final results = await ds.searchDocuments(userId: 'u1', query: 'special');
      expect(results.length, equals(1));

      final results2 = await ds.searchDocuments(userId: 'u1', type: 'proforma');
      expect(results2.length, equals(1));
    });

    test('convertProformaToInvoice creates invoice', () async {
      final item = DocumentItemModel(
        id: 'i1',
        productName: 'Item',
        quantity: 1,
        unit: 'عدد',
        purchasePrice: 1.6,
        sellPrice: 2,
        totalPrice: 2,
        profitPercentage: 25,
        supplier: 'Sup',
      );

      final pro = DocumentModel(
        id: 'pro1',
        userId: 'u1',
        documentNumber: 'PRO-1001',
        documentTypeString: 'proforma',
        customerId: 'c1',
        documentDate: DateTime.now(),
        items: [item],
        totalAmount: 2,
        discount: 0,
        finalAmount: 2,
        statusString: 'unpaid',
        notes: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        approvalStatus: 'notRequired',
      );

      await ds.createDocument(pro);
      final invoice = await ds.convertProformaToInvoice('pro1');
      expect(invoice.documentTypeString, equals('invoice'));
      expect(invoice.documentNumber.startsWith('INV-'), isTrue);
    });
  });
}
