import '../../domain/entities/dashboard_entity.dart';

class DashboardModel extends DashboardEntity {
  const DashboardModel({
    required super.totalInvoices,
    required super.totalRevenue,
    required super.totalCustomers,
    required super.pendingInvoices,
    required super.monthlyRevenue,
    required super.monthlyData,
    required super.recentInvoices,
  });

  /// تبدیل از JSON
  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    return DashboardModel(
      totalInvoices: json['totalInvoices'] ?? 0,
      totalRevenue: (json['totalRevenue'] ?? 0.0).toDouble(),
      totalCustomers: json['totalCustomers'] ?? 0,
      pendingInvoices: json['pendingInvoices'] ?? 0,
      monthlyRevenue: (json['monthlyRevenue'] ?? 0.0).toDouble(),
      monthlyData: (json['monthlyData'] as List<dynamic>?)
              ?.map((e) => MonthlyDataModel.fromJson(e))
              .toList() ??
          [],
      recentInvoices: (json['recentInvoices'] as List<dynamic>?)
              ?.map((e) => RecentInvoiceModel.fromJson(e))
              .toList() ??
          [],
    );
  }

  /// تبدیل به JSON
  Map<String, dynamic> toJson() {
    return {
      'totalInvoices': totalInvoices,
      'totalRevenue': totalRevenue,
      'totalCustomers': totalCustomers,
      'pendingInvoices': pendingInvoices,
      'monthlyRevenue': monthlyRevenue,
      'monthlyData': monthlyData.map((e) => (e as MonthlyDataModel).toJson()).toList(),
      'recentInvoices': recentInvoices.map((e) => (e as RecentInvoiceModel).toJson()).toList(),
    };
  }
}

class MonthlyDataModel extends MonthlyData {
  const MonthlyDataModel({
    required super.month,
    required super.revenue,
  });

  factory MonthlyDataModel.fromJson(Map<String, dynamic> json) {
    return MonthlyDataModel(
      month: json['month'] ?? '',
      revenue: (json['revenue'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'month': month,
      'revenue': revenue,
    };
  }
}

class RecentInvoiceModel extends RecentInvoice {
  const RecentInvoiceModel({
    required super.id,
    required super.customerName,
    required super.amount,
    required super.date,
    required super.status,
  });

  factory RecentInvoiceModel.fromJson(Map<String, dynamic> json) {
    return RecentInvoiceModel(
      id: json['id'] ?? '',
      customerName: json['customerName'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      status: json['status'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerName': customerName,
      'amount': amount,
      'date': date.toIso8601String(),
      'status': status,
    };
  }
}
