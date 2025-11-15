import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invoice/core/widgets/loading_widget.dart';
import 'package:invoice/core/widgets/error_widget.dart';
import 'package:invoice/core/utils/number_formatter.dart';
import '../bloc/customer_bloc.dart';
import '../../domain/entities/customer_entity.dart';

class CustomerDetailPage extends StatefulWidget {
  final String customerId;

  const CustomerDetailPage({super.key, required this.customerId});

  @override
  State<CustomerDetailPage> createState() => _CustomerDetailPageState();
}

class _CustomerDetailPageState extends State<CustomerDetailPage> {
  CustomerEntity? _customer;

  @override
  void initState() {
    super.initState();
    // بارگذاری جزئیات مشتری
    context.read<CustomerBloc>().add(const LoadCustomers());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('جزئیات مشتری'),
        actions: [
          if (_customer != null) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.of(context).pushNamed('/customers/edit', arguments: _customer);
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _showDeleteConfirmationDialog(),
            ),
          ],
        ],
      ),
      body: BlocConsumer<CustomerBloc, CustomerState>(
        listener: (context, state) {
          if (state is CustomersLoaded) {
            // پیدا کردن مشتری مورد نظر
            final customer = state.customers.firstWhere(
              (c) => c.id == widget.customerId,
              orElse: () => throw Exception('Customer not found'),
            );
            setState(() => _customer = customer);
          } else if (state is CustomerOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.of(context).pop();
          } else if (state is CustomerError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is CustomerInitial || state is CustomerLoading) {
            return const LoadingWidget();
          } else if (state is CustomerError) {
            return ErrorDisplayWidget(
              message: state.message,
              onRetry: () {
                context.read<CustomerBloc>().add(const LoadCustomers());
              },
            );
          } else if (_customer != null) {
            return _buildCustomerDetails(_customer!);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildCustomerDetails(CustomerEntity customer) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // هدر با آواتار
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: customer.isActive
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.surfaceVariant,
                  child: Text(
                    customer.name.isNotEmpty ? customer.name[0] : '?',
                    style: TextStyle(
                      fontSize: 32,
                      color: customer.isActive
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  customer.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: customer.isActive
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    customer.isActive ? 'مشتری فعال' : 'مشتری غیرفعال',
                    style: TextStyle(
                      color: customer.isActive ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // اطلاعات مشتری
          Text(
            'اطلاعات مشتری',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),

          _buildInfoCard(
            title: 'نام مشتری',
            value: customer.name,
            icon: Icons.person,
          ),
          _buildInfoCard(
            title: 'شماره تلفن',
            value: customer.phone,
            icon: Icons.phone,
          ),
          if (customer.email != null && customer.email!.isNotEmpty)
            _buildInfoCard(
              title: 'ایمیل',
              value: customer.email!,
              icon: Icons.email,
            ),
          if (customer.company != null && customer.company!.isNotEmpty)
            _buildInfoCard(
              title: 'شرکت',
              value: customer.company!,
              icon: Icons.business,
            ),
          if (customer.nationalId != null && customer.nationalId!.isNotEmpty)
            _buildInfoCard(
              title: 'کد ملی/شماره ثبت',
              value: customer.nationalId!,
              icon: Icons.badge,
            ),
          if (customer.address != null && customer.address!.isNotEmpty)
            _buildInfoCard(
              title: 'آدرس',
              value: customer.address!,
              icon: Icons.location_on,
            ),

          const SizedBox(height: 32),

          // اطلاعات مالی
          Text(
            'اطلاعات مالی',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),

          _buildInfoCard(
            title: 'سقف اعتبار',
            value: NumberFormatter.formatCurrency(customer.creditLimit),
            icon: Icons.account_balance_wallet,
          ),
          _buildInfoCard(
            title: 'بدهی فعلی',
            value: NumberFormatter.formatCurrency(customer.currentDebt),
            icon: Icons.money_off,
            valueColor: customer.currentDebt > 0 ? Colors.red : Colors.green,
          ),
          _buildInfoCard(
            title: 'اعتبار باقی مانده',
            value: NumberFormatter.formatCurrency(customer.remainingCredit),
            icon: Icons.trending_up,
            valueColor: customer.remainingCredit >= 0 ? Colors.green : Colors.red,
          ),

          const SizedBox(height: 32),

          // تاریخ‌ها
          Text(
            'تاریخ‌ها',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),

          _buildInfoCard(
            title: 'تاریخ ایجاد',
            value: _formatDate(customer.createdAt),
            icon: Icons.calendar_today,
          ),
          if (customer.lastTransaction != null)
            _buildInfoCard(
              title: 'آخرین تراکنش',
              value: _formatDate(customer.lastTransaction!),
              icon: Icons.schedule,
            ),

          const SizedBox(height: 32),

          // دکمه‌ها
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushNamed('/customers/edit', arguments: customer);
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('ویرایش'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showDeleteConfirmationDialog(),
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text('حذف'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Colors.red),
                    foregroundColor: Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
    Color? valueColor,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        subtitle: Text(
          value,
          style: valueColor != null ? TextStyle(color: valueColor) : null,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  void _showDeleteConfirmationDialog() {
    if (_customer == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأیید حذف'),
        content: Text('آیا از حذف مشتری "${_customer!.name}" اطمینان دارید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('انصراف'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<CustomerBloc>().add(DeleteCustomer(_customer!.id));
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}