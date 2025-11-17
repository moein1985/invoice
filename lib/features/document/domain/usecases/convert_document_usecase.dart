import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/enums/document_type.dart';
import '../entities/document_entity.dart';
import '../repositories/document_repository.dart';
import 'get_next_document_number_usecase.dart';

class ConvertDocumentUseCase {
  final DocumentRepository repository;
  final GetNextDocumentNumberUseCase getNextNumberUseCase;

  ConvertDocumentUseCase(this.repository, this.getNextNumberUseCase);

  Future<Either<Failure, DocumentEntity>> call(DocumentEntity document) async {
    final nextType = document.documentType.nextType;
    
    if (nextType == null) {
      return const Left(ValidationFailure('این نوع سند قابل تبدیل نیست'));
    }

    try {
      // بررسی اینکه قبلا تبدیل شده یا نه (آیا سند دیگری با convertedFromId این سند وجود دارد)
      final allDocsResult = await repository.getDocuments(document.userId);
      final alreadyExists = allDocsResult.fold(
        (_) => false,
        (docs) => docs.any((d) => 
          d.convertedFromId == document.id
        ),
      );
      
      if (alreadyExists) {
        return const Left(ValidationFailure('این سند قبلاً تبدیل شده است'));
      }

      // تولید شماره جدید فقط برای تبدیل به Invoice
      String newNumber = document.documentNumber;
      if (nextType == DocumentType.invoice) {
        final numberResult = await getNextNumberUseCase(nextType);
        newNumber = numberResult.fold(
          (failure) => throw failure,
          (number) => number,
        );
      }

      // ایجاد سند جدید
      final convertedDocument = DocumentEntity(
        id: const Uuid().v4(), // ID جدید
        userId: document.userId,
        documentNumber: newNumber,
        documentType: nextType,
        customerId: document.customerId,
        documentDate: DateTime.now(), // تاریخ جدید
        items: document.items,
        totalAmount: document.totalAmount,
        discount: document.discount,
        finalAmount: document.finalAmount,
        status: document.status,
        notes: document.notes,
        attachment: document.attachment,
        defaultProfitPercentage: document.defaultProfitPercentage,
        convertedFromId: document.id, // ثبت ID سند منبع
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // ذخیره سند جدید
      return await repository.createDocument(convertedDocument);
    } catch (e) {
      return Left(ServerFailure('خطا در تبدیل سند: $e'));
    }
  }
}
