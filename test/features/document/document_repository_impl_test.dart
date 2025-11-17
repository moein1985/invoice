import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:invoice/core/enums/document_type.dart';
import 'package:invoice/features/document/data/datasources/document_local_datasource.dart';
import 'package:invoice/features/document/data/models/document_item_model.dart';
import 'package:invoice/features/document/data/models/document_model.dart';
import 'package:invoice/features/document/data/repositories/document_repository_impl.dart';

class MockDocumentLocalDataSource extends Mock implements DocumentLocalDataSource {}

DocumentModel _sampleDoc({required String id, String type = 'invoice'}) {
  final item = DocumentItemModel(
    id: 'i1',
    productName: 'item',
    quantity: 1,
    unit: 'عدد',
    purchasePrice: 8,
    sellPrice: 10,
    totalPrice: 10,
    profitPercentage: 25,
    supplier: 's',
  );

  return DocumentModel(
    id: id,
    userId: 'u1',
    documentNumber: type == 'invoice' ? 'INV-1001' : 'PRO-1001',
    documentTypeString: type,
    customerId: 'c1',
    documentDate: DateTime.now(),
    items: [item],
    totalAmount: 10,
    discount: 0,
    finalAmount: 10,
    statusString: 'unpaid',
    notes: null,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

void main() {
  setUpAll(() {
    // register a fallback DocumentModel for mocktail when using `any()`
    registerFallbackValue(_sampleDoc(id: 'fallback'));
  });

  late MockDocumentLocalDataSource mockLocal;
  late DocumentRepositoryImpl repository;

  setUp(() {
    mockLocal = MockDocumentLocalDataSource();
    repository = DocumentRepositoryImpl(localDataSource: mockLocal);
  });

  group('createDocument', () {
    test('returns Right(entity) when local succeeds', () async {
      final doc = _sampleDoc(id: 'd1');
      when(() => mockLocal.createDocument(any())).thenAnswer((_) async => doc);

      final res = await repository.createDocument(doc.toEntity());
      expect(res.isRight(), isTrue);
      res.fold((l) => fail('expected right'), (r) => expect(r.id, equals('d1')));
    });
  });

  group('getNextDocumentNumber', () {
    test('returns Right(number) on success', () async {
      when(() => mockLocal.getNextDocumentNumber('invoice')).thenAnswer((_) async => 'INV-1001');

      final res = await repository.getNextDocumentNumber(DocumentType.invoice);
      expect(res.isRight(), isTrue);
      res.fold((l) => fail('expected right'), (r) => expect(r, equals('INV-1001')));
    });
  });
}
