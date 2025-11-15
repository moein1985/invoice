import 'package:equatable/equatable.dart';

class CustomerEntity extends Equatable {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String? address;
  final String? company;
  final String? nationalId; // کد ملی یا شماره ثبت
  final double creditLimit; // سقف اعتبار
  final double currentDebt; // بدهی فعلی
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastTransaction;

  const CustomerEntity({
    required this.id,
    required this.name,
    required this.phone,
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

  /// آیا مشتری بدهی دارد
  bool get hasDebt => currentDebt > 0;

  /// آیا مشتری به سقف اعتبار رسیده
  bool get isAtCreditLimit => currentDebt >= creditLimit && creditLimit > 0;

  /// اعتبار باقی مانده
  double get remainingCredit => creditLimit - currentDebt;

  @override
  List<Object?> get props => [
        id,
        name,
        phone,
        email,
        address,
        company,
        nationalId,
        creditLimit,
        currentDebt,
        isActive,
        createdAt,
        lastTransaction,
      ];
}
