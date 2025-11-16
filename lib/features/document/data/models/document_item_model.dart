import 'package:hive/hive.dart';
import '../../domain/entities/document_item_entity.dart';

part 'document_item_model.g.dart';

@HiveType(typeId: 4)
class DocumentItemModel extends DocumentItemEntity {
  const DocumentItemModel({
    required super.id,
    required super.productName,
    required super.quantity,
    required super.unitPrice,
    required super.totalPrice,
    required super.profitPercentage,
    required super.supplier,
    super.description,
  });

  @override
  @HiveField(0)
  String get id => super.id;

  @override
  @HiveField(1)
  String get productName => super.productName;

  @override
  @HiveField(2)
  int get quantity => super.quantity;

  @override
  @HiveField(3)
  double get unitPrice => super.unitPrice;

  @override
  @HiveField(4)
  double get totalPrice => super.totalPrice;

  @override
  @HiveField(5)
  double get profitPercentage => super.profitPercentage;

  @override
  @HiveField(6)
  String get supplier => super.supplier;

  @override
  @HiveField(7)
  String? get description => super.description;

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
