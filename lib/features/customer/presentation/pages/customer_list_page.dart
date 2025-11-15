import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invoice/core/widgets/loading_widget.dart';
import 'package:invoice/core/widgets/error_widget.dart';
import '../bloc/customer_bloc.dart';
import '../widgets/customer_list_item.dart';
import '../widgets/customer_search_bar.dart';

class CustomerListPage extends StatefulWidget {
  const CustomerListPage({super.key});

  @override
  State<CustomerListPage> createState() => _CustomerListPageState();
}

class _CustomerListPageState extends State<CustomerListPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // بارگذاری لیست مشتریان
    context.read<CustomerBloc>().add(const LoadCustomers());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      context.read<CustomerBloc>().add(const LoadCustomers());
    } else {
      context.read<CustomerBloc>().add(SearchCustomers(query));
    }
  }

  void _onRefresh() {
    _searchController.clear();
    context.read<CustomerBloc>().add(const LoadCustomers());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مدیریت مشتریان'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _onRefresh,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.of(context).pushNamed('/customers/create');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // نوار جستجو
          CustomerSearchBar(
            controller: _searchController,
            onChanged: _onSearchChanged,
          ),

          // لیست مشتریان
          Expanded(
            child: BlocConsumer<CustomerBloc, CustomerState>(
              listener: (context, state) {
                if (state is CustomerOperationSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.green,
                    ),
                  );
                  // بروزرسانی لیست پس از عملیات موفق
                  context.read<CustomerBloc>().add(const LoadCustomers());
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
                } else if (state is CustomersLoaded) {
                  if (state.customers.isEmpty) {
                    return const Center(
                      child: Text('هیچ مشتری یافت نشد'),
                    );
                  }

                  return ListView.builder(
                    itemCount: state.customers.length,
                    itemBuilder: (context, index) {
                      final customer = state.customers[index];
                      return CustomerListItem(
                        customer: customer,
                        onEdit: () {
                          Navigator.of(context).pushNamed('/customers/edit', arguments: customer);
                        },
                        onDelete: () {
                          _showDeleteConfirmationDialog(customer);
                        },
                        onToggleStatus: () {
                          context.read<CustomerBloc>().add(ToggleCustomerStatus(customer.id));
                        },
                        onViewDetails: () {
                          Navigator.of(context).pushNamed('/customers/detail', arguments: customer.id);
                        },
                      );
                    },
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(dynamic customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأیید حذف'),
        content: Text('آیا از حذف مشتری "${customer.fullName}" اطمینان دارید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('انصراف'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<CustomerBloc>().add(DeleteCustomer(customer.id));
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}