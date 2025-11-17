import 'package:hive/hive.dart';
import '../../../../core/enums/document_type.dart';
import '../../../../core/enums/document_status.dart';
import '../../../../core/enums/approval_status.dart';
import '../../domain/entities/document_entity.dart';
import 'document_item_model.dart';

part 'document_model.g.dart';

@HiveType(typeId: 3)
class DocumentModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String documentNumber;

  @HiveField(3)
  final String documentTypeString; // 'invoice' or 'proforma'

  @HiveField(4)
  final String customerId;

  @HiveField(5)
  final DateTime documentDate;

  @HiveField(6)
  final List<DocumentItemModel> items;

  @HiveField(7)
  final double totalAmount;

  @HiveField(8)
  final double discount;

  @HiveField(9)
  final double finalAmount;

  @HiveField(10)
  final String statusString; // 'paid', 'unpaid', 'pending'

  @HiveField(11)
  final String? notes;

  @HiveField(12)
  final DateTime createdAt;

  @HiveField(13)
  final DateTime updatedAt;

  @HiveField(14)
  final String? attachment;

  @HiveField(15)
  final double defaultProfitPercentage;

  @HiveField(16)
  final String? convertedFromId;

  @HiveField(17)
  final String approvalStatus;

  @HiveField(18)
  final String? approvedBy;

  @HiveField(19)
  final DateTime? approvedAt;

  @HiveField(20)
  final String? rejectionReason;

  @HiveField(21)
  final bool requiresApproval;

  const DocumentModel({
    required this.id,
    required this.userId,
    required this.documentNumber,
    required this.documentTypeString,
    required this.customerId,
    required this.documentDate,
    required this.items,
    required this.totalAmount,
    required this.discount,
    required this.finalAmount,
    required this.statusString,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.attachment,
    this.defaultProfitPercentage = 22.0,
    this.convertedFromId,
    required this.approvalStatus,
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
    this.requiresApproval = false,
  });

  static DocumentType _parseDocumentType(String type) {
    switch (type) {
      case 'temp_proforma':
        return DocumentType.tempProforma;
      case 'proforma':
        return DocumentType.proforma;
      case 'invoice':
        return DocumentType.invoice;
      case 'return':
        return DocumentType.returnInvoice;
      default:
        return DocumentType.tempProforma;
    }
  }

  static String _documentTypeToString(DocumentType type) {
    switch (type) {
      case DocumentType.tempProforma:
        return 'temp_proforma';
      case DocumentType.proforma:
        return 'proforma';
      case DocumentType.invoice:
        return 'invoice';
      case DocumentType.returnInvoice:
        return 'return';
    }
  }

  static DocumentStatus _parseDocumentStatus(String status) {
    switch (status) {
      case 'paid':
        return DocumentStatus.paid;
      case 'unpaid':
        return DocumentStatus.unpaid;
      default:
        return DocumentStatus.pending;
    }
  }

  factory DocumentModel.fromEntity(DocumentEntity entity) {
    return DocumentModel(
      id: entity.id,
      userId: entity.userId,
      documentNumber: entity.documentNumber,
      documentTypeString: _documentTypeToString(entity.documentType),
      customerId: entity.customerId,
      documentDate: entity.documentDate,
      items: entity.items.map((item) => DocumentItemModel.fromEntity(item)).toList(),
      totalAmount: entity.totalAmount,
      discount: entity.discount,
      finalAmount: entity.finalAmount,
      statusString: entity.status == DocumentStatus.paid
          ? 'paid'
          : entity.status == DocumentStatus.unpaid
              ? 'unpaid'
              : 'pending',
      notes: entity.notes,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      attachment: entity.attachment,
      defaultProfitPercentage: entity.defaultProfitPercentage,
      convertedFromId: entity.convertedFromId,
      approvalStatus: entity.approvalStatus.name,
      approvedBy: entity.approvedBy,
      approvedAt: entity.approvedAt,
      rejectionReason: entity.rejectionReason,
      requiresApproval: entity.requiresApproval,
    );
  }

  DocumentEntity toEntity() {
    return DocumentEntity(
      id: id,
      userId: userId,
      documentNumber: documentNumber,
      documentType: _parseDocumentType(documentTypeString),
      customerId: customerId,
      documentDate: documentDate,
      items: items.map((item) => item.toEntity()).toList(),
      totalAmount: totalAmount,
      discount: discount,
      finalAmount: finalAmount,
      attachment: attachment,
      defaultProfitPercentage: defaultProfitPercentage,
      convertedFromId: convertedFromId,
      status: _parseDocumentStatus(statusString),
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
      approvalStatus: ApprovalStatus.values.byName(approvalStatus),
      approvedBy: approvedBy,
      approvedAt: approvedAt,
      rejectionReason: rejectionReason,
      requiresApproval: requiresApproval,
    );
  }
}
