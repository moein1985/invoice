import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/enums/document_type.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/usecases/create_document_usecase.dart';
import '../../domain/usecases/update_document_usecase.dart';
import '../../domain/usecases/delete_document_usecase.dart';
import '../../domain/usecases/get_documents_usecase.dart';
import '../../domain/usecases/get_document_by_id_usecase.dart';
import '../../domain/usecases/search_documents_usecase.dart';
import '../../domain/usecases/convert_proforma_to_invoice_usecase.dart';
import '../../domain/usecases/convert_document_usecase.dart';
import 'document_event.dart';
import 'document_state.dart';

class DocumentBloc extends Bloc<DocumentEvent, DocumentState> {
  final GetDocumentsUseCase getDocumentsUseCase;
  final GetDocumentByIdUseCase getDocumentByIdUseCase;
  final CreateDocumentUseCase createDocumentUseCase;
  final UpdateDocumentUseCase updateDocumentUseCase;
  final DeleteDocumentUseCase deleteDocumentUseCase;
  final SearchDocumentsUseCase searchDocumentsUseCase;
  final ConvertProformaToInvoiceUseCase convertProformaToInvoiceUseCase;
  final ConvertDocumentUseCase convertDocumentUseCase;

  DocumentBloc({
    required this.getDocumentsUseCase,
    required this.getDocumentByIdUseCase,
    required this.createDocumentUseCase,
    required this.updateDocumentUseCase,
    required this.deleteDocumentUseCase,
    required this.searchDocumentsUseCase,
    required this.convertProformaToInvoiceUseCase,
    required this.convertDocumentUseCase,
  }) : super(const DocumentInitial()) {
    on<LoadDocuments>(_onLoadDocuments);
    on<LoadDocumentById>(_onLoadDocumentById);
    on<SearchDocuments>(_onSearchDocuments);
    on<CreateDocument>(_onCreateDocument);
    on<UpdateDocument>(_onUpdateDocument);
    on<DeleteDocument>(_onDeleteDocument);
    on<ConvertToInvoice>(_onConvertToInvoice);
    on<ConvertDocument>(_onConvertDocument);
  }

  Future<void> _onLoadDocuments(
    LoadDocuments event,
    Emitter<DocumentState> emit,
  ) async {
    AppLogger.debug('LoadDocuments started for userId=${event.userId}', 'DocumentBloc');
    emit(const DocumentLoading());
    
    final result = await getDocumentsUseCase(event.userId);
    
    result.fold(
      (failure) {
        AppLogger.error('LoadDocuments failed: ${failure.message}', 'DocumentBloc');
        emit(DocumentError(failure.message));
      },
      (documents) {
        // شمارش اسناد بر اساس نوع برای دیباگ دقیق
        final tempCount = documents.where((d) => d.documentType.name == 'tempProforma').length;
        final proformaCount = documents.where((d) => d.documentType.name == 'proforma').length;
        final invoiceCount = documents.where((d) => d.documentType.name == 'invoice').length;
        final returnCount = documents.where((d) => d.documentType.name == 'returnInvoice').length;
        AppLogger.debug('LoadDocuments success: total=${documents.length} temp=$tempCount proforma=$proformaCount invoice=$invoiceCount return=$returnCount', 'DocumentBloc');
        emit(DocumentsLoaded(documents));
      },
    );
  }

  Future<void> _onLoadDocumentById(
    LoadDocumentById event,
    Emitter<DocumentState> emit,
  ) async {
    AppLogger.debug('LoadDocumentById started for id=${event.documentId}', 'DocumentBloc');
    emit(const DocumentLoading());
    
    final result = await getDocumentByIdUseCase(event.documentId);
    
    result.fold(
      (failure) {
        AppLogger.error('LoadDocumentById failed: ${failure.message}', 'DocumentBloc');
        emit(DocumentError(failure.message));
      },
      (document) {
        AppLogger.debug('LoadDocumentById success: number=${document.documentNumber} type=${document.documentType}', 'DocumentBloc');
        emit(DocumentLoaded(document));
      },
    );
  }

  Future<void> _onSearchDocuments(
    SearchDocuments event,
    Emitter<DocumentState> emit,
  ) async {
    AppLogger.debug('SearchDocuments started query="${event.query}" type=${event.type} userId=${event.userId}', 'DocumentBloc');
    emit(const DocumentLoading());
    
    final result = await searchDocumentsUseCase(
      userId: event.userId,
      query: event.query,
      type: event.type,
      startDate: event.startDate,
      endDate: event.endDate,
    );
    
    result.fold(
      (failure) {
        AppLogger.error('SearchDocuments failed: ${failure.message}', 'DocumentBloc');
        emit(DocumentError(failure.message));
      },
      (documents) {
        AppLogger.debug('SearchDocuments success: results=${documents.length}', 'DocumentBloc');
        emit(DocumentsLoaded(documents));
      },
    );
  }

