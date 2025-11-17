import 'package:dartz/dartz.dart';
import '../../../../core/enums/document_type.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/document_entity.dart';
import '../../domain/repositories/document_repository.dart';
import '../datasources/document_local_datasource.dart';
import '../models/document_model.dart';

class DocumentRepositoryImpl implements DocumentRepository {
  final DocumentLocalDataSource localDataSource;

  DocumentRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, DocumentEntity>> createDocument(DocumentEntity document) async {
    try {
      final model = DocumentModel.fromEntity(document);
      final result = await localDataSource.createDocument(model);
      return Right(result.toEntity());
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
      final result = await localDataSource.updateDocument(model);
      return Right(result.toEntity());
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
      await localDataSource.deleteDocument(documentId);
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
      final documents = await localDataSource.getDocuments(userId);
      return Right(documents.map((model) => model.toEntity()).toList());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('خطای غیرمنتظره: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<DocumentEntity>>> getAllDocuments() async {
    try {
      final documents = await localDataSource.getAllDocuments();
      return Right(documents.map((model) => model.toEntity()).toList());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('خطای غیرمنتظره: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, DocumentEntity>> getDocumentById(String documentId) async {
    try {
      final document = await localDataSource.getDocumentById(documentId);
      return Right(document.toEntity());
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
      final typeString = type == null 
          ? null 
          : type == DocumentType.invoice ? 'invoice' : 'proforma';
          
      final documents = await localDataSource.searchDocuments(
        userId: userId,
        query: query,
        type: typeString,
        startDate: startDate,
        endDate: endDate,
      );
      return Right(documents.map((model) => model.toEntity()).toList());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('خطای غیرمنتظره: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, DocumentEntity>> convertProformaToInvoice(String proformaId) async {
    try {
      final invoice = await localDataSource.convertProformaToInvoice(proformaId);
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
      final typeString = type == DocumentType.invoice ? 'invoice' : 'proforma';
      final number = await localDataSource.getNextDocumentNumber(typeString);
      return Right(number);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('خطای غیرمنتظره: ${e.toString()}'));
    }
  }
}
