import 'package:flutter/material.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../../../core/utils/date_utils.dart' as date_utils;
import '../../domain/entities/dashboard_entity.dart';

class RecentInvoicesList extends StatelessWidget {
  final List<RecentInvoice> invoices;

  const RecentInvoicesList({
    super.key,
    required this.invoices,
  });

  @override
  Widget build(BuildContext context) {
    if (invoices.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('فاکتوری برای نمایش وجود ندارد'),
        ),
      );
    }

    return Card(
      elevation: 4,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: invoices.length,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
          final invoice = invoices[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: _getStatusColor(invoice.status),
              child: Icon(
                _getStatusIcon(invoice.status),
                color: Colors.white,
                size: 20,
              ),
            ),
            title: Text(
              invoice.customerName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              'فاکتور ${invoice.id} - ${date_utils.PersianDateUtils.toJalali(invoice.date)}',
            ),
            trailing: Text(
              NumberFormatter.formatCurrency(invoice.amount),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _getStatusColor(invoice.status),
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'پرداخت شده':
        return Colors.green;
      case 'در انتظار پرداخت':
        return Colors.orange;
      case 'لغو شده':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'پرداخت شده':
        return Icons.check;
      case 'در انتظار پرداخت':
        return Icons.schedule;
      case 'لغو شده':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }
}
