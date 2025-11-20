import 'package:equatable/equatable.dart';

class DocumentModel extends Equatable {
  final String id;
  final String userId;
  final String documentNumber;
  final String documentType;
  final String customerId;
  final DateTime documentDate;
  final double totalAmount;
  final double? discount;
  final double finalAmount;
  final String? status;
  final String? notes;
  final String? attachment;
  final double? defaultProfitPercentage;
  final String? convertedFromId;
  final String? approvalStatus;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? rejectionReason;
  final bool? requiresApproval;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const DocumentModel({
    required this.id,
    required this.userId,
    required this.documentNumber,
    required this.documentType,
    required this.customerId,
    required this.documentDate,
    required this.totalAmount,
    this.discount,
    required this.finalAmount,
    this.status,
    this.notes,
    this.attachment,
    this.defaultProfitPercentage,
    this.convertedFromId,
    this.approvalStatus,
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
    this.requiresApproval,
    this.createdAt,
    this.updatedAt,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id'],
      userId: json['userId'],
      documentNumber: json['documentNumber'],
      documentType: json['documentType'],
      customerId: json['customerId'],
      documentDate: json['documentDate'] != null ? DateTime.parse(json['documentDate']) : null ?? DateTime.now(),
      totalAmount: _parseDouble(json['totalAmount']) ?? 0.0,
      discount: _parseDouble(json['discount']),
      finalAmount: _parseDouble(json['finalAmount']) ?? 0.0,
      status: json['status'],
      notes: json['notes'],
      attachment: json['attachment'],
      defaultProfitPercentage: _parseDouble(json['defaultProfitPercentage']),
      convertedFromId: json['convertedFromId'],
      approvalStatus: json['approvalStatus'],
      approvedBy: json['approvedBy'],
      approvedAt: json['approvedAt'] != null ? DateTime.parse(json['approvedAt']) : null,
      rejectionReason: json['rejectionReason'],
      requiresApproval: _parseBool(json['requiresApproval']),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'documentNumber': documentNumber,
      'documentType': documentType,
      'customerId': customerId,
      'documentDate': documentDate.toIso8601String(),
      'totalAmount': totalAmount,
      'discount': discount,
      'finalAmount': finalAmount,
      'status': status,
      'notes': notes,
      'attachment': attachment,
      'defaultProfitPercentage': defaultProfitPercentage,
      'convertedFromId': convertedFromId,
      'approvalStatus': approvalStatus,
      'approvedBy': approvedBy,
      'approvedAt': approvedAt?.toIso8601String(),
      'rejectionReason': rejectionReason,
      'requiresApproval': requiresApproval,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  DocumentModel copyWith({
    String? id,
    String? userId,
    String? documentNumber,
    String? documentType,
    String? customerId,
    DateTime? documentDate,
    double? totalAmount,
    double? discount,
    double? finalAmount,
    String? status,
    String? notes,
    String? attachment,
    double? defaultProfitPercentage,
    String? convertedFromId,
    String? approvalStatus,
    String? approvedBy,
    DateTime? approvedAt,
    String? rejectionReason,
    bool? requiresApproval,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DocumentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      documentNumber: documentNumber ?? this.documentNumber,
      documentType: documentType ?? this.documentType,
      customerId: customerId ?? this.customerId,
      documentDate: documentDate ?? this.documentDate,
      totalAmount: totalAmount ?? this.totalAmount,
      discount: discount ?? this.discount,
      finalAmount: finalAmount ?? this.finalAmount,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      attachment: attachment ?? this.attachment,
      defaultProfitPercentage: defaultProfitPercentage ?? this.defaultProfitPercentage,
      convertedFromId: convertedFromId ?? this.convertedFromId,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      requiresApproval: requiresApproval ?? this.requiresApproval,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, userId, documentNumber, documentType, customerId, documentDate, totalAmount, discount, finalAmount, status, notes, attachment, defaultProfitPercentage, convertedFromId, approvalStatus, approvedBy, approvedAt, rejectionReason, requiresApproval, createdAt, updatedAt];

  // Helper methods for type conversion
  static bool? _parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return false;
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
