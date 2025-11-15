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
        createdAt,
        updatedAt,
      ];

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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
