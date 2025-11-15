import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/document_entity.dart';
import '../repositories/document_repository.dart';

class GetDocumentsUseCase {
  final DocumentRepository repository;

  GetDocumentsUseCase(this.repository);

  Future<Either<Failure, List<DocumentEntity>>> call(String userId) async {
    if (userId.isEmpty) {
      return const Left(ValidationFailure('شناسه کاربر نامعتبر است'));
    }

    return await repository.getDocuments(userId);
  }
}
