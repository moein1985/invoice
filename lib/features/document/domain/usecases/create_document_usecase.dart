import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/document_entity.dart';
import '../repositories/document_repository.dart';

class CreateDocumentUseCase {
  final DocumentRepository repository;

  CreateDocumentUseCase(this.repository);

  Future<Either<Failure, DocumentEntity>> call(DocumentEntity document) async {
    // اعتبارسنجی
    if (document.items.isEmpty) {
      return const Left(ValidationFailure('حداقل یک ردیف باید وارد شود'));
    }

    if (document.finalAmount < 0) {
      return const Left(ValidationFailure('مبلغ نهایی نمی‌تواند منفی باشد'));
    }

    return await repository.createDocument(document);
  }
}
