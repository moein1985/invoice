import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/enums/document_type.dart';
import '../entities/document_entity.dart';

abstract class DocumentRepository {
  /// ایجاد سند جدید
  Future<Either<Failure, DocumentEntity>> createDocument(DocumentEntity document);

  /// به‌روزرسانی سند
  Future<Either<Failure, DocumentEntity>> updateDocument(DocumentEntity document);

  /// حذف سند
  Future<Either<Failure, void>> deleteDocument(String documentId);

  /// دریافت تمام اسناد یک کاربر
  Future<Either<Failure, List<DocumentEntity>>> getDocuments(String userId);

  /// دریافت تمام اسناد (برای سرپرست)
  Future<Either<Failure, List<DocumentEntity>>> getAllDocuments();

  /// دریافت یک سند با ID
  Future<Either<Failure, DocumentEntity>> getDocumentById(String documentId);

  /// جستجوی اسناد
  Future<Either<Failure, List<DocumentEntity>>> searchDocuments({
    required String userId,
    String? query,
    DocumentType? type,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// تبدیل پیش‌فاکتور به فاکتور
  Future<Either<Failure, DocumentEntity>> convertProformaToInvoice(String proformaId);

  /// دریافت شماره سند بعدی
  Future<Either<Failure, String>> getNextDocumentNumber(DocumentType type);

  /// تأیید سند
  Future<Either<Failure, DocumentEntity>> approveDocument(String documentId, String approvedBy);

  /// رد سند
  Future<Either<Failure, DocumentEntity>> rejectDocument(String documentId, String rejectedBy, String reason);
}
