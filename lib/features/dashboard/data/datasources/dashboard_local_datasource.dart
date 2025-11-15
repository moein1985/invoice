import 'package:hive_flutter/hive_flutter.dart';
import '../models/dashboard_model.dart';
import '../../../../core/constants/hive_boxes.dart';
import '../../../../core/enums/document_type.dart';
import '../../../../core/enums/document_status.dart';
import '../../../document/data/models/document_model.dart';
import '../../../customer/data/models/customer_model.dart';

abstract class DashboardLocalDataSource {
  /// دریافت داده‌های داشبورد
  Future<DashboardModel> getDashboardData(String userId);
}

class DashboardLocalDataSourceImpl implements DashboardLocalDataSource {
  @override
  Future<DashboardModel> getDashboardData(String userId) async {
    final documentBox = Hive.box<DocumentModel>(HiveBoxes.documents);
    final customerBox = Hive.box<CustomerModel>(HiveBoxes.customers);

    // فیلتر اسناد بر اساس userId
    final allDocuments = documentBox.values.where((doc) => doc.userId == userId).toList();
    
    // محاسبه آمار
    final totalInvoices = allDocuments.where((d) => d.documentTypeString == 'invoice').length;
    final totalRevenue = allDocuments
        .where((d) => d.documentTypeString == 'invoice' && d.statusString == 'paid')
        .fold<double>(0, (sum, doc) => sum + doc.finalAmount);
    final totalCustomers = customerBox.values.length;
    final pendingInvoices = allDocuments
        .where((d) => d.statusString == 'unpaid' || d.statusString == 'pending')
        .length;

    // آخرین اسناد
    final recentDocs = allDocuments
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final recentInvoices = recentDocs.take(5).map((doc) {
      final customer = customerBox.values.firstWhere(
        (c) => c.id == doc.customerId,
        orElse: () => CustomerModel(
          id: '',
          name: 'نامشخص',
          phone: '',
          creditLimit: 0,
          currentDebt: 0,
          isActive: true,
          createdAt: DateTime.now(),
        ),
      );
      String statusText;
      switch (doc.statusString) {
        case 'paid':
          statusText = 'پرداخت شده';
          break;
        case 'unpaid':
          statusText = 'پرداخت نشده';
          break;
        default:
          statusText = 'در انتظار';
      }
      
      return RecentInvoiceModel(
        id: doc.documentNumber,
        customerName: customer.name,
        amount: doc.finalAmount,
        date: doc.documentDate,
        status: statusText,
      );
    }).toList();

    // داده‌های ماهانه (شبیه‌سازی شده - می‌توان با محاسبه واقعی جایگزین کرد)
    return DashboardModel(
      totalInvoices: totalInvoices,
      totalRevenue: totalRevenue,
      totalCustomers: totalCustomers,
      pendingInvoices: pendingInvoices,
      monthlyRevenue: totalRevenue,
      monthlyData: const [
        MonthlyDataModel(month: 'فروردین', revenue: 0),
        MonthlyDataModel(month: 'اردیبهشت', revenue: 0),
        MonthlyDataModel(month: 'خرداد', revenue: 0),
        MonthlyDataModel(month: 'تیر', revenue: 0),
        MonthlyDataModel(month: 'مرداد', revenue: 0),
        MonthlyDataModel(month: 'شهریور', revenue: 0),
      ],
      recentInvoices: recentInvoices,
    );
  }
}