  Future<void> _onCreateDocument(
    CreateDocument event,
    Emitter<DocumentState> emit,
  ) async {
    AppLogger.debug('CreateDocument started number=${event.document.documentNumber} type=${event.document.documentType}', 'DocumentBloc');
    emit(const DocumentLoading());
    
    final result = await createDocumentUseCase(event.document);
    
    result.fold(
      (failure) {
        AppLogger.error('CreateDocument failed: ${failure.message}', 'DocumentBloc');
        emit(DocumentError(failure.message));
      },
      (document) {
        AppLogger.info('CreateDocument success: number=${document.documentNumber} type=${document.documentType}', 'DocumentBloc');
        emit(DocumentCreated(document));
      },
    );
  }

  Future<void> _onUpdateDocument(
    UpdateDocument event,
    Emitter<DocumentState> emit,
  ) async {
    AppLogger.debug('UpdateDocument started id=${event.document.id} number=${event.document.documentNumber}', 'DocumentBloc');
    emit(const DocumentLoading());
    
    final result = await updateDocumentUseCase(event.document);
    
    result.fold(
      (failure) {
        AppLogger.error('UpdateDocument failed: ${failure.message}', 'DocumentBloc');
        emit(DocumentError(failure.message));
      },
      (document) {
        AppLogger.info('UpdateDocument success: number=${document.documentNumber} type=${document.documentType}', 'DocumentBloc');
        emit(DocumentUpdated(document));
      },
    );
  }

  Future<void> _onDeleteDocument(
    DeleteDocument event,
    Emitter<DocumentState> emit,
  ) async {
    AppLogger.debug('DeleteDocument started id=${event.documentId}', 'DocumentBloc');
    emit(const DocumentLoading());
    
    final result = await deleteDocumentUseCase(event.documentId);
    
    result.fold(
      (failure) {
        AppLogger.error('DeleteDocument failed: ${failure.message}', 'DocumentBloc');
        emit(DocumentError(failure.message));
      },
      (_) {
        AppLogger.info('DeleteDocument success id=${event.documentId}', 'DocumentBloc');
        emit(const DocumentDeleted());
      },
    );
  }

  Future<void> _onConvertToInvoice(
    ConvertToInvoice event,
    Emitter<DocumentState> emit,
  ) async {
    AppLogger.debug('ConvertToInvoice started proformaId=${event.proformaId}', 'DocumentBloc');
    emit(const DocumentLoading());
    
    final result = await convertProformaToInvoiceUseCase(event.proformaId);
    
    result.fold(
      (failure) {
        AppLogger.error('ConvertToInvoice failed: ${failure.message}', 'DocumentBloc');
        emit(DocumentError(failure.message));
      },
      (invoice) {
        AppLogger.info('ConvertToInvoice success newNumber=${invoice.documentNumber}', 'DocumentBloc');
        emit(DocumentConverted(
          invoice,
          fromType: DocumentType.proforma,
          toType: DocumentType.invoice,
        ));
      },
    );
  }

  Future<void> _onConvertDocument(
    ConvertDocument event,
    Emitter<DocumentState> emit,
  ) async {
    AppLogger.debug('ConvertDocument started for id=${event.documentId}', 'DocumentBloc');
    emit(const DocumentLoading());
    
    // ابتدا سند را بارگذاری می‌کنیم
    final documentResult = await getDocumentByIdUseCase(event.documentId);
    
    await documentResult.fold(
      (failure) async {
        AppLogger.error('ConvertDocument load failed: ${failure.message}', 'DocumentBloc');
        emit(DocumentError(failure.message));
      },
      (document) async {
        AppLogger.debug('ConvertDocument loaded number=${document.documentNumber} currentType=${document.documentType}', 'DocumentBloc');
        // سند را تبدیل می‌کنیم
        final convertResult = await convertDocumentUseCase(document);
        
        convertResult.fold(
          (failure) {
            AppLogger.error('ConvertDocument failed: ${failure.message}', 'DocumentBloc');
            emit(DocumentError(failure.message));
          },
          (convertedDocument) {
            AppLogger.info('ConvertDocument success number=${convertedDocument.documentNumber} newType=${convertedDocument.documentType}', 'DocumentBloc');
            emit(DocumentConverted(
              convertedDocument,
              fromType: document.documentType,
              toType: convertedDocument.documentType,
            ));
          },
        );
      },
    );
  }
}
