import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:invoice/core/enums/document_type.dart';
import 'package:invoice/core/enums/document_status.dart';
import 'package:invoice/core/enums/approval_status.dart';
import 'package:invoice/features/document/domain/entities/document_entity.dart';
import 'package:invoice/features/document/domain/entities/document_item_entity.dart';
import 'package:invoice/features/document/domain/repositories/document_repository.dart';
import 'package:invoice/features/document/domain/usecases/create_document_usecase.dart';
import 'package:invoice/features/document/domain/usecases/get_next_document_number_usecase.dart';

class DocumentEntityFake extends Fake implements DocumentEntity {}

class MockDocRepo extends Mock implements DocumentRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(DocumentEntityFake());
  });
  late MockDocRepo mockRepo;
  late CreateDocumentUseCase createDoc;
  late GetNextDocumentNumberUseCase getNext;

  setUp(() {
    mockRepo = MockDocRepo();
    createDoc = CreateDocumentUseCase(mockRepo);
    getNext = GetNextDocumentNumberUseCase(mockRepo);
  });

  test('createDocument delegates to repository', () async {
    final item = DocumentItemEntity(id: 'i1', productName: 'P', quantity: 1, unit: 'عدد', purchasePrice: 0.8, sellPrice: 1.0, totalPrice: 1.0, profitPercentage: 25.0, supplier: 'S');
    final doc = DocumentEntity(
      id: 'd1',
      userId: 'u1',
      documentNumber: 'INV-1001',
      documentType: DocumentType.invoice,
      customerId: 'c1',
      documentDate: DateTime.now(),
      items: [item],
      totalAmount: 1.0,
      discount: 0.0,
      finalAmount: 1.0,
      status: DocumentStatus.unpaid,
      notes: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      approvalStatus: ApprovalStatus.notRequired,
    );

    when(() => mockRepo.createDocument(any())).thenAnswer((_) async => Right(doc));
    final res = await createDoc(doc);
    expect(res.isRight(), isTrue);
  });

  test('getNextDocumentNumber returns number from repo', () async {
    when(() => mockRepo.getNextDocumentNumber(DocumentType.invoice)).thenAnswer((_) async => Right('INV-1001'));
    final res = await getNext(DocumentType.invoice);
    expect(res.isRight(), isTrue);
    res.fold((l) => fail('expected right'), (r) => expect(r, equals('INV-1001')));
  });
}
