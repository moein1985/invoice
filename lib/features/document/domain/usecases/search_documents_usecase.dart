import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/enums/document_type.dart';
import '../entities/document_entity.dart';
import '../repositories/document_repository.dart';

class SearchDocumentsUseCase {
  final DocumentRepository repository;

  SearchDocumentsUseCase(this.repository);

  Future<Either<Failure, List<DocumentEntity>>> call({
    required String userId,
    String? query,
    DocumentType? type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (userId.isEmpty) {
      return const Left(ValidationFailure('شناسه کاربر نامعتبر است'));
    }

    return await repository.searchDocuments(
      userId: userId,
      query: query,
      type: type,
      startDate: startDate,
      endDate: endDate,
    );
  }
}
