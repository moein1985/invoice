import 'package:dartz/dartz.dart';
import '../entities/document_entity.dart';
import '../repositories/document_repository.dart';
import '../../../../core/error/failures.dart';

class ApproveDocumentUseCase {
  final DocumentRepository repository;

  ApproveDocumentUseCase(this.repository);

  Future<Either<Failure, DocumentEntity>> call({
    required String documentId,
    required String approvedBy, // ID سرپرست
  }) async {
    return await repository.approveDocument(documentId, approvedBy);
  }
}