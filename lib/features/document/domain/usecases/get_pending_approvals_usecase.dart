import 'package:dartz/dartz.dart';
import '../entities/document_entity.dart';
import '../repositories/document_repository.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/enums/approval_status.dart';
import '../../../../core/enums/document_type.dart';

class GetPendingApprovalsUseCase {
  final DocumentRepository repository;

  GetPendingApprovalsUseCase(this.repository);

  Future<Either<Failure, List<DocumentEntity>>> call() async {
    try {
      final allDocsResult = await repository.getAllDocuments();
      
      return allDocsResult.fold(
        (failure) => Left(failure),
        (documents) {
          // فیلتر اسناد منتظر تأیید
          final pendingDocs = documents.where((doc) {
            return doc.documentType == DocumentType.tempProforma &&
                   doc.approvalStatus == ApprovalStatus.pending;
          }).toList();
          
          // مرتب‌سازی بر اساس تاریخ (جدیدترین اول)
          pendingDocs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          
          return Right(pendingDocs);
        },
      );
    } catch (e) {
      return Left(CacheFailure('خطا در دریافت اسناد منتظر تأیید'));
    }
  }
}