import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/enums/document_type.dart';
import '../../../../core/enums/document_status.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/utils/date_utils.dart' as date_utils;
import '../../../../core/utils/number_formatter.dart';
import '../../../customer/domain/entities/customer_entity.dart';
import '../../../customer/presentation/bloc/customer_bloc.dart';
import '../../domain/entities/document_entity.dart';
import '../bloc/document_bloc.dart';
import '../bloc/document_state.dart';
import '../bloc/document_event.dart';

class DocumentPreviewPage extends StatefulWidget {
  final String documentId;

  const DocumentPreviewPage({
    Key? key,
    required this.documentId,
  }) : super(key: key);

  @override
  State<DocumentPreviewPage> createState() => _DocumentPreviewPageState();
}

class _DocumentPreviewPageState extends State<DocumentPreviewPage> {
  DocumentEntity? _document;
  CustomerEntity? _customer;

  @override
  void initState() {
    super.initState();
    context.read<DocumentBloc>().add(LoadDocumentById(widget.documentId));
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
      body: BlocBuilder<DocumentBloc, DocumentState>(
        builder: (context, state) {
          if (state is DocumentLoading) {
            return const LoadingWidget();
          } else if (state is DocumentError) {
            return ErrorDisplayWidget(message: state.message);
          } else if (state is DocumentLoaded) {
            _document = state.document;
            // Load customer info
            _loadCustomer(state.document.customerId);
            return _buildPreview();
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _loadCustomer(String customerId) {
    final customerState = context.read<CustomerBloc>().state;
    if (customerState is CustomersLoaded) {
      try {
        _customer = customerState.customers.firstWhere((c) => c.id == customerId);
      } catch (e) {
        _customer = null;
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
                color: Colors.black.withOpacity(0.1),
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
              if (_document!.notes != null) ...[
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
            color: _getStatusColor(_document!.status).withOpacity(0.2),
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
            Table(
              border: TableBorder.all(color: Colors.grey.shade300),
              columnWidths: const {
                0: FlexColumnWidth(0.5),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(1),
                3: FlexColumnWidth(1.5),
                4: FlexColumnWidth(1.5),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey.shade100),
                  children: [
                    _buildTableHeader('ردیف'),
                    _buildTableHeader('محصول'),
                    _buildTableHeader('تعداد'),
                    _buildTableHeader('قیمت واحد'),
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
                      _buildTableCell(NumberFormatter.formatWithComma(item.unitPrice)),
                      _buildTableCell(NumberFormatter.formatWithComma(item.totalPrice)),
                    ],
                  );
                }).toList(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotals() {
    return Card(
      color: AppColors.primary.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
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
            const Text(
              'یادداشت',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(_document!.notes!),
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

  Future<void> _exportToPdf() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('قابلیت خروجی PDF نیاز به فونت فارسی دارد. به زودی اضافه می‌شود...')),
    );
    // TODO: Implement PDF export with Persian font
    // final pdfService = di.sl<PdfExportService>();
    // final path = 'path/to/save/${_document!.documentNumber}.pdf';
    // await pdfService.generatePdf(_document!, _customer!, path);
  }

  Future<void> _exportToExcel() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('خروجی Excel در حال آماده‌سازی است...')),
    );
    // TODO: Implement Excel export
    // final excelService = di.sl<ExcelExportService>();
    // final path = 'path/to/save/${_document!.documentNumber}.xlsx';
    // await excelService.generateExcel(_document!, _customer!, path);
  }

  Future<void> _printDocument() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('قابلیت چاپ نیاز به فونت فارسی دارد. به زودی اضافه می‌شود...')),
    );
    // TODO: Implement print
    // final pdfService = di.sl<PdfExportService>();
    // await pdfService.printDocument(_document!, _customer!);
  }
}
