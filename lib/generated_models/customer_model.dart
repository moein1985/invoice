import 'package:equatable/equatable.dart';

class CustomerModel extends Equatable {
  final String id;
  final String name;
  final String? phone;
  final String? email;
  final String? company;
  final double? creditLimit;
  final double? currentDebt;
  final String? address;
  final bool? isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? phoneNumbers;

  const CustomerModel({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.company,
    this.creditLimit,
    this.currentDebt,
    this.address,
    this.isActive,
    this.createdAt,
    this.updatedAt,
    this.phoneNumbers,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      email: json['email'],
      company: json['company'],
      creditLimit: _parseDouble(json['creditLimit']),
      currentDebt: _parseDouble(json['currentDebt']),
      address: json['address'],
      isActive: _parseBool(json['isActive']),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      phoneNumbers: json['phoneNumbers'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'company': company,
      'creditLimit': creditLimit,
      'currentDebt': currentDebt,
      'address': address,
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'phoneNumbers': phoneNumbers,
    };
  }

  CustomerModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? company,
    double? creditLimit,
    double? currentDebt,
    String? address,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? phoneNumbers,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      company: company ?? this.company,
      creditLimit: creditLimit ?? this.creditLimit,
      currentDebt: currentDebt ?? this.currentDebt,
      address: address ?? this.address,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      phoneNumbers: phoneNumbers ?? this.phoneNumbers,
    );
  }

  @override
  List<Object?> get props => [id, name, phone, email, company, creditLimit, currentDebt, address, isActive, createdAt, updatedAt, phoneNumbers];

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
