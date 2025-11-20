import 'package:equatable/equatable.dart';

class DocumentItemModel extends Equatable {
  final String id;
  final String documentId;
  final String productName;
  final double quantity;
  final String unit;
  final double purchasePrice;
  final double sellPrice;
  final double totalPrice;
  final double profitPercentage;
  final String? supplier;
  final DateTime? createdAt;

  const DocumentItemModel({
    required this.id,
    required this.documentId,
    required this.productName,
    required this.quantity,
    required this.unit,
    required this.purchasePrice,
    required this.sellPrice,
    required this.totalPrice,
    required this.profitPercentage,
    this.supplier,
    this.createdAt,
  });

  factory DocumentItemModel.fromJson(Map<String, dynamic> json) {
    return DocumentItemModel(
      id: json['id'],
      documentId: json['documentId'],
      productName: json['productName'],
      quantity: _parseDouble(json['quantity']) ?? 0.0,
      unit: json['unit'],
      purchasePrice: _parseDouble(json['purchasePrice']) ?? 0.0,
      sellPrice: _parseDouble(json['sellPrice']) ?? 0.0,
      totalPrice: _parseDouble(json['totalPrice']) ?? 0.0,
      profitPercentage: _parseDouble(json['profitPercentage']) ?? 0.0,
      supplier: json['supplier'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'documentId': documentId,
      'productName': productName,
      'quantity': quantity,
      'unit': unit,
      'purchasePrice': purchasePrice,
      'sellPrice': sellPrice,
      'totalPrice': totalPrice,
      'profitPercentage': profitPercentage,
      'supplier': supplier,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  DocumentItemModel copyWith({
    String? id,
    String? documentId,
    String? productName,
    double? quantity,
    String? unit,
    double? purchasePrice,
    double? sellPrice,
    double? totalPrice,
    double? profitPercentage,
    String? supplier,
    DateTime? createdAt,
  }) {
    return DocumentItemModel(
      id: id ?? this.id,
      documentId: documentId ?? this.documentId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellPrice: sellPrice ?? this.sellPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      profitPercentage: profitPercentage ?? this.profitPercentage,
      supplier: supplier ?? this.supplier,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, documentId, productName, quantity, unit, purchasePrice, sellPrice, totalPrice, profitPercentage, supplier, createdAt];

  // Helper methods for type conversion
  static double? _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
