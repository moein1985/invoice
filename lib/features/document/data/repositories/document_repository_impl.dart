import 'package:dartz/dartz.dart';
import '../../../../core/enums/document_type.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/document_entity.dart';
import '../../domain/repositories/document_repository.dart';
import '../datasources/document_remote_datasource.dart';
import '../models/document_model.dart';

class DocumentRepositoryImpl implements DocumentRepository {  final DocumentRemoteDataSource remoteDataSource;

  DocumentRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, DocumentEntity>> createDocument(DocumentEntity document) async {
    try {
      final model = DocumentModel.fromEntity(document);
      try {
        final result = await remoteDataSource.createDocument(model);
        return Right(result.toEntity());
      } catch (_) {
        final result = await remoteDataSource.createDocument(model);
        return Right(result.toEntity());
      }
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('خطای غیرمنتظره: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, DocumentEntity>> updateDocument(DocumentEntity document) async {
    try {
      final model = DocumentModel.fromEntity(document);
      try {
        final result = await remoteDataSource.updateDocument(model);
        return Right(result.toEntity());
      } catch (_) {
        final result = await remoteDataSource.updateDocument(model);
        return Right(result.toEntity());
      }
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('خطای غیرمنتظره: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteDocument(String documentId) async {
    try {
      try {
        await remoteDataSource.deleteDocument(documentId);
      } catch (_) {
        await remoteDataSource.deleteDocument(documentId);
      }
      return const Right(null);
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('خطای غیرمنتظره: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<DocumentEntity>>> getDocuments(String userId) async {
    try {
      try {
        final documents = await remoteDataSource.getDocuments();
        return Right(documents.map((model) => model.toEntity()).toList());
      } catch (_) {
        final documents = await remoteDataSource.getDocuments(userId);
        return Right(documents.map((model) => model.toEntity()).toList());
      }
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('خطای غیرمنتظره: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<DocumentEntity>>> getAllDocuments() async {
    try {
      try {
        final documents = await remoteDataSource.getDocuments();
        return Right(documents.map((model) => model.toEntity()).toList());
      } catch (_) {
        final documents = await remoteDataSource.getAllDocuments();
        return Right(documents.map((model) => model.toEntity()).toList());
      }
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('خطای غیرمنتظره: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, DocumentEntity>> getDocumentById(String documentId) async {
    try {
      try {
        final document = await remoteDataSource.getDocumentById(documentId);
        return Right(document.toEntity());
      } catch (_) {
        final document = await remoteDataSource.getDocumentById(documentId);
        return Right(document.toEntity());
      }
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('خطای غیرمنتظره: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<DocumentEntity>>> searchDocuments({
    required String userId,
    String? query,
    DocumentType? type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      try {
        final all = await remoteDataSource.getDocuments();
        var results = all;
        if (type != null) {
          final t = type == DocumentType.invoice ? 'invoice' : (type == DocumentType.proforma ? 'proforma' : 'temp_proforma');
          results = results.where((d) => d.documentTypeString == t).toList();
        }
        if (startDate != null) {
          results = results.where((d) => !d.documentDate.isBefore(startDate)).toList();
        }
        if (endDate != null) {
          results = results.where((d) => !d.documentDate.isAfter(endDate)).toList();
        }
        if (query != null && query.isNotEmpty) {
          results = results.where((d) => d.documentNumber.contains(query) || (d.notes?.contains(query) ?? false)).toList();
        }
        return Right(results.map((m) => m.toEntity()).toList());
      } catch (_) {
        final typeString = type == null 
            ? null 
            : type == DocumentType.invoice ? 'invoice' : 'proforma';
        final documents = await remoteDataSource.searchDocuments(
          userId: userId,
          query: query,
          type: typeString,
          startDate: startDate,
          endDate: endDate,
        );
        return Right(documents.map((model) => model.toEntity()).toList());
      }
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('خطای غیرمنتظره: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, DocumentEntity>> convertProformaToInvoice(String proformaId) async {
    try {
      // فعلاً روی سرور نداریم؛ بازگشت به آفلاین
      final invoice = await remoteDataSource.convertProformaToInvoice(proformaId);
      return Right(invoice.toEntity());
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('خطای غیرمنتظره: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, String>> getNextDocumentNumber(DocumentType type) async {
    try {
      // روی سرور نداریم؛ محلی محاسبه می‌کنیم
      final typeString = type == DocumentType.invoice ? 'invoice' : 'proforma';
      final number = await remoteDataSource.getNextDocumentNumber(typeString);
      return Right(number);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('خطای غیرمنتظره: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, DocumentEntity>> approveDocument(String documentId, String approvedBy) async {
    try {
      try {
        final result = await remoteDataSource.approveDocument(documentId, approvedBy);
        return Right(result.toEntity());
      } catch (_) {
        // Fallback to local update
        final doc = await remoteDataSource.getDocumentById(documentId);
        final updated = DocumentModel(
          id: doc.id,
          userId: doc.userId,
          documentNumber: doc.documentNumber,
          documentTypeString: doc.documentTypeString,
          customerId: doc.customerId,
          documentDate: doc.documentDate,
          items: doc.items,
          totalAmount: doc.totalAmount,
          discount: doc.discount,
          finalAmount: doc.finalAmount,
          statusString: doc.statusString,
          notes: doc.notes,
          createdAt: doc.createdAt,
          updatedAt: DateTime.now(),
          attachment: doc.attachment,
          defaultProfitPercentage: doc.defaultProfitPercentage,
          convertedFromId: doc.convertedFromId,
          approvalStatus: 'approved',
          approvedBy: approvedBy,
          approvedAt: DateTime.now(),
          rejectionReason: null,
          requiresApproval: doc.requiresApproval,
        );
        final result = await remoteDataSource.updateDocument(updated);
        return Right(result.toEntity());
      }
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('خطای غیرمنتظره: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, DocumentEntity>> rejectDocument(String documentId, String rejectedBy, String reason) async {
    try {
      try {
        final result = await remoteDataSource.rejectDocument(documentId, rejectedBy, reason);
        return Right(result.toEntity());
      } catch (_) {
        // Fallback to local update
        final doc = await remoteDataSource.getDocumentById(documentId);
        final updated = DocumentModel(
          id: doc.id,
          userId: doc.userId,
          documentNumber: doc.documentNumber,
          documentTypeString: doc.documentTypeString,
          customerId: doc.customerId,
          documentDate: doc.documentDate,
          items: doc.items,
          totalAmount: doc.totalAmount,
          discount: doc.discount,
          finalAmount: doc.finalAmount,
          statusString: doc.statusString,
          notes: doc.notes,
          createdAt: doc.createdAt,
          updatedAt: DateTime.now(),
          attachment: doc.attachment,
          defaultProfitPercentage: doc.defaultProfitPercentage,
          convertedFromId: doc.convertedFromId,
          approvalStatus: 'rejected',
          approvedBy: rejectedBy,
          approvedAt: DateTime.now(),
          rejectionReason: reason,
          requiresApproval: doc.requiresApproval,
        );
        final result = await remoteDataSource.updateDocument(updated);
        return Right(result.toEntity());
      }
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('خطای غیرمنتظره: ${e.toString()}'));
    }
  }
}
