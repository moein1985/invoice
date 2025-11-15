import 'package:equatable/equatable.dart';
import '../../../../core/enums/document_type.dart';
import '../../domain/entities/document_entity.dart';

abstract class DocumentEvent extends Equatable {
  const DocumentEvent();

  @override
  List<Object?> get props => [];
}

/// دریافت تمام اسناد
class LoadDocuments extends DocumentEvent {
  final String userId;
  
  const LoadDocuments(this.userId);
  
  @override
  List<Object?> get props => [userId];
}

/// جستجوی اسناد
class SearchDocuments extends DocumentEvent {
  final String userId;
  final String? query;
  final DocumentType? type;
  final DateTime? startDate;
  final DateTime? endDate;
  
  const SearchDocuments({
    required this.userId,
    this.query,
    this.type,
    this.startDate,
    this.endDate,
  });
  
  @override
  List<Object?> get props => [userId, query, type, startDate, endDate];
}

/// ایجاد سند جدید
class CreateDocument extends DocumentEvent {
  final DocumentEntity document;
  
  const CreateDocument(this.document);
  
  @override
  List<Object?> get props => [document];
}

/// به‌روزرسانی سند
class UpdateDocument extends DocumentEvent {
  final DocumentEntity document;
  
  const UpdateDocument(this.document);
  
  @override
  List<Object?> get props => [document];
}

/// حذف سند
class DeleteDocument extends DocumentEvent {
  final String documentId;
  
  const DeleteDocument(this.documentId);
  
  @override
  List<Object?> get props => [documentId];
}

/// تبدیل پیش‌فاکتور به فاکتور
class ConvertToInvoice extends DocumentEvent {
  final String proformaId;
  
  const ConvertToInvoice(this.proformaId);
  
  @override
  List<Object?> get props => [proformaId];
}

/// دریافت یک سند
class LoadDocumentById extends DocumentEvent {
  final String documentId;
  
  const LoadDocumentById(this.documentId);
  
  @override
  List<Object?> get props => [documentId];
}
