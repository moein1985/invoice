import '../../domain/entities/customer_entity.dart';

class CustomerModel {
  final String id;
  final String name;
  final String phone;
  final List<String>? phoneNumbers;
  final String? email;
  final String? address;
  final String? company;
  final String? nationalId;
  final double creditLimit;
  final double currentDebt;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastTransaction;

  const CustomerModel({
    required this.id,
    required this.name,
    required this.phone,
    this.phoneNumbers,
    this.email,
    this.address,
    this.company,
    this.nationalId,
    this.creditLimit = 0.0,
    this.currentDebt = 0.0,
    this.isActive = true,
    required this.createdAt,
    this.lastTransaction,
  });

  /// تبدیل از Entity به Model
  factory CustomerModel.fromEntity(CustomerEntity entity) {
    return CustomerModel(
      id: entity.id,
      name: entity.name,
      phone: entity.phone,
      phoneNumbers: entity.phoneNumbers,
      email: entity.email,
      address: entity.address,
      company: entity.company,
      nationalId: entity.nationalId,
      creditLimit: entity.creditLimit,
      currentDebt: entity.currentDebt,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      lastTransaction: entity.lastTransaction,
    );
  }

  /// تبدیل از JSON
  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      phoneNumbers: json['phoneNumbers'] != null ? List<String>.from(json['phoneNumbers']) : null,
      email: json['email'] as String?,
      address: json['address'] as String?,
      company: json['company'] as String?,
      nationalId: json['nationalId'] as String?,
      creditLimit: (json['creditLimit'] as num?)?.toDouble() ?? 0.0,
      currentDebt: (json['currentDebt'] as num?)?.toDouble() ?? 0.0,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastTransaction: json['lastTransaction'] != null
          ? DateTime.parse(json['lastTransaction'] as String)
          : null,
    );
  }

  /// تبدیل به JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'phoneNumbers': phoneNumbers,
      'email': email,
      'address': address,
      'company': company,
      'nationalId': nationalId,
      'creditLimit': creditLimit,
      'currentDebt': currentDebt,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'lastTransaction': lastTransaction?.toIso8601String(),
    };
  }

  /// تبدیل به Entity
  CustomerEntity toEntity() {
    return CustomerEntity(
      id: id,
      name: name,
      phone: phone,
      phoneNumbers: phoneNumbers,
      email: email,
      address: address,
      company: company,
      nationalId: nationalId,
      creditLimit: creditLimit,
      currentDebt: currentDebt,
      isActive: isActive,
      createdAt: createdAt,
      lastTransaction: lastTransaction,
    );
  }
}
