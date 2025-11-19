import '../../../../core/enums/document_type.dart';
import '../../../../core/enums/document_status.dart';
import '../../../../core/enums/approval_status.dart';
import '../../domain/entities/document_entity.dart';
import 'document_item_model.dart';


class DocumentModel {
  final String id;
  final String userId;
  final String documentNumber;
  final String documentTypeString; // 'invoice' or 'proforma'
  final String customerId;
  final DateTime documentDate;
  final List<DocumentItemModel> items;
  final double totalAmount;
  final double discount;
  final double finalAmount;
  final String statusString; // 'paid', 'unpaid', 'pending'
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? attachment;
  final double defaultProfitPercentage;
  final String? convertedFromId;
  final String approvalStatus;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? rejectionReason;
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
