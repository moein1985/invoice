import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/hive_boxes.dart';
import '../../../../core/error/exceptions.dart';
import '../models/document_model.dart';

abstract class DocumentLocalDataSource {
  Future<DocumentModel> createDocument(DocumentModel document);
  Future<DocumentModel> updateDocument(DocumentModel document);
  Future<void> deleteDocument(String documentId);
  Future<List<DocumentModel>> getDocuments(String userId);
  Future<DocumentModel> getDocumentById(String documentId);
  Future<List<DocumentModel>> searchDocuments({
    required String userId,
    String? query,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
  });
  Future<DocumentModel> convertProformaToInvoice(String proformaId);
  Future<String> getNextDocumentNumber(String type);
}

class DocumentLocalDataSourceImpl implements DocumentLocalDataSource {
  final _uuid = const Uuid();

  Box<DocumentModel> get _box => Hive.box<DocumentModel>(HiveBoxes.documents);

  @override
  Future<DocumentModel> createDocument(DocumentModel document) async {
    try {
      await _box.put(document.id, document);
      return document;
    } catch (e) {
      throw CacheException('خطا در ذخیره سند: ${e.toString()}');
    }
  }

  @override
  Future<DocumentModel> updateDocument(DocumentModel document) async {
    try {
      if (!_box.containsKey(document.id)) {
        throw NotFoundException('سند یافت نشد');
      }
      await _box.put(document.id, document);
      return document;
    } catch (e) {
      if (e is NotFoundException) rethrow;
      throw CacheException('خطا در به‌روزرسانی سند: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteDocument(String documentId) async {
    try {
      if (!_box.containsKey(documentId)) {
        throw NotFoundException('سند یافت نشد');
      }
      await _box.delete(documentId);
    } catch (e) {
      if (e is NotFoundException) rethrow;
      throw CacheException('خطا در حذف سند: ${e.toString()}');
    }
  }

  @override
  Future<List<DocumentModel>> getDocuments(String userId) async {
    try {
      final documents = _box.values.where((doc) => doc.userId == userId).toList();
      // مرتب‌سازی بر اساس تاریخ (جدیدترین اول)
      documents.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return documents;
    } catch (e) {
      throw CacheException('خطا در دریافت اسناد: ${e.toString()}');
    }
  }

  @override
  Future<DocumentModel> getDocumentById(String documentId) async {
    try {
      final document = _box.get(documentId);
      if (document == null) {
        throw NotFoundException('سند یافت نشد');
      }
      return document;
    } catch (e) {
      if (e is NotFoundException) rethrow;
      throw CacheException('خطا در دریافت سند: ${e.toString()}');
    }
  }

  @override
  Future<List<DocumentModel>> searchDocuments({
    required String userId,
    String? query,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var results = _box.values.where((doc) => doc.userId == userId);

      // فیلتر نوع سند
      if (type != null) {
        results = results.where((doc) => doc.documentTypeString == type);
      }

      // فیلتر بازه زمانی
      if (startDate != null) {
        results = results.where((doc) => doc.documentDate.isAfter(startDate) || 
                                         doc.documentDate.isAtSameMomentAs(startDate));
      }
      if (endDate != null) {
        results = results.where((doc) => doc.documentDate.isBefore(endDate) || 
                                         doc.documentDate.isAtSameMomentAs(endDate));
      }

      // جستجوی متنی
      if (query != null && query.isNotEmpty) {
        results = results.where((doc) {
          return doc.documentNumber.contains(query) ||
                 (doc.notes?.contains(query) ?? false) ||
                 doc.items.any((item) => 
                   item.productName.contains(query) ||
                   item.supplier.contains(query) ||
                   (item.description?.contains(query) ?? false)
                 );
        });
      }

      final list = results.toList();
      // مرتب‌سازی بر اساس تاریخ (جدیدترین اول)
      list.sort((a, b) => b.documentDate.compareTo(a.documentDate));
      return list;
    } catch (e) {
      throw CacheException('خطا در جستجوی اسناد: ${e.toString()}');
    }
  }

  @override
  Future<DocumentModel> convertProformaToInvoice(String proformaId) async {
    try {
      final proforma = await getDocumentById(proformaId);
      
      if (proforma.documentTypeString != 'proforma') {
        throw ValidationException('فقط پیش‌فاکتور قابل تبدیل به فاکتور است');
      }

      // دریافت شماره فاکتور جدید
      final invoiceNumber = await getNextDocumentNumber('invoice');

      // ایجاد فاکتور جدید
      final invoice = DocumentModel(
        id: _uuid.v4(),
        userId: proforma.userId,
        documentNumber: invoiceNumber,
        documentTypeString: 'invoice',
        customerId: proforma.customerId,
        documentDate: DateTime.now(),
        items: proforma.items,
        totalAmount: proforma.totalAmount,
        discount: proforma.discount,
        finalAmount: proforma.finalAmount,
        statusString: 'unpaid',
        notes: proforma.notes,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await createDocument(invoice);
      return invoice;
    } catch (e) {
      if (e is NotFoundException || e is ValidationException) rethrow;
      throw CacheException('خطا در تبدیل پیش‌فاکتور به فاکتور: ${e.toString()}');
    }
  }

  @override
  Future<String> getNextDocumentNumber(String type) async {
    try {
      final prefix = type == 'invoice' ? 'INV' : 'PRO';
      
      // یافتن آخرین شماره
      final documents = _box.values
          .where((doc) => doc.documentTypeString == type)
          .toList();
      
      if (documents.isEmpty) {
        return '$prefix-1001';
      }

      // استخراج شماره‌ها و یافتن بزرگترین
      final numbers = documents
          .map((doc) => int.tryParse(doc.documentNumber.split('-').last) ?? 0)
          .toList();
      
      final maxNumber = numbers.reduce((a, b) => a > b ? a : b);
      return '$prefix-${maxNumber + 1}';
    } catch (e) {
      throw CacheException('خطا در تولید شماره سند: ${e.toString()}');
    }
  }
}
