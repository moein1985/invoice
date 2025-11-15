import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/create_document_usecase.dart';
import '../../domain/usecases/update_document_usecase.dart';
import '../../domain/usecases/delete_document_usecase.dart';
import '../../domain/usecases/get_documents_usecase.dart';
import '../../domain/usecases/get_document_by_id_usecase.dart';
import '../../domain/usecases/search_documents_usecase.dart';
import '../../domain/usecases/convert_proforma_to_invoice_usecase.dart';
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

  DocumentBloc({
    required this.getDocumentsUseCase,
    required this.getDocumentByIdUseCase,
    required this.createDocumentUseCase,
    required this.updateDocumentUseCase,
    required this.deleteDocumentUseCase,
    required this.searchDocumentsUseCase,
    required this.convertProformaToInvoiceUseCase,
  }) : super(const DocumentInitial()) {
    on<LoadDocuments>(_onLoadDocuments);
    on<LoadDocumentById>(_onLoadDocumentById);
    on<SearchDocuments>(_onSearchDocuments);
    on<CreateDocument>(_onCreateDocument);
    on<UpdateDocument>(_onUpdateDocument);
    on<DeleteDocument>(_onDeleteDocument);
    on<ConvertToInvoice>(_onConvertToInvoice);
  }

  Future<void> _onLoadDocuments(
    LoadDocuments event,
    Emitter<DocumentState> emit,
  ) async {
    emit(const DocumentLoading());
    
    final result = await getDocumentsUseCase(event.userId);
    
    result.fold(
      (failure) => emit(DocumentError(failure.message)),
      (documents) => emit(DocumentsLoaded(documents)),
    );
  }

  Future<void> _onLoadDocumentById(
    LoadDocumentById event,
    Emitter<DocumentState> emit,
  ) async {
    emit(const DocumentLoading());
    
    final result = await getDocumentByIdUseCase(event.documentId);
    
    result.fold(
      (failure) => emit(DocumentError(failure.message)),
      (document) => emit(DocumentLoaded(document)),
    );
  }

  Future<void> _onSearchDocuments(
    SearchDocuments event,
    Emitter<DocumentState> emit,
  ) async {
    emit(const DocumentLoading());
    
    final result = await searchDocumentsUseCase(
      userId: event.userId,
      query: event.query,
      type: event.type,
      startDate: event.startDate,
      endDate: event.endDate,
    );
    
    result.fold(
      (failure) => emit(DocumentError(failure.message)),
      (documents) => emit(DocumentsLoaded(documents)),
    );
  }

  Future<void> _onCreateDocument(
    CreateDocument event,
    Emitter<DocumentState> emit,
  ) async {
    emit(const DocumentLoading());
    
    final result = await createDocumentUseCase(event.document);
    
    result.fold(
      (failure) => emit(DocumentError(failure.message)),
      (document) => emit(DocumentCreated(document)),
    );
  }

  Future<void> _onUpdateDocument(
    UpdateDocument event,
    Emitter<DocumentState> emit,
  ) async {
    emit(const DocumentLoading());
    
    final result = await updateDocumentUseCase(event.document);
    
    result.fold(
      (failure) => emit(DocumentError(failure.message)),
      (document) => emit(DocumentUpdated(document)),
    );
  }

  Future<void> _onDeleteDocument(
    DeleteDocument event,
    Emitter<DocumentState> emit,
  ) async {
    emit(const DocumentLoading());
    
    final result = await deleteDocumentUseCase(event.documentId);
    
    result.fold(
      (failure) => emit(DocumentError(failure.message)),
      (_) => emit(const DocumentDeleted()),
    );
  }

  Future<void> _onConvertToInvoice(
    ConvertToInvoice event,
    Emitter<DocumentState> emit,
  ) async {
    emit(const DocumentLoading());
    
    final result = await convertProformaToInvoiceUseCase(event.proformaId);
    
    result.fold(
      (failure) => emit(DocumentError(failure.message)),
      (invoice) => emit(DocumentConverted(invoice)),
    );
  }
}
