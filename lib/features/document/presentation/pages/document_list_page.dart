import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/enums/document_type.dart';
import '../../../../core/enums/document_status.dart';
import '../../../../core/enums/approval_status.dart';
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
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return; // ignore intermediate animation states
      AppLogger.debug('Tab changed index=${_tabController.index}', 'DocumentList');
    });
    _loadDocuments();
  }

  void _loadDocuments() {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      AppLogger.debug('Loading documents for userId=${authState.user.id}', 'DocumentList');
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
            Tab(icon: Icon(Icons.edit_note), text: 'پیش‌فاکتور موقت'),
            Tab(icon: Icon(Icons.description), text: 'پیش‌فاکتور'),
            Tab(icon: Icon(Icons.receipt), text: 'فاکتور'),
            Tab(icon: Icon(Icons.assignment_return), text: 'برگشت'),
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
                _buildDocumentList(DocumentType.tempProforma),
                _buildDocumentList(DocumentType.proforma),
                _buildDocumentList(DocumentType.invoice),
                _buildDocumentList(DocumentType.returnInvoice),
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
          final message = _getConversionMessage(state.fromType, state.toType);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: AppColors.success),
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
          AppLogger.debug('Building list for type=$type count=${filteredDocs.length}', 'DocumentList');

          if (filteredDocs.isEmpty) {
            return EmptyStateWidget(
              message: 'هنوز ${type.toFarsi()} ثبت نشده است',
              icon: _getDocumentTypeIcon(type),
              onAction: () => _navigateToForm(type: type),
              actionText: 'ایجاد ${type.toFarsi()}',
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _loadDocuments(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredDocs.length,
              itemBuilder: (context, index) {
                final doc = filteredDocs[index];
                AppLogger.debug('List item build index=$index id=${doc.id} number=${doc.documentNumber} type=${doc.documentType}', 'DocumentList');
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getDocumentTypeColor(doc.documentType),
                      child: Icon(
                        _getDocumentTypeIcon(doc.documentType),
                        color: Colors.white,
                      ),
                    ),
                    title: Row(
                      children: [
                        Text(
                          'شماره: ${doc.documentNumber}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getDocumentTypeColor(doc.documentType).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            doc.documentType.toFarsi(),
                            style: TextStyle(
                              fontSize: 11,
                              color: _getDocumentTypeColor(doc.documentType),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
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
                        if (doc.documentType == DocumentType.tempProforma)
                          PopupMenuItem(
                            value: doc.approvalStatus == ApprovalStatus.pending 
                              ? 'pending' 
                              : doc.approvalStatus == ApprovalStatus.rejected
                              ? 'rejected'
                              : 'convert',
                            child: Row(
                              children: [
                                Icon(
                                  doc.approvalStatus == ApprovalStatus.pending
                                    ? Icons.schedule
                                    : doc.approvalStatus == ApprovalStatus.rejected
                                    ? Icons.close
                                    : Icons.transform,
                                  color: doc.approvalStatus == ApprovalStatus.rejected
                                    ? AppColors.error
                                    : null,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  doc.approvalStatus == ApprovalStatus.pending
                                    ? 'منتظر تأیید'
                                    : doc.approvalStatus == ApprovalStatus.rejected
                                    ? 'رد شده'
                                    : 'تبدیل به پیش‌فاکتور',
                                  style: TextStyle(
                                    color: doc.approvalStatus == ApprovalStatus.rejected
                                      ? AppColors.error
                                      : null,
                                  ),
                                ),
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
                            AppLogger.debug('Action=view id=${doc.id}', 'DocumentList');
                            _openDocumentPreview(doc.id);
                            break;
                          case 'edit':
                            AppLogger.debug('Action=edit id=${doc.id}', 'DocumentList');
                            _navigateToForm(documentId: doc.id);
                            break;
                          case 'convert':
                            AppLogger.debug('Action=convert id=${doc.id} currentType=${doc.documentType}', 'DocumentList');
                            _convertDocument(doc);
                            break;
                          case 'delete':
                            AppLogger.debug('Action=delete id=${doc.id}', 'DocumentList');
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

    AppLogger.debug('Opening preview for id=$documentId detachedSupported=${_supportsDetachedPreview}', 'DocumentList');
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
    if (!_supportsDetachedPreview || document == null) {
      AppLogger.debug('Detached preview not supported or document null id=$documentId', 'DocumentList');
      return false;
    }
    
    // Ensure customers are loaded first
    final customerBloc = context.read<CustomerBloc>();
    if (customerBloc.state is! CustomersLoaded) {
      AppLogger.debug('Customers not loaded yet; dispatching LoadCustomers', 'DocumentList');
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
        AppLogger.debug('Found customer ${customer.name} for document ${document.documentNumber}', 'DocumentList');
      } catch (_) {
        AppLogger.warning('Customer not found for ID: ${document.customerId}', 'DocumentList');
      }
    } else {
      AppLogger.warning('Customers not loaded state=${customerState.runtimeType}', 'DocumentList');
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
      AppLogger.error('Failed to open detached preview window: $error', 'DocumentList');
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

  Color _getDocumentTypeColor(DocumentType type) {
    switch (type) {
      case DocumentType.tempProforma:
        return Colors.orange;
      case DocumentType.proforma:
        return Colors.blue;
      case DocumentType.invoice:
        return Colors.green;
      case DocumentType.returnInvoice:
        return Colors.red;
    }
  }

  IconData _getDocumentTypeIcon(DocumentType type) {
    switch (type) {
      case DocumentType.tempProforma:
        return Icons.edit_note;
      case DocumentType.proforma:
        return Icons.description;
      case DocumentType.invoice:
        return Icons.receipt;
      case DocumentType.returnInvoice:
        return Icons.assignment_return;
    }
  }

  void _performSearch() {
    if (_searchQuery.isEmpty) {
      _loadDocuments();
      return;
    }

    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      final DocumentType type;
      switch (_tabController.index) {
        case 0:
          type = DocumentType.tempProforma;
          break;
        case 1:
          type = DocumentType.proforma;
          break;
        case 2:
          type = DocumentType.invoice;
          break;
        case 3:
          type = DocumentType.returnInvoice;
          break;
        default:
          type = DocumentType.tempProforma;
      }
      
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

  void _convertDocument(DocumentEntity document) {
    final nextType = document.documentType.nextType;
    if (nextType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('این نوع سند قابل تبدیل نیست'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final String title;
    final String message;
    
    switch (document.documentType) {
      case DocumentType.tempProforma:
        title = 'تبدیل به پیش‌فاکتور';
        message = 'آیا می‌خواهید این پیش‌فاکتور موقت را به پیش‌فاکتور تبدیل کنید؟';
        break;
      case DocumentType.proforma:
        title = 'تبدیل به فاکتور';
        message = 'آیا می‌خواهید این پیش‌فاکتور را به فاکتور تبدیل کنید؟';
        break;
      default:
        return;
    }

    // از context والد استفاده می‌کنیم تا Provider در route دیالوگ از دست نرود
    final parentBloc = context.read<DocumentBloc>();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('لغو'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              AppLogger.info('Converting document id=${document.id} from ${document.documentType} to $nextType', 'DocumentList');
              parentBloc.add(ConvertDocument(document.id));
            },
            child: const Text('تبدیل'),
          ),
        ],
      ),
    );
  }

  String _getConversionMessage(DocumentType from, DocumentType to) {
    switch (from) {
      case DocumentType.tempProforma:
        return 'پیش‌فاکتور موقت با موفقیت به پیش‌فاکتور تبدیل شد';
      case DocumentType.proforma:
        return 'پیش‌فاکتور با موفقیت به فاکتور تبدیل شد';
      default:
        return 'سند با موفقیت تبدیل شد';
    }
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
              AppLogger.info('Deleting document id=$documentId', 'DocumentList');
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
