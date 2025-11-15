import 'package:hive/hive.dart';
import '../../domain/entities/document_item_entity.dart';

part 'document_item_model.g.dart';

@HiveType(typeId: 4)
class DocumentItemModel extends DocumentItemEntity {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String productName;

  @HiveField(2)
  final int quantity;

  @HiveField(3)
  final double unitPrice;

  @HiveField(4)
  final double totalPrice;

  @HiveField(5)
  final double profitPercentage;

  @HiveField(6)
  final String supplier;

  @HiveField(7)
  final String? description;

  const DocumentItemModel({
    required this.id,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.profitPercentage,
    required this.supplier,
    this.description,
  }) : super(
          id: id,
          productName: productName,
          quantity: quantity,
          unitPrice: unitPrice,
          totalPrice: totalPrice,
          profitPercentage: profitPercentage,
          supplier: supplier,
          description: description,
        );

  factory DocumentItemModel.fromEntity(DocumentItemEntity entity) {
    return DocumentItemModel(
      id: entity.id,
      productName: entity.productName,
      quantity: entity.quantity,
      unitPrice: entity.unitPrice,
      totalPrice: entity.totalPrice,
      profitPercentage: entity.profitPercentage,
      supplier: entity.supplier,
      description: entity.description,
    );
  }

  DocumentItemEntity toEntity() {
    return DocumentItemEntity(
      id: id,
      productName: productName,
      quantity: quantity,
      unitPrice: unitPrice,
      totalPrice: totalPrice,
      profitPercentage: profitPercentage,
      supplier: supplier,
      description: description,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productName': productName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
      'profitPercentage': profitPercentage,
      'supplier': supplier,
      'description': description,
    };
  }

  factory DocumentItemModel.fromJson(Map<String, dynamic> json) {
    return DocumentItemModel(
      id: json['id'] as String,
      productName: json['productName'] as String,
      quantity: json['quantity'] as int,
      unitPrice: (json['unitPrice'] as num).toDouble(),
      totalPrice: (json['totalPrice'] as num).toDouble(),
      profitPercentage: (json['profitPercentage'] as num).toDouble(),
      supplier: json['supplier'] as String,
      description: json['description'] as String?,
    );
  }
}
