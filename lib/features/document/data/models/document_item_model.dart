import 'package:hive/hive.dart';
import '../../domain/entities/document_item_entity.dart';

part 'document_item_model.g.dart';

@HiveType(typeId: 4)
class DocumentItemModel extends DocumentItemEntity {
  const DocumentItemModel({
    required super.id,
    required super.productName,
    required super.quantity,
    required super.unit,
    required super.purchasePrice,
    required super.sellPrice,
    required super.totalPrice,
    required super.profitPercentage,
    required super.supplier,
    super.description,
    super.isManualPrice = false,
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
  String get unit => super.unit;

  @override
  @HiveField(4)
  double get purchasePrice => super.purchasePrice;

  @override
  @HiveField(5)
  double get sellPrice => super.sellPrice;

  @override
  @HiveField(6)
  double get totalPrice => super.totalPrice;

  @override
  @HiveField(7)
  double get profitPercentage => super.profitPercentage;

  @override
  @HiveField(8)
  String get supplier => super.supplier;

  @override
  @HiveField(9)
  String? get description => super.description;

  @override
  @HiveField(10)
  bool get isManualPrice => super.isManualPrice;

  factory DocumentItemModel.fromEntity(DocumentItemEntity entity) {
    return DocumentItemModel(
      id: entity.id,
      productName: entity.productName,
      quantity: entity.quantity,
      unit: entity.unit,
      purchasePrice: entity.purchasePrice,
      sellPrice: entity.sellPrice,
      totalPrice: entity.totalPrice,
      profitPercentage: entity.profitPercentage,
      supplier: entity.supplier,
      description: entity.description,
      isManualPrice: entity.isManualPrice,
    );
  }

  DocumentItemEntity toEntity() {
    return DocumentItemEntity(
      id: id,
      productName: productName,
      quantity: quantity,
      unit: unit,
      purchasePrice: purchasePrice,
      sellPrice: sellPrice,
      totalPrice: totalPrice,
      profitPercentage: profitPercentage,
      supplier: supplier,
      description: description,
      isManualPrice: isManualPrice,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productName': productName,
      'quantity': quantity,
      'unit': unit,
      'purchasePrice': purchasePrice,
      'sellPrice': sellPrice,
      'totalPrice': totalPrice,
      'profitPercentage': profitPercentage,
      'supplier': supplier,
      'description': description,
      'isManualPrice': isManualPrice,
    };
  }

  factory DocumentItemModel.fromJson(Map<String, dynamic> json) {
    return DocumentItemModel(
      id: json['id'] as String,
      productName: json['productName'] as String,
      quantity: json['quantity'] as int,
      unit: json['unit'] as String,
      purchasePrice: (json['purchasePrice'] as num).toDouble(),
      sellPrice: (json['sellPrice'] as num).toDouble(),
      totalPrice: (json['totalPrice'] as num).toDouble(),
      profitPercentage: (json['profitPercentage'] as num).toDouble(),
      supplier: json['supplier'] as String,
      description: json['description'] as String?,
      isManualPrice: json['isManualPrice'] as bool? ?? false,
    );
  }
}
