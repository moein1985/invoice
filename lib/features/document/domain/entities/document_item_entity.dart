import 'package:equatable/equatable.dart';

class DocumentItemEntity extends Equatable {
  final String id;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final double profitPercentage;
  final String supplier;
  final String? description;

  const DocumentItemEntity({
    required this.id,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.profitPercentage,
    required this.supplier,
    this.description,
  });

  @override
  List<Object?> get props => [
        id,
        productName,
        quantity,
        unitPrice,
        totalPrice,
        profitPercentage,
        supplier,
        description,
      ];

  DocumentItemEntity copyWith({
    String? id,
    String? productName,
    int? quantity,
    double? unitPrice,
    double? totalPrice,
    double? profitPercentage,
    String? supplier,
    String? description,
  }) {
    return DocumentItemEntity(
      id: id ?? this.id,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      profitPercentage: profitPercentage ?? this.profitPercentage,
      supplier: supplier ?? this.supplier,
      description: description ?? this.description,
    );
  }
}
