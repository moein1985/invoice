import 'package:dartz/dartz.dart';
import '../entities/document_entity.dart';
import '../repositories/document_repository.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/enums/approval_status.dart';

class ApproveDocumentUseCase {
  final DocumentRepository repository;

  ApproveDocumentUseCase(this.repository);

  Future<Either<Failure, DocumentEntity>> call({
    required String documentId,
    required String approvedBy, // ID سرپرست
  }) async {
    try {
      final documentResult = await repository.getDocumentById(documentId);
      
      return documentResult.fold(
        (failure) => Left(failure),
        (document) async {
          // تأیید سند
          final updatedDocument = document.copyWith(
            approvalStatus: ApprovalStatus.approved,
            approvedBy: approvedBy,
            approvedAt: DateTime.now(),
            rejectionReason: null,
          );
          
          return await repository.updateDocument(updatedDocument);
        },
      );
    } catch (e) {
      return Left(CacheFailure('خطا در تأیید سند'));
    }
  }
}