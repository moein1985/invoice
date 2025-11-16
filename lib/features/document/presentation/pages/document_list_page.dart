import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/enums/document_type.dart';
import '../../../../core/enums/document_status.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/utils/date_utils.dart' as date_utils;
import '../../../../core/utils/number_formatter.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/utils/window_arguments.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../customer/domain/entities/customer_entity.dart';
import '../../../customer/presentation/bloc/customer_bloc.dart';
import '../../domain/entities/document_entity.dart';
import '../bloc/document_bloc.dart';
import '../bloc/document_event.dart';
import '../bloc/document_state.dart';
import 'document_form_page.dart';

class DocumentListPage extends StatefulWidget {
  const DocumentListPage({super.key});

  @override
  State<DocumentListPage> createState() => _DocumentListPageState();
}

class _DocumentListPageState extends State<DocumentListPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadDocuments();
  }

  void _loadDocuments() {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      context.read<DocumentBloc>().add(LoadDocuments(authState.user.id));
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('فاکتورها و پیش‌فاکتورها'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'فاکتور'),
            Tab(text: 'پیش‌فاکتور'),
          ],
        ),
      ),
      body: Column(
        children: [
          // جستجو
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'جستجو در شماره، نام محصول، تامین‌کننده...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                          _loadDocuments();
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
                if (value.isEmpty) {
                  _loadDocuments();
                }
              },
              onSubmitted: (value) => _performSearch(),
            ),
          ),

          // لیست
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDocumentList(DocumentType.invoice),
                _buildDocumentList(DocumentType.proforma),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToForm(),
        icon: const Icon(Icons.add),
        label: const Text('سند جدید'),
      ),
    );
  }

  Widget _buildDocumentList(DocumentType type) {
    return BlocConsumer<DocumentBloc, DocumentState>(
      listener: (context, state) {
        if (state is DocumentError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
          );
        } else if (state is DocumentDeleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('سند با موفقیت حذف شد'), backgroundColor: AppColors.success),
          );
          _loadDocuments();
        } else if (state is DocumentConverted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('پیش‌فاکتور با موفقیت به فاکتور تبدیل شد'), backgroundColor: AppColors.success),
          );
          _loadDocuments();
        }
      },
      builder: (context, state) {
        if (state is DocumentLoading) {
          return const LoadingWidget();
        }

        if (state is DocumentError) {
          return ErrorDisplayWidget(message: state.message, onRetry: _loadDocuments);
        }

        if (state is DocumentsLoaded) {
          final filteredDocs = state.documents.where((doc) => doc.documentType == type).toList();

          if (filteredDocs.isEmpty) {
            return EmptyStateWidget(
              message: type == DocumentType.invoice
                  ? 'هنوز فاکتوری ثبت نشده است'
                  : 'هنوز پیش‌فاکتوری ثبت نشده است',
              icon: Icons.receipt_long_outlined,
              onAction: () => _navigateToForm(type: type),
              actionText: type == DocumentType.invoice ? 'ایجاد فاکتور' : 'ایجاد پیش‌فاکتور',
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _loadDocuments(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredDocs.length,
              itemBuilder: (context, index) {
                final doc = filteredDocs[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getStatusColor(doc.status),
                      child: Icon(
                        doc.documentType == DocumentType.invoice
                            ? Icons.receipt
                            : Icons.description,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      'شماره: ${doc.documentNumber}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('تاریخ: ${date_utils.PersianDateUtils.toJalali(doc.documentDate)}'),
                        Text('مبلغ: ${NumberFormatter.formatCurrency(doc.finalAmount)}'),
                        Text(
                          'وضعیت: ${doc.status.toFarsi()}',
                          style: TextStyle(
                            color: _getStatusColor(doc.status),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton(
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'view',
                          child: Row(
                            children: [
                              Icon(Icons.visibility),
                              SizedBox(width: 8),
                              Text('مشاهده'),
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
                        if (doc.documentType == DocumentType.proforma)
                          const PopupMenuItem(
                            value: 'convert',
                            child: Row(
                              children: [
                                Icon(Icons.transform),
                                SizedBox(width: 8),
                                Text('تبدیل به فاکتور'),
                              ],
                            ),
                          ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: AppColors.error),
                              SizedBox(width: 8),
                              Text('حذف', style: TextStyle(color: AppColors.error)),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) {
                        switch (value) {
                          case 'view':
                            _openDocumentPreview(doc.id);
                            break;
                          case 'edit':
                            _navigateToForm(documentId: doc.id);
                            break;
                          case 'convert':
                            _convertToInvoice(doc.id);
                            break;
                          case 'delete':
                            _deleteDocument(doc.id);
                            break;
                        }
                      },
                    ),
                  ),
                );
              },
            ),
          );
        }

        return const Center(child: Text('خطای غیرمنتظره'));
      },
    );
  }

  Future<void> _openDocumentPreview(String documentId) async {
    // Find the document from current state
    final documentState = context.read<DocumentBloc>().state;
    DocumentEntity? document;
    if (documentState is DocumentsLoaded) {
      try {
        document = documentState.documents.firstWhere((d) => d.id == documentId);
      } catch (_) {}
    }

    final openedInNewWindow = await _tryOpenDetachedPreview(documentId, document);
    if (!openedInNewWindow && mounted) {
      Navigator.pushNamed(
        context,
        '/documents/preview',
        arguments: documentId,
      );
    }
  }

  Future<bool> _tryOpenDetachedPreview(String documentId, DocumentEntity? document) async {
    if (!_supportsDetachedPreview || document == null) return false;
    
    // Ensure customers are loaded first
    final customerBloc = context.read<CustomerBloc>();
    if (customerBloc.state is! CustomersLoaded) {
      customerBloc.add(const LoadCustomers());
      // Wait a moment for customers to load
      await Future.delayed(const Duration(milliseconds: 500));
    }
    
    // Find customer data
    final customerState = customerBloc.state;
    CustomerEntity? customer;
    if (customerState is CustomersLoaded) {
      try {
        customer = customerState.customers.firstWhere((c) => c.id == document.customerId);
        debugPrint('Found customer: ${customer.name} for document ${document.documentNumber}');
      } catch (_) {
        debugPrint('Customer not found for ID: ${document.customerId}');
      }
    } else {
      debugPrint('Customers not loaded, state: ${customerState.runtimeType}');
    }

    try {
      final args = AppWindowArguments.preview(
        documentId: documentId,
        documentData: document.toJson(),
        customerData: customer?.toJson(),
      ).encode();
      final controller = await WindowController.create(
        WindowConfiguration(arguments: args),
      );
      await controller.show();
      return true;
    } catch (error) {
      debugPrint('Failed to open detached preview window: $error');
      return false;
    }
  }

  bool get _supportsDetachedPreview {
    if (kIsWeb) return false;
    return {
      TargetPlatform.windows,
      TargetPlatform.linux,
      TargetPlatform.macOS,
    }.contains(defaultTargetPlatform);
  }

  Color _getStatusColor(DocumentStatus status) {
    switch (status) {
      case DocumentStatus.paid:
        return AppColors.success;
      case DocumentStatus.unpaid:
        return AppColors.error;
      case DocumentStatus.pending:
        return AppColors.warning;
    }
  }

  void _performSearch() {
    if (_searchQuery.isEmpty) {
      _loadDocuments();
      return;
    }

    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      final type = _tabController.index == 0 ? DocumentType.invoice : DocumentType.proforma;
      context.read<DocumentBloc>().add(
            SearchDocuments(
              userId: authState.user.id,
              query: _searchQuery,
              type: type,
            ),
          );
    }
  }

  void _navigateToForm({String? documentId, DocumentType? type}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: context.read<DocumentBloc>()),
            BlocProvider.value(value: context.read<CustomerBloc>()),
          ],
          child: DocumentFormPage(
            documentId: documentId,
            initialType: type ?? DocumentType.invoice,
          ),
        ),
      ),
    ).then((_) => _loadDocuments());
  }

  void _convertToInvoice(String proformaId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تبدیل به فاکتور'),
        content: const Text('آیا می‌خواهید این پیش‌فاکتور را به فاکتور تبدیل کنید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('لغو'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<DocumentBloc>().add(ConvertToInvoice(proformaId));
            },
            child: const Text('تبدیل'),
          ),
        ],
      ),
    );
  }

  void _deleteDocument(String documentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف سند'),
        content: const Text('آیا مطمئن هستید که می‌خواهید این سند را حذف کنید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('لغو'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<DocumentBloc>().add(DeleteDocument(documentId));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}
