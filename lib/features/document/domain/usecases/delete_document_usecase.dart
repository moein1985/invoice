import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/document_repository.dart';

class DeleteDocumentUseCase {
  final DocumentRepository repository;

  DeleteDocumentUseCase(this.repository);

  Future<Either<Failure, void>> call(String documentId) async {
    if (documentId.isEmpty) {
      return const Left(ValidationFailure('شناسه سند نامعتبر است'));
    }

    return await repository.deleteDocument(documentId);
  }
}
