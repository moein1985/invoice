import 'package:flutter/material.dart';
import 'package:invoice/core/utils/number_formatter.dart';
import '../../domain/entities/customer_entity.dart';

class CustomerListItem extends StatelessWidget {
  final CustomerEntity customer;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleStatus;
  final VoidCallback onViewDetails;

  const CustomerListItem({
    super.key,
    required this.customer,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleStatus,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: customer.isActive
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Text(
            customer.name.isNotEmpty ? customer.name[0] : '?',
            style: TextStyle(
                color: customer.isActive
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        title: Text(
          customer.name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                decoration: customer.isActive ? null : TextDecoration.lineThrough,
              ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (customer.company != null && customer.company!.isNotEmpty)
              Text(
                customer.company!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            if (customer.phone.isNotEmpty)
              Text(
                customer.phone,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            Row(
              children: [
                Text(
                  'بدهی: ${NumberFormatter.formatCurrency(customer.currentDebt)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: customer.currentDebt > 0 ? Colors.red : Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(width: 8),
                Text(
                  'سقف: ${NumberFormatter.formatCurrency(customer.creditLimit)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // وضعیت مشتری
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: customer.isActive
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                customer.isActive ? 'فعال' : 'غیرفعال',
                style: TextStyle(
                  color: customer.isActive ? Colors.green : Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // منوی عملیات
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    onEdit();
                    break;
                  case 'toggle':
                    onToggleStatus();
                    break;
                  case 'delete':
                    onDelete();
                    break;
                  case 'details':
                    onViewDetails();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'details',
                  child: Row(
                    children: [
                      Icon(Icons.visibility),
                      SizedBox(width: 8),
                      Text('جزئیات'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('ویرایش'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'toggle',
                  child: Row(
                    children: [
                      Icon(customer.isActive ? Icons.block : Icons.check_circle),
                      const SizedBox(width: 8),
                      Text(customer.isActive ? 'غیرفعال کردن' : 'فعال کردن'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('حذف'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: onViewDetails,
      ),
    );
  }
}