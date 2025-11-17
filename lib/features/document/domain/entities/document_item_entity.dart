import 'package:equatable/equatable.dart';

class DocumentItemEntity extends Equatable {
  final String id;
  final String productName;
  final int quantity;
  final String unit;
  final double purchasePrice;
  final double sellPrice;
  final double totalPrice;
  final double profitPercentage;
  final String supplier;
  final String? description;
  final bool isManualPrice; // آیا قیمت فروش به صورت دستی وارد شده؟

  const DocumentItemEntity({
    required this.id,
    required this.productName,
    required this.quantity,
    required this.unit,
    required this.purchasePrice,
    required this.sellPrice,
    required this.totalPrice,
    required this.profitPercentage,
    required this.supplier,
    this.description,
    this.isManualPrice = false,
  });

  @override
  List<Object?> get props => [
        id,
        productName,
        quantity,
        unit,
        purchasePrice,
        sellPrice,
        totalPrice,
        profitPercentage,
        supplier,
        description,
        isManualPrice,
      ];

  /// Factory constructor با محاسبات خودکار
  factory DocumentItemEntity.create({
    required String id,
    required String productName,
    required int quantity,
    required String unit,
    required double purchasePrice,
    double? sellPrice, // اگر null باشد از profitPercentage محاسبه می‌شود
    double? profitPercentage, // اگر null باشد از sellPrice محاسبه می‌شود
    required String supplier,
    String? description,
    bool isManualPrice = false,
  }) {
    // اگر قیمت فروش دستی وارد شده، از همان استفاده می‌کنیم
    final double finalSellPrice;
    final double finalProfitPercentage;

    if (isManualPrice && sellPrice != null) {
      // قیمت فروش دستی
      finalSellPrice = sellPrice;
      finalProfitPercentage = purchasePrice > 0
          ? ((sellPrice - purchasePrice) / purchasePrice) * 100
          : 0.0;
    } else {
      // محاسبه خودکار از درصد سود
      final profit = profitPercentage ?? 0.0;
      finalSellPrice = purchasePrice * (1 + profit / 100);
      finalProfitPercentage = profit;
    }

    final totalPrice = quantity * finalSellPrice;

    return DocumentItemEntity(
      id: id,
      productName: productName,
      quantity: quantity,
      unit: unit,
      purchasePrice: purchasePrice,
      sellPrice: finalSellPrice,
      totalPrice: totalPrice,
      profitPercentage: finalProfitPercentage,
      supplier: supplier,
      description: description,
      isManualPrice: isManualPrice,
    );
  }

  /// مبلغ سود
  double get profitAmount => (sellPrice - purchasePrice) * quantity;

  /// جمع خرید
  double get totalPurchasePrice => quantity * purchasePrice;

  DocumentItemEntity copyWith({
    String? id,
    String? productName,
    int? quantity,
    String? unit,
    double? purchasePrice,
    double? sellPrice,
    double? totalPrice,
    double? profitPercentage,
    String? supplier,
    String? description,
    bool? isManualPrice,
  }) {
    return DocumentItemEntity(
      id: id ?? this.id,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellPrice: sellPrice ?? this.sellPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      profitPercentage: profitPercentage ?? this.profitPercentage,
      supplier: supplier ?? this.supplier,
      description: description ?? this.description,
      isManualPrice: isManualPrice ?? this.isManualPrice,
    );
  }

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

  factory DocumentItemEntity.fromJson(Map<String, dynamic> json) {
    return DocumentItemEntity(
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
