import 'package:equatable/equatable.dart';
import '../../../../core/enums/document_type.dart';
import '../../domain/entities/document_entity.dart';

abstract class DocumentState extends Equatable {
  const DocumentState();

  @override
  List<Object?> get props => [];
}

/// حالت اولیه
class DocumentInitial extends DocumentState {
  const DocumentInitial();
}

/// در حال بارگذاری
class DocumentLoading extends DocumentState {
  const DocumentLoading();
}

/// اسناد بارگذاری شده
class DocumentsLoaded extends DocumentState {
  final List<DocumentEntity> documents;
  
  const DocumentsLoaded(this.documents);
  
  @override
  List<Object?> get props => [documents];
}

/// یک سند بارگذاری شده
class DocumentLoaded extends DocumentState {
  final DocumentEntity document;
  
  const DocumentLoaded(this.document);
  
  @override
  List<Object?> get props => [document];
}

/// سند با موفقیت ایجاد شد
class DocumentCreated extends DocumentState {
  final DocumentEntity document;
  
  const DocumentCreated(this.document);
  
  @override
  List<Object?> get props => [document];
}

/// سند با موفقیت به‌روز شد
class DocumentUpdated extends DocumentState {
  final DocumentEntity document;
  
  const DocumentUpdated(this.document);
  
  @override
  List<Object?> get props => [document];
}

/// سند با موفقیت حذف شد
class DocumentDeleted extends DocumentState {
  const DocumentDeleted();
}

/// سند تبدیل شد
class DocumentConverted extends DocumentState {
  final DocumentEntity convertedDocument;
  final DocumentType fromType;
  final DocumentType toType;
  
  const DocumentConverted(this.convertedDocument, {required this.fromType, required this.toType});
  
  @override
  List<Object?> get props => [convertedDocument, fromType, toType];
}

/// خطا
class DocumentError extends DocumentState {
  final String message;
  
  const DocumentError(this.message);
  
  @override
  List<Object?> get props => [message];
}
