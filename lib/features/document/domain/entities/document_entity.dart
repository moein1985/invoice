import 'package:equatable/equatable.dart';
import '../../../../core/enums/document_type.dart';
import '../../../../core/enums/document_status.dart';
import 'document_item_entity.dart';

class DocumentEntity extends Equatable {
  final String id;
  final String userId;
  final String documentNumber;
  final DocumentType documentType;
  final String customerId;
  final DateTime documentDate;
  final List<DocumentItemEntity> items;
  final double totalAmount;
  final double discount;
  final double finalAmount;
  final DocumentStatus status;
  final String? notes;
  final String? attachment; // پیوست
  final double defaultProfitPercentage; // درصد سود پیش‌فرض
  final String? convertedFromId; // ID سند منبع که این سند از آن تبدیل شده
  final DateTime createdAt;
  final DateTime updatedAt;

  const DocumentEntity({
    required this.id,
    required this.userId,
    required this.documentNumber,
    required this.documentType,
    required this.customerId,
    required this.documentDate,
    required this.items,
    required this.totalAmount,
    required this.discount,
    required this.finalAmount,
    required this.status,
    this.notes,
    this.attachment,
    this.defaultProfitPercentage = 22.0, // پیش‌فرض 22%
    this.convertedFromId,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        documentNumber,
        documentType,
        customerId,
        documentDate,
        items,
        totalAmount,
        discount,
        finalAmount,
        status,
        notes,
        attachment,
        defaultProfitPercentage,
        convertedFromId,
        createdAt,
        updatedAt,
      ];

  /// محاسبه جمع کل خرید
  double get totalPurchaseAmount {
    return items.fold(0.0, (sum, item) => sum + item.totalPurchasePrice);
  }

  /// محاسبه جمع سود
  double get totalProfitAmount {
    return items.fold(0.0, (sum, item) => sum + item.profitAmount);
  }

  DocumentEntity copyWith({
    String? id,
    String? userId,
    String? documentNumber,
    DocumentType? documentType,
    String? customerId,
    DateTime? documentDate,
    List<DocumentItemEntity>? items,
    double? totalAmount,
    double? discount,
    double? finalAmount,
    DocumentStatus? status,
    String? notes,
    String? attachment,
    double? defaultProfitPercentage,
    String? convertedFromId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DocumentEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      documentNumber: documentNumber ?? this.documentNumber,
      documentType: documentType ?? this.documentType,
      customerId: customerId ?? this.customerId,
      documentDate: documentDate ?? this.documentDate,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      discount: discount ?? this.discount,
      finalAmount: finalAmount ?? this.finalAmount,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      attachment: attachment ?? this.attachment,
      defaultProfitPercentage: defaultProfitPercentage ?? this.defaultProfitPercentage,
      convertedFromId: convertedFromId ?? this.convertedFromId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'documentNumber': documentNumber,
      'documentType': () {
        switch (documentType) {
          case DocumentType.tempProforma:
            return 'tempProforma';
          case DocumentType.proforma:
            return 'proforma';
          case DocumentType.invoice:
            return 'invoice';
          case DocumentType.returnInvoice:
            return 'returnInvoice';
        }
      }(),
      'customerId': customerId,
      'documentDate': documentDate.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
      'totalAmount': totalAmount,
      'discount': discount,
      'finalAmount': finalAmount,
      'status': status == DocumentStatus.paid
          ? 'paid'
          : status == DocumentStatus.unpaid
              ? 'unpaid'
              : 'pending',
      'notes': notes,
      'attachment': attachment,
      'defaultProfitPercentage': defaultProfitPercentage,
      'convertedFromId': convertedFromId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory DocumentEntity.fromJson(Map<String, dynamic> json) {
    return DocumentEntity(
      id: json['id'] as String,
      userId: json['userId'] as String,
      documentNumber: json['documentNumber'] as String,
      documentType: () {
        final t = json['documentType'] as String;
        switch (t) {
          case 'tempProforma':
            return DocumentType.tempProforma;
          case 'proforma':
            return DocumentType.proforma;
          case 'invoice':
            return DocumentType.invoice;
          case 'returnInvoice':
            return DocumentType.returnInvoice;
          default:
            return DocumentType.proforma; // fallback
        }
      }(),
      customerId: json['customerId'] as String,
      documentDate: DateTime.parse(json['documentDate'] as String),
      items: (json['items'] as List).map((item) => DocumentItemEntity.fromJson(item as Map<String, dynamic>)).toList(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      discount: (json['discount'] as num).toDouble(),
      finalAmount: (json['finalAmount'] as num).toDouble(),
      status: json['status'] == 'paid'
          ? DocumentStatus.paid
          : json['status'] == 'unpaid'
              ? DocumentStatus.unpaid
              : DocumentStatus.pending,
      notes: json['notes'] as String?,
      attachment: json['attachment'] as String?,
      defaultProfitPercentage: (json['defaultProfitPercentage'] as num?)?.toDouble() ?? 22.0,
      convertedFromId: json['convertedFromId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
