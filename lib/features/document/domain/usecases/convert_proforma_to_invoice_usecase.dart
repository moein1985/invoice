import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/document_entity.dart';
import '../repositories/document_repository.dart';

class ConvertProformaToInvoiceUseCase {
  final DocumentRepository repository;

  ConvertProformaToInvoiceUseCase(this.repository);

  Future<Either<Failure, DocumentEntity>> call(String proformaId) async {
    if (proformaId.isEmpty) {
      return const Left(ValidationFailure('شناسه پیش‌فاکتور نامعتبر است'));
    }

    return await repository.convertProformaToInvoice(proformaId);
  }
}
