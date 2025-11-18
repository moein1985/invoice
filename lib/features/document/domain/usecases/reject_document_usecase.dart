import 'package:dartz/dartz.dart';
import '../entities/document_entity.dart';
import '../repositories/document_repository.dart';
import '../../../../core/error/failures.dart';

class RejectDocumentUseCase {
  final DocumentRepository repository;

  RejectDocumentUseCase(this.repository);

  Future<Either<Failure, DocumentEntity>> call({
    required String documentId,
    required String rejectedBy,
    required String reason,
  }) async {
    return await repository.rejectDocument(documentId, rejectedBy, reason);
  }
}