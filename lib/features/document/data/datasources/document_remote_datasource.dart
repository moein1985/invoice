import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/error/exceptions.dart';
import '../models/document_item_model.dart';
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
  final _uuid = const Uuid();
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

    DateTime parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      return DateTime.parse(v.toString());
    }

    final items = (json['items'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        .map((i) => DocumentItemModel(
              id: (i['id'] ?? _uuid.v4()).toString(),
              productName: i['product_name'] ?? i['productName'],
              quantity: (i['quantity'] as num).toInt(),
              unit: i['unit'],
              purchasePrice: ((i['purchase_price'] ?? i['purchasePrice']) as num).toDouble(),
              sellPrice: ((i['sell_price'] ?? i['sellPrice']) as num).toDouble(),
              totalPrice: ((i['total_price'] ?? i['totalPrice']) as num).toDouble(),
              profitPercentage: ((i['profit_percentage'] ?? i['profitPercentage']) as num).toDouble(),
              supplier: i['supplier'] ?? '',
              description: i['description'],
              isManualPrice: i['is_manual_price'] ?? i['isManualPrice'] ?? false,
            ))
        .toList();

    return DocumentModel(
      id: (json['id'] ?? '').toString(),
      userId: (json['user_id'] ?? json['userId'] ?? '').toString(),
      documentNumber: (json['document_number'] ?? json['documentNumber'] ?? '').toString(),
      documentTypeString: mapDocType(json['document_type'] ?? json['documentType'] ?? 'tempProforma'),
      customerId: (json['customer_id'] ?? json['customerId'] ?? '').toString(),
      documentDate: parseDate(json['document_date'] ?? json['documentDate']),
      items: items,
      totalAmount: ((json['total_amount'] ?? json['totalAmount'] ?? 0) as num).toDouble(),
      discount: ((json['discount'] ?? 0) as num).toDouble(),
      finalAmount: ((json['final_amount'] ?? json['finalAmount'] ?? 0) as num).toDouble(),
      statusString: (json['status'] ?? 'unpaid').toString(),
      notes: json['notes'] as String?,
      createdAt: parseDate(json['created_at'] ?? json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: parseDate(json['updated_at'] ?? json['updatedAt'] ?? json['created_at'] ?? json['createdAt'] ?? DateTime.now().toIso8601String()),
      attachment: json['attachment'] as String?,
      defaultProfitPercentage: ((json['default_profit_percentage'] ?? json['defaultProfitPercentage'] ?? 22) as num).toDouble(),
      convertedFromId: json['converted_from_id'] ?? json['convertedFromId'] as String?,
      approvalStatus: (json['approval_status'] ?? json['approvalStatus'] ?? 'notRequired').toString(),
      approvedBy: (json['approved_by'] ?? json['approvedBy'])?.toString(),
      approvedAt: (json['approved_at'] ?? json['approvedAt']) != null ? parseDate(json['approved_at'] ?? json['approvedAt']) : null,
      rejectionReason: (json['rejection_reason'] ?? json['rejectionReason'])?.toString(),
      requiresApproval: (json['requires_approval'] ?? json['requiresApproval'] ?? false) as bool,
    );
  }

  Map<String, dynamic> _toApi(DocumentModel d) {
    String mapDocTypeOut(String s) {
      switch (s) {
        case 'temp_proforma':
          return 'tempProforma';
        case 'proforma':
          return 'proforma';
        case 'invoice':
          return 'invoice';
        case 'return':
          return 'returnInvoice';
        default:
          return 'tempProforma';
      }
    }

    return {
      'documentNumber': d.documentNumber,
      'documentType': mapDocTypeOut(d.documentTypeString),
      'customerId': d.customerId,
      'documentDate': d.documentDate.toIso8601String(),
      'items': d.items.map((i) => i.toJson()).toList(),
      'totalAmount': d.totalAmount,
      'discount': d.discount,
      'finalAmount': d.finalAmount,
      'status': d.statusString,
      'notes': d.notes,
      'attachment': d.attachment,
      'defaultProfitPercentage': d.defaultProfitPercentage,
      'convertedFromId': d.convertedFromId,
      'approvalStatus': d.approvalStatus,
      'approvedBy': d.approvedBy,
      'approvedAt': d.approvedAt?.toIso8601String(),
      'rejectionReason': d.rejectionReason,
      'requiresApproval': d.requiresApproval,
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
        'status': document.statusString,
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
      final list = (res.data as List).cast<Map<String, dynamic>>();
      return list.map(_fromApi).toList();
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
