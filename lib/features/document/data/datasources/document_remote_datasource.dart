import 'package:dio/dio.dart';
import '../../../../core/error/exceptions.dart';
import '../models/document_model.dart';

abstract class DocumentRemoteDataSource {
  Future<DocumentModel> createDocument(DocumentModel document);
  Future<DocumentModel> updateDocument(DocumentModel document);
  Future<void> deleteDocument(String documentId);
  Future<List<DocumentModel>> getDocuments();
  Future<DocumentModel> getDocumentById(String documentId);
  Future<DocumentModel> approveDocument(String documentId, String approvedBy);
  Future<DocumentModel> rejectDocument(String documentId, String rejectedBy, String reason);
}

class DocumentRemoteDataSourceImpl implements DocumentRemoteDataSource {
  final Dio dio;
  DocumentRemoteDataSourceImpl({required this.dio});

  DocumentModel _fromApi(Map<String, dynamic> json) {
    String mapDocType(String s) {
      switch (s) {
        case 'tempProforma':
          return 'temp_proforma';
        case 'proforma':
          return 'proforma';
        case 'invoice':
          return 'invoice';
        case 'returnInvoice':
          return 'return';
        default:
          return 'temp_proforma';
      }
    }

    // نرمال‌سازی key ها برای fromJson
    final normalizedJson = {
      'id': (json['id'] ?? '').toString(),
      'userId': (json['user_id'] ?? json['userId'] ?? '').toString(),
      'documentNumber': (json['document_number'] ?? json['documentNumber'] ?? '').toString(),
      'documentType': mapDocType(json['document_type'] ?? json['documentType'] ?? 'tempProforma'),
      'customerId': (json['customer_id'] ?? json['customerId'] ?? '').toString(),
      'documentDate': (json['document_date'] ?? json['documentDate'] ?? DateTime.now().toIso8601String()),
      'totalAmount': (json['total_amount'] ?? json['totalAmount'] ?? 0),
      'discount': (json['discount'] ?? 0),
      'finalAmount': (json['final_amount'] ?? json['finalAmount'] ?? 0),
      'status': (json['status'] ?? 'unpaid'),
      'notes': json['notes'],
      'createdAt': (json['created_at'] ?? json['createdAt'] ?? DateTime.now().toIso8601String()),
      'updatedAt': (json['updated_at'] ?? json['updatedAt'] ?? json['created_at'] ?? json['createdAt'] ?? DateTime.now().toIso8601String()),
      'attachment': json['attachment'],
      'defaultProfitPercentage': (json['default_profit_percentage'] ?? json['defaultProfitPercentage'] ?? 22),
      'convertedFromId': (json['converted_from_id'] ?? json['convertedFromId']),
      'approvalStatus': (json['approval_status'] ?? json['approvalStatus'] ?? 'pending'),
      'approvedBy': (json['approved_by'] ?? json['approvedBy']),
      'approvedAt': (json['approved_at'] ?? json['approvedAt']),
      'rejectionReason': (json['rejection_reason'] ?? json['rejectionReason']),
      'requiresApproval': (json['requires_approval'] ?? json['requiresApproval'] ?? false),
    };
    return DocumentModel.fromJson(normalizedJson);
  }

  Map<String, dynamic> _toApi(DocumentModel d) {
    // استفاده از toJson و فقط نرمال‌سازی key ها برای API
    final json = d.toJson();
    return {
      'documentNumber': json['documentNumber'],
      'documentType': json['documentType'],
      'customerId': json['customerId'],
      'documentDate': json['documentDate'],
      // items جداگانه مدیریت می‌شوند، اینجا نمی‌فرستیم
      'totalAmount': json['totalAmount'],
      'discount': json['discount'],
      'finalAmount': json['finalAmount'],
      'status': json['status'],
      'notes': json['notes'],
      'attachment': json['attachment'],
      'defaultProfitPercentage': json['defaultProfitPercentage'],
      'convertedFromId': json['convertedFromId'],
      'approvalStatus': json['approvalStatus'],
      'approvedBy': json['approvedBy'],
      'approvedAt': json['approvedAt'],
      'rejectionReason': json['rejectionReason'],
      'requiresApproval': json['requiresApproval'],
    };
  }

  @override
  Future<DocumentModel> createDocument(DocumentModel document) async {
    try {
      final res = await dio.post('/api/documents', data: _toApi(document));
      return _fromApi(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final msg = e.response?.data is Map && (e.response?.data['error'] != null)
          ? e.response?.data['error']
          : 'خطا در ایجاد سند';
      throw CacheException(msg.toString());
    }
  }

  @override
  Future<DocumentModel> updateDocument(DocumentModel document) async {
    try {
      final payload = {
        'status': document.status,
        'notes': document.notes,
        'approvalStatus': document.approvalStatus,
        'approvedBy': document.approvedBy,
        'approvedAt': document.approvedAt?.toIso8601String(),
        'rejectionReason': document.rejectionReason,
        'requiresApproval': document.requiresApproval,
      };
      final res = await dio.put('/api/documents/${document.id}', data: payload);
      return _fromApi(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw NotFoundException('سند یافت نشد');
      }
      throw CacheException('خطا در بروزرسانی سند');
    }
  }

  @override
  Future<void> deleteDocument(String documentId) async {
    try {
      await dio.delete('/api/documents/$documentId');
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw NotFoundException('سند یافت نشد');
      }
      throw CacheException('خطا در حذف سند');
    }
  }

  @override
  Future<DocumentModel> getDocumentById(String documentId) async {
    try {
      final res = await dio.get('/api/documents/$documentId');
      return _fromApi(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw NotFoundException('سند یافت نشد');
      }
      throw CacheException('سند یافت نشد');
    }
  }

  @override
  Future<List<DocumentModel>> getDocuments() async {
    try {
      final res = await dio.get('/api/documents');
      // چک کردن آیا response یک array است یا object
      if (res.data is List) {
        final list = (res.data as List).cast<Map<String, dynamic>>();
        return list.map(_fromApi).toList();
      } else if (res.data is Map) {
        // اگر object باشد، لیست خالی برمی‌گردانیم
        return [];
      }
      return [];
    } on DioException {
      throw CacheException('خطا در دریافت اسناد');
    }
  }

  @override
  Future<DocumentModel> approveDocument(String documentId, String approvedBy) async {
    try {
      final res = await dio.post('/api/documents/$documentId/approve', data: {
        'approvedBy': approvedBy,
      });
      return _fromApi(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw NotFoundException('سند یافت نشد');
      }
      throw CacheException('خطا در تأیید سند');
    }
  }

  @override
  Future<DocumentModel> rejectDocument(String documentId, String rejectedBy, String reason) async {
    try {
      final res = await dio.post('/api/documents/$documentId/reject', data: {
        'rejectedBy': rejectedBy,
        'reason': reason,
      });
      return _fromApi(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw NotFoundException('سند یافت نشد');
      }
      throw CacheException('خطا در رد سند');
    }
  }
}
