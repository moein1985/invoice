import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/enums/document_type.dart';
import '../repositories/document_repository.dart';

class GetNextDocumentNumberUseCase {
  final DocumentRepository repository;

  GetNextDocumentNumberUseCase(this.repository);

  Future<Either<Failure, String>> call(DocumentType type) async {
    return await repository.getNextDocumentNumber(type);
  }
}
