import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:invoice/features/document/presentation/bloc/document_bloc.dart';
import 'package:invoice/features/document/presentation/bloc/document_event.dart';
import 'package:invoice/features/document/presentation/bloc/document_state.dart';
import 'package:invoice/features/document/domain/usecases/get_documents_usecase.dart';
import 'package:invoice/features/document/domain/usecases/get_document_by_id_usecase.dart';
import 'package:invoice/features/document/domain/usecases/create_document_usecase.dart';
import 'package:invoice/features/document/domain/usecases/update_document_usecase.dart';
import 'package:invoice/features/document/domain/usecases/delete_document_usecase.dart';
import 'package:invoice/features/document/domain/usecases/search_documents_usecase.dart';
import 'package:invoice/features/document/domain/usecases/convert_proforma_to_invoice_usecase.dart';
import 'package:invoice/features/document/domain/entities/document_entity.dart';
import 'package:invoice/features/document/domain/entities/document_item_entity.dart';
import 'package:invoice/core/enums/document_type.dart' as dt;
import 'package:invoice/core/enums/document_status.dart' as ds;

class MockGetDocuments extends Mock implements GetDocumentsUseCase {}
class MockGetDocumentById extends Mock implements GetDocumentByIdUseCase {}
class MockCreateDocument extends Mock implements CreateDocumentUseCase {}
class MockUpdateDocument extends Mock implements UpdateDocumentUseCase {}
class MockDeleteDocument extends Mock implements DeleteDocumentUseCase {}
class MockSearchDocuments extends Mock implements SearchDocumentsUseCase {}
class MockConvertProforma extends Mock implements ConvertProformaToInvoiceUseCase {}

void main() {
  late MockGetDocuments mockGetDocuments;
  late MockCreateDocument mockCreateDocument;
  late MockConvertProforma mockConvertProforma;
  late DocumentBloc bloc;

  setUp(() {
    mockGetDocuments = MockGetDocuments();
    mockCreateDocument = MockCreateDocument();
    mockConvertProforma = MockConvertProforma();
    final mockGetDocumentById = MockGetDocumentById();
    final mockUpdateDocument = MockUpdateDocument();
    final mockDeleteDocument = MockDeleteDocument();
    final mockSearchDocuments = MockSearchDocuments();

    bloc = DocumentBloc(
      getDocumentsUseCase: mockGetDocuments,
      getDocumentByIdUseCase: mockGetDocumentById,
      createDocumentUseCase: mockCreateDocument,
      updateDocumentUseCase: mockUpdateDocument,
      deleteDocumentUseCase: mockDeleteDocument,
      searchDocumentsUseCase: mockSearchDocuments,
      convertProformaToInvoiceUseCase: mockConvertProforma,
    );
  });

  test('emits [DocumentLoading, DocumentsLoaded] when LoadDocuments succeeds', () async {
    final doc = DocumentEntity(
      id: 'd1',
      userId: 'u1',
      documentNumber: '1',
      documentType: dt.DocumentType.invoice,
      customerId: 'c1',
      documentDate: DateTime.now(),
      items: [DocumentItemEntity(id: 'i1', productName: 'item', quantity: 1, unitPrice: 100, totalPrice: 100, profitPercentage: 0, supplier: 's1')],
      totalAmount: 100,
      discount: 0,
      finalAmount: 100,
      status: ds.DocumentStatus.paid,
      notes: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    when(() => mockGetDocuments('u1')).thenAnswer((_) async => Right([doc]));

    final expected = [const DocumentLoading(), DocumentsLoaded([doc])];
    expectLater(bloc.stream, emitsInOrder(expected));

    bloc.add(const LoadDocuments('u1'));
  });

  test('emits [DocumentLoading, DocumentCreated] when CreateDocument succeeds', () async {
    final doc = DocumentEntity(
      id: 'd2',
      userId: 'u1',
      documentNumber: '2',
      documentType: dt.DocumentType.invoice,
      customerId: 'c1',
      documentDate: DateTime.now(),
      items: [DocumentItemEntity(id: 'i1', productName: 'item', quantity: 1, unitPrice: 100, totalPrice: 100, profitPercentage: 0, supplier: 's1')],
      totalAmount: 100,
      discount: 0,
      finalAmount: 100,
      status: ds.DocumentStatus.pending,
      notes: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    when(() => mockCreateDocument(doc)).thenAnswer((_) async => Right(doc));

    final expected = [const DocumentLoading(), DocumentCreated(doc)];
    expectLater(bloc.stream, emitsInOrder(expected));

    bloc.add(CreateDocument(doc));
  });

  test('emits [DocumentLoading, DocumentConverted] when ConvertToInvoice succeeds', () async {
    final invoice = DocumentEntity(
      id: 'inv1',
      userId: 'u1',
      documentNumber: '3',
      documentType: dt.DocumentType.invoice,
      customerId: 'c1',
      documentDate: DateTime.now(),
      items: [DocumentItemEntity(id: 'i1', productName: 'item', quantity: 1, unitPrice: 100, totalPrice: 100, profitPercentage: 0, supplier: 's1')],
      totalAmount: 100,
      discount: 0,
      finalAmount: 100,
      status: ds.DocumentStatus.paid,
      notes: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    when(() => mockConvertProforma('p1')).thenAnswer((_) async => Right(invoice));

    final expected = [const DocumentLoading(), DocumentConverted(invoice)];
    expectLater(bloc.stream, emitsInOrder(expected));

    bloc.add(const ConvertToInvoice('p1'));
  });
}
