import 'package:invoice/features/customer/domain/entities/customer_entity.dart';
import 'package:invoice/features/document/domain/entities/document_entity.dart';

/// ترکیب اطلاعات مشتری + آخرین سند برای نمایش در Popup
class CustomerCallData {
  final CustomerEntity customer;
  final DocumentEntity? lastDocument;
  final String phoneNumber; // شماره‌ای که تماس گرفته

  const CustomerCallData({
    required this.customer,
    this.lastDocument,
    required this.phoneNumber,
  });

  factory CustomerCallData.fromJson(Map<String, dynamic> json) {
    return CustomerCallData(
      customer: CustomerEntity.fromJson(json['customer']),
      lastDocument: json['lastDocument'] != null 
          ? DocumentEntity.fromJson(json['lastDocument'])
          : null,
      phoneNumber: json['phoneNumber'] as String? ?? '',
    );
  }
}
