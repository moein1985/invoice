import 'package:equatable/equatable.dart';

class DashboardEntity extends Equatable {
  final int totalInvoices;
  final double totalRevenue;
  final int totalCustomers;
  final int pendingInvoices;
  final double monthlyRevenue;
  final List<MonthlyData> monthlyData;
  final List<RecentInvoice> recentInvoices;

  const DashboardEntity({
    required this.totalInvoices,
    required this.totalRevenue,
    required this.totalCustomers,
    required this.pendingInvoices,
    required this.monthlyRevenue,
    required this.monthlyData,
    required this.recentInvoices,
  });

  @override
  List<Object?> get props => [
        totalInvoices,
        totalRevenue,
        totalCustomers,
        pendingInvoices,
        monthlyRevenue,
        monthlyData,
        recentInvoices,
      ];
}

class MonthlyData extends Equatable {
  final String month;
  final double revenue;

  const MonthlyData({
    required this.month,
    required this.revenue,
  });

  @override
  List<Object?> get props => [month, revenue];
}

class RecentInvoice extends Equatable {
  final String id;
  final String customerName;
  final double amount;
  final DateTime date;
  final String status;

  const RecentInvoice({
    required this.id,
    required this.customerName,
    required this.amount,
    required this.date,
    required this.status,
  });

  @override
  List<Object?> get props => [id, customerName, amount, date, status];
}
