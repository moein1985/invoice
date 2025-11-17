import 'package:dartz/dartz.dart';
import '../entities/document_entity.dart';
import '../repositories/document_repository.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/enums/approval_status.dart';

class RequestApprovalUseCase {
  final DocumentRepository repository;

  RequestApprovalUseCase(this.repository);

  Future<Either<Failure, DocumentEntity>> call({
    required String documentId,
  }) async {
    try {
      // بارگذاری سند
      final documentResult = await repository.getDocumentById(documentId);
      
      return documentResult.fold(
        (failure) => Left(failure),
        (document) async {
          // تغییر وضعیت به pending
          final updatedDocument = document.copyWith(
            approvalStatus: ApprovalStatus.pending,
            requiresApproval: true,
          );
          
          // ذخیره
          return await repository.updateDocument(updatedDocument);
        },
      );
    } catch (e) {
      return Left(CacheFailure('خطا در درخواست تأیید'));
    }
  }
}