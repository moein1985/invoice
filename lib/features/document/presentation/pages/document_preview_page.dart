import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../../../core/enums/document_type.dart';
import '../../../../core/enums/document_status.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/utils/date_utils.dart' as date_utils;
import '../../../../core/utils/number_formatter.dart';
import '../../../../core/utils/logger.dart';
import '../../../../injection_container.dart' as di;
import '../../../customer/domain/entities/customer_entity.dart';
import '../../../customer/presentation/bloc/customer_bloc.dart';
import '../../domain/entities/document_entity.dart';
import '../bloc/document_bloc.dart';
import '../bloc/document_state.dart';
import '../bloc/document_event.dart';
import '../../domain/usecases/convert_document_usecase.dart';
import '../../../export/services/pdf_export_service.dart';
import '../../../export/services/excel_export_service.dart';

class DocumentPreviewPage extends StatefulWidget {
  final String documentId;

  const DocumentPreviewPage({
    super.key,
    required this.documentId,
  });

  @override
  State<DocumentPreviewPage> createState() => _DocumentPreviewPageState();
}

class _DocumentPreviewPageState extends State<DocumentPreviewPage> {
  DocumentEntity? _document;
  CustomerEntity? _customer;
  String? _pendingCustomerId;

  @override
  void initState() {
    super.initState();
    context.read<DocumentBloc>().add(LoadDocumentById(widget.documentId));
    final customerBloc = context.read<CustomerBloc>();
    if (customerBloc.state is! CustomersLoaded) {
      customerBloc.add(const LoadCustomers());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مشاهده سند'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'ویرایش',
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/documents/edit',
                arguments: widget.documentId,
              ).then((_) {
                // Reload document after edit
                setState(() {});
              });
            },
          ),
          // دکمه تبدیل
          if (_document != null && _document!.documentType.nextType != null)
            IconButton(
              icon: const Icon(Icons.arrow_forward),
              tooltip: _document!.documentType.convertButtonText,
              onPressed: _convertDocument,
            ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'خروجی PDF',
            onPressed: _document != null && _customer != null ? _exportToPdf : null,
          ),
          IconButton(
            icon: const Icon(Icons.table_chart),
            tooltip: 'خروجی Excel',
            onPressed: _document != null && _customer != null ? _exportToExcel : null,
          ),
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'چاپ',
            onPressed: _document != null && _customer != null ? _printDocument : null,
          ),
        ],
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<CustomerBloc, CustomerState>(
            listenWhen: (previous, current) => current is CustomersLoaded,
            listener: (context, state) {
              if (state is CustomersLoaded) {
                _resolveCustomer();
              }
            },
          ),
        ],
        child: BlocBuilder<DocumentBloc, DocumentState>(
          builder: (context, state) {
            if (state is DocumentLoading) {
              return const LoadingWidget();
            } else if (state is DocumentError) {
              return ErrorDisplayWidget(message: state.message);
            } else if (state is DocumentLoaded) {
              _document = state.document;
              _pendingCustomerId = state.document.customerId;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                _resolveCustomer();
              });
              return _buildPreview();
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  void _resolveCustomer() {
    if (_pendingCustomerId == null) return;
    final customerState = context.read<CustomerBloc>().state;
    if (customerState is CustomersLoaded) {
      try {
        final found = customerState.customers.firstWhere((c) => c.id == _pendingCustomerId);
        if (_customer != found) {
          setState(() {
            _customer = found;
          });
        }
        _pendingCustomerId = null;
      } catch (e) {
        setState(() {
          _customer = null;
        });
      }
    }
  }

  Widget _buildPreview() {
    if (_document == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const Divider(height: 32, thickness: 2),
              _buildDocumentInfo(),
              const SizedBox(height: 24),
              _buildCustomerInfo(),
              const SizedBox(height: 24),
              _buildItemsTable(),
              const SizedBox(height: 24),
              _buildTotals(),
              if (_document!.notes != null || _document!.attachment != null) ...[
                const SizedBox(height: 24),
                _buildNotes(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _document!.documentType == DocumentType.invoice ? 'فاکتور فروش' : 'پیش‌فاکتور',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'شماره سند: ${_document!.documentNumber}',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _getStatusColor(_document!.status).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _getStatusColor(_document!.status)),
          ),
          child: Text(
            _document!.status.toFarsi(),
            style: TextStyle(
              color: _getStatusColor(_document!.status),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _buildInfoItem(
                'تاریخ سند',
                date_utils.PersianDateUtils.toJalali(_document!.documentDate),
                Icons.calendar_today,
              ),
            ),
            Expanded(
              child: _buildInfoItem(
                'تاریخ ایجاد',
                date_utils.PersianDateUtils.toJalali(_document!.createdAt),
                Icons.access_time,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'اطلاعات مشتری',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_customer != null) ...[
              _buildInfoRow('نام', _customer!.name),
              _buildInfoRow('شماره تماس', _customer!.phone),
              if (_customer!.company != null) _buildInfoRow('شرکت', _customer!.company!),
              if (_customer!.address != null) _buildInfoRow('آدرس', _customer!.address!),
            ] else
              const Text('اطلاعات مشتری یافت نشد'),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsTable() {
    final showInternal = _document!.documentType.showInternalDetails;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ردیف‌های سند',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Table(
                border: TableBorder.all(color: Colors.grey.shade300),
                columnWidths: showInternal ? const {
                  0: FixedColumnWidth(50),
                  1: FixedColumnWidth(150),
                  2: FixedColumnWidth(80),
                  3: FixedColumnWidth(80),
                  4: FixedColumnWidth(100),
                  5: FixedColumnWidth(80),
                  6: FixedColumnWidth(100),
                  7: FixedColumnWidth(100),
                  8: FixedColumnWidth(100),
                } : const {
                  0: FixedColumnWidth(50),
                  1: FixedColumnWidth(200),
                  2: FixedColumnWidth(80),
                  3: FixedColumnWidth(80),
                  4: FixedColumnWidth(120),
                  5: FixedColumnWidth(120),
                },
                children: [
                  TableRow(
                    decoration: BoxDecoration(color: Colors.grey.shade100),
                    children: [
                      _buildTableHeader('ردیف'),
                      _buildTableHeader('محصول'),
                      _buildTableHeader('تعداد'),
                      _buildTableHeader('واحد'),
                      if (showInternal) _buildTableHeader('قیمت خرید'),
                      if (showInternal) _buildTableHeader('درصد سود'),
                      _buildTableHeader('قیمت فروش'),
                      if (showInternal) _buildTableHeader('سود'),
                      _buildTableHeader('مبلغ کل'),
                    ],
                  ),
                  ..._document!.items.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return TableRow(
                      children: [
                        _buildTableCell((index + 1).toString()),
                        _buildTableCell(item.productName),
                        _buildTableCell(item.quantity.toString()),
                        _buildTableCell(item.unit),
                        if (showInternal) _buildTableCell(NumberFormatter.formatWithComma(item.purchasePrice)),
                        if (showInternal) _buildTableCell('${item.profitPercentage.toStringAsFixed(1)}%'),
                        _buildTableCell(NumberFormatter.formatWithComma(item.sellPrice)),
                        if (showInternal) _buildTableCell(NumberFormatter.formatWithComma(item.profitAmount)),
                        _buildTableCell(NumberFormatter.formatWithComma(item.totalPrice)),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotals() {
    final showInternal = _document!.documentType.showInternalDetails;
    
    return Card(
      color: AppColors.primary.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (showInternal) ...[
              _buildTotalRow('جمع خرید', _document!.totalPurchaseAmount),
              _buildTotalRow('جمع سود', _document!.totalProfitAmount),
              const Divider(),
            ],
            _buildTotalRow('جمع کل', _document!.totalAmount),
            if (_document!.discount > 0) _buildTotalRow('تخفیف', _document!.discount),
            const Divider(thickness: 2),
            _buildTotalRow(
              'مبلغ قابل پرداخت',
              _document!.finalAmount,
              isMain: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotes() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_document!.notes != null) ...[
              const Text(
                'یادداشت',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(_document!.notes!),
              const SizedBox(height: 16),
            ],
            if (_document!.attachment != null) ...[
              const Text(
                'پیوست',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(_document!.attachment!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTableCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        text,
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount, {bool isMain = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isMain ? 18 : 16,
              fontWeight: isMain ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '${NumberFormatter.formatWithComma(amount)} ریال',
            style: TextStyle(
              fontSize: isMain ? 18 : 16,
              fontWeight: isMain ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(DocumentStatus status) {
    switch (status) {
      case DocumentStatus.paid:
        return AppColors.success;
      case DocumentStatus.unpaid:
        return AppColors.warning;
      case DocumentStatus.pending:
        return AppColors.error;
    }
  }

  Future<void> _convertDocument() async {
    if (_document == null) return;
    
    final nextType = _document!.documentType.nextType;
    if (nextType == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_document!.documentType.convertButtonText ?? 'تبدیل'),
        content: Text('آیا مطمئن هستید که می‌خواهید این سند را به ${nextType.toFarsi()} تبدیل کنید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('لغو'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('تبدیل'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final convertUseCase = di.sl<ConvertDocumentUseCase>();
      final result = await convertUseCase(_document!);
      
      result.fold(
        (failure) {
          _showSnack(failure.message, isError: true);
        },
        (convertedDocument) {
          _showSnack('سند با موفقیت به ${nextType.toFarsi()} تبدیل شد');
          // بازگشت به صفحه قبل و نمایش سند جدید
          Navigator.pushReplacementNamed(
            context,
            '/documents/preview',
            arguments: convertedDocument.id,
          );
        },
      );
    } catch (e, stack) {
      AppLogger.error('Failed to convert document', 'DocumentPreview', e, stack);
      _showSnack('خطا در تبدیل سند', isError: true);
    }
  }

  Future<void> _exportToPdf() async {
    if (_document == null || _customer == null) return;
    try {
      final dir = await _getExportDirectory();
      final fileName = _buildFileName('pdf');
      final path = p.join(dir.path, fileName);
      final pdfService = di.sl<PdfExportService>();
      final file = await pdfService.generatePdf(_document!, _customer!, path);
      _showSnack('فایل PDF در ${file.path} ذخیره شد');
      await OpenFile.open(file.path);
    } catch (e, stack) {
      AppLogger.error('Failed to export PDF', 'DocumentPreview', e, stack);
      _showSnack('خطا در ایجاد فایل PDF', isError: true);
    }
  }

  Future<void> _exportToExcel() async {
    if (_document == null || _customer == null) return;
    try {
      final dir = await _getExportDirectory();
      final fileName = _buildFileName('xlsx');
      final path = p.join(dir.path, fileName);
      final excelService = di.sl<ExcelExportService>();
      final file = await excelService.generateExcel(_document!, _customer!, path);
      _showSnack('فایل Excel در ${file.path} ذخیره شد');
      await OpenFile.open(file.path);
    } catch (e, stack) {
      AppLogger.error('Failed to export Excel', 'DocumentPreview', e, stack);
      _showSnack('خطا در ایجاد فایل Excel', isError: true);
    }
  }

  Future<void> _printDocument() async {
    if (_document == null || _customer == null) return;
    try {
      final pdfService = di.sl<PdfExportService>();
      await pdfService.printDocument(_document!, _customer!);
      _showSnack('سند برای چاپ ارسال شد');
    } catch (e, stack) {
      AppLogger.error('Failed to print document', 'DocumentPreview', e, stack);
      _showSnack('خطا در ارسال سند به چاپگر', isError: true);
    }
  }

  Future<Directory> _getExportDirectory() async {
    final downloads = await getDownloadsDirectory();
    if (downloads != null) {
      return downloads;
    }
    return getApplicationDocumentsDirectory();
  }

  String _buildFileName(String extension) {
    final base = _document?.documentNumber ?? widget.documentId;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${base}_$timestamp.$extension';
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : null,
      ),
    );
  }
}

/// Static preview page that doesn't require database access
/// Used for multi-window desktop preview with serialized data
class StaticDocumentPreviewPage extends StatelessWidget {
  final Map<String, dynamic> documentData;
  final Map<String, dynamic>? customerData;

  const StaticDocumentPreviewPage({
    super.key,
    required this.documentData,
    this.customerData,
  });

  @override
  Widget build(BuildContext context) {
    final document = DocumentEntity.fromJson(documentData);
    final customer = customerData != null ? CustomerEntity.fromJson(customerData!) : null;
    
    // Debug logging
    AppLogger.debug('StaticDocumentPreviewPage built', 'PREVIEW');
    AppLogger.debug('Document: ${document.documentNumber}', 'PREVIEW');
    AppLogger.debug('Document Type: ${document.documentType}', 'PREVIEW');
    AppLogger.debug('Show Internal Details: ${document.documentType.showInternalDetails}', 'PREVIEW');
    AppLogger.debug('Customer data available: ${customerData != null}', 'PREVIEW');
    if (customer != null) {
      AppLogger.debug('Customer name: ${customer.name}', 'PREVIEW');
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('مشاهده سند'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'خروجی PDF',
            onPressed: customer != null ? () => _exportToPdf(context, document, customer) : null,
          ),
          IconButton(
            icon: const Icon(Icons.table_chart),
            tooltip: 'خروجی Excel',
            onPressed: customer != null ? () => _exportToExcel(context, document, customer) : null,
          ),
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'چاپ',
            onPressed: customer != null ? () => _printDocument(context, document, customer) : null,
          ),
        ],
      ),
      body: _buildPreview(document, customer),
    );
  }

  Widget _buildPreview(DocumentEntity document, CustomerEntity? customer) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(document),
              const Divider(height: 32, thickness: 2),
              _buildDocumentInfo(document),
              const SizedBox(height: 24),
              _buildCustomerInfo(customer),
              const SizedBox(height: 24),
              _buildItemsTable(document),
              const SizedBox(height: 24),
              _buildTotals(document),
              if (document.notes != null) ...[
                const SizedBox(height: 24),
                _buildNotes(document),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(DocumentEntity document) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              document.documentType == DocumentType.invoice ? 'فاکتور فروش' : 'پیش‌فاکتور',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'شماره سند: ${document.documentNumber}',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _getStatusColor(document.status).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _getStatusColor(document.status)),
          ),
          child: Text(
            document.status.toFarsi(),
            style: TextStyle(
              color: _getStatusColor(document.status),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentInfo(DocumentEntity document) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _buildInfoItem(
                'تاریخ سند',
                date_utils.PersianDateUtils.toJalali(document.documentDate),
                Icons.calendar_today,
              ),
            ),
            Expanded(
              child: _buildInfoItem(
                'تاریخ ایجاد',
                date_utils.PersianDateUtils.toJalali(document.createdAt),
                Icons.access_time,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerInfo(CustomerEntity? customer) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'اطلاعات مشتری',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (customer != null) ...[
              _buildInfoRow('نام', customer.name),
              _buildInfoRow('شماره تماس', customer.phone),
              if (customer.company != null) _buildInfoRow('شرکت', customer.company!),
              if (customer.address != null) _buildInfoRow('آدرس', customer.address!),
            ] else
              const Text('اطلاعات مشتری یافت نشد'),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsTable(DocumentEntity document) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ردیف‌های سند',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Builder(builder: (context) {
              final showInternal = document.documentType.showInternalDetails;
              AppLogger.debug('Building items table with showInternalDetails: $showInternal', 'PREVIEW');
              AppLogger.debug('Column count: ${showInternal ? 9 : 6}', 'PREVIEW');
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Table(
                  border: TableBorder.all(color: Colors.grey.shade300),
                  columnWidths: showInternal ? const {
                  0: FixedColumnWidth(50),
                  1: FixedColumnWidth(150),
                  2: FixedColumnWidth(80),
                  3: FixedColumnWidth(80),
                  4: FixedColumnWidth(100),
                  5: FixedColumnWidth(80),
                  6: FixedColumnWidth(100),
                  7: FixedColumnWidth(100),
                  8: FixedColumnWidth(100),
                } : const {
                  0: FixedColumnWidth(50),
                  1: FixedColumnWidth(200),
                  2: FixedColumnWidth(80),
                  3: FixedColumnWidth(80),
                  4: FixedColumnWidth(120),
                  5: FixedColumnWidth(120),
                },
                children: [
                  TableRow(
                    decoration: BoxDecoration(color: Colors.grey.shade100),
                    children: [
                      _buildTableHeader('ردیف'),
                      _buildTableHeader('محصول'),
                      _buildTableHeader('تعداد'),
                      _buildTableHeader('واحد'),
                      if (document.documentType.showInternalDetails) _buildTableHeader('قیمت خرید'),
                      if (document.documentType.showInternalDetails) _buildTableHeader('درصد سود'),
                      _buildTableHeader('قیمت فروش'),
                      if (document.documentType.showInternalDetails) _buildTableHeader('سود'),
                      _buildTableHeader('مبلغ کل'),
                    ],
                  ),
                  ...document.items.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return TableRow(
                      children: [
                        _buildTableCell((index + 1).toString()),
                        _buildTableCell(item.productName),
                        _buildTableCell(item.quantity.toString()),
                        _buildTableCell(item.unit),
                        if (document.documentType.showInternalDetails) _buildTableCell(NumberFormatter.formatWithComma(item.purchasePrice)),
                        if (document.documentType.showInternalDetails) _buildTableCell('${item.profitPercentage.toStringAsFixed(1)}%'),
                        _buildTableCell(NumberFormatter.formatWithComma(item.sellPrice)),
                        if (document.documentType.showInternalDetails) _buildTableCell(NumberFormatter.formatWithComma(item.profitAmount)),
                        _buildTableCell(NumberFormatter.formatWithComma(item.totalPrice)),
                      ],
                    );
                  }),
                ],
              ),
            );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTotals(DocumentEntity document) {
    final showInternal = document.documentType.showInternalDetails;
    
    return Card(
      color: AppColors.primary.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (showInternal) ...[
              _buildTotalRow('جمع خرید', document.totalPurchaseAmount),
              _buildTotalRow('جمع سود', document.totalProfitAmount),
              const Divider(),
            ],
            _buildTotalRow('جمع کل', document.totalAmount),
            if (document.discount > 0) _buildTotalRow('تخفیف', document.discount),
            const Divider(thickness: 2),
            _buildTotalRow(
              'مبلغ قابل پرداخت',
              document.finalAmount,
              isMain: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotes(DocumentEntity document) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'یادداشت',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(document.notes!),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTableCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        text,
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount, {bool isMain = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isMain ? 18 : 16,
              fontWeight: isMain ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '${NumberFormatter.formatWithComma(amount)} ریال',
            style: TextStyle(
              fontSize: isMain ? 18 : 16,
              fontWeight: isMain ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
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

  Future<void> _exportToPdf(BuildContext context, DocumentEntity document, CustomerEntity customer) async {
    try {
      AppLogger.debug('Exporting to PDF for customer: ${customer.name}', 'EXPORT');
      // Create service directly since GetIt is not initialized in preview window
      final pdfService = PdfExportService();
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'document_${document.documentNumber}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = p.join(directory.path, fileName);
      
      final file = await pdfService.generatePdf(document, customer, filePath);
      
      if (context.mounted) {
        _showSnackBar(context, 'فایل PDF با موفقیت ذخیره شد');
        await OpenFile.open(file.path);
      }
    } catch (e) {
      AppLogger.error('خطا در ایجاد PDF: $e', 'EXPORT');
      if (context.mounted) {
        _showSnackBar(context, 'خطا در ایجاد فایل PDF', isError: true);
      }
    }
  }

  Future<void> _exportToExcel(BuildContext context, DocumentEntity document, CustomerEntity customer) async {
    try {
      AppLogger.debug('Exporting to Excel for customer: ${customer.name}', 'EXPORT');
      // Create service directly since GetIt is not initialized in preview window
      final excelService = ExcelExportService();
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'document_${document.documentNumber}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final filePath = p.join(directory.path, fileName);
      
      final file = await excelService.generateExcel(document, customer, filePath);
      
      if (context.mounted) {
        _showSnackBar(context, 'فایل Excel با موفقیت ذخیره شد');
        await OpenFile.open(file.path);
      }
    } catch (e) {
      AppLogger.error('خطا در ایجاد Excel: $e', 'EXPORT');
      if (context.mounted) {
        _showSnackBar(context, 'خطا در ایجاد فایل Excel', isError: true);
      }
    }
  }

  Future<void> _printDocument(BuildContext context, DocumentEntity document, CustomerEntity customer) async {
    try {
      AppLogger.debug('Printing document for customer: ${customer.name}', 'PRINT');
      // Create service directly since GetIt is not initialized in preview window
      final pdfService = PdfExportService();
      final directory = await getTemporaryDirectory();
      final fileName = 'print_${document.documentNumber}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = p.join(directory.path, fileName);
      
      final file = await pdfService.generatePdf(document, customer, filePath);
      await OpenFile.open(file.path);
      
      if (context.mounted) {
        _showSnackBar(context, 'فایل برای چاپ آماده شد');
      }
    } catch (e) {
      AppLogger.error('خطا در آماده‌سازی چاپ: $e', 'PRINT');
      if (context.mounted) {
        _showSnackBar(context, 'خطا در آماده‌سازی چاپ', isError: true);
      }
    }
  }

  void _showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : null,
      ),
    );
  }
}
