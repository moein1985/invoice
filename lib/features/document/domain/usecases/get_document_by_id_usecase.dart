import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/document_entity.dart';
import '../repositories/document_repository.dart';

class GetDocumentByIdUseCase {
  final DocumentRepository repository;

  GetDocumentByIdUseCase(this.repository);

  Future<Either<Failure, DocumentEntity>> call(String documentId) async {
    if (documentId.isEmpty) {
      return const Left(ValidationFailure('شناسه سند نامعتبر است'));
    }

    return await repository.getDocumentById(documentId);
  }
}
