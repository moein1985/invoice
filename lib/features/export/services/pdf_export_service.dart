import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/enums/document_type.dart';
import '../../../core/enums/document_status.dart';
import '../../document/domain/entities/document_entity.dart';
import '../../customer/domain/entities/customer_entity.dart';

class PdfExportService {
  static const _regularFontPath = 'assets/fonts/Vazirmatn-Regular.ttf';
  static const _boldFontPath = 'assets/fonts/Vazirmatn-Bold.ttf';

  /// تولید PDF از سند
  Future<File> generatePdf(
    DocumentEntity document,
    CustomerEntity customer,
    String savePath,
  ) async {
    final pdf = pw.Document();

    // بارگذاری فونت‌های فارسی
    final fonts = await _loadFonts();

    pdf.addPage(
      pw.Page(
        theme: pw.ThemeData.withFont(
          base: fonts.base,
          bold: fonts.bold,
        ),
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(document),
              pw.SizedBox(height: 20),
              _buildCustomerInfo(customer),
              pw.SizedBox(height: 20),
              _buildItemsTable(document),
              pw.SizedBox(height: 20),
              _buildTotals(document),
              if (document.notes != null || document.attachment != null) ...[
                pw.SizedBox(height: 20),
                _buildNotesAndAttachment(document),
              ],
            ],
          );
        },
      ),
    );

    final file = File(savePath);
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  /// چاپ مستقیم
  Future<void> printDocument(
    DocumentEntity document,
    CustomerEntity customer,
  ) async {
    final fonts = await _loadFonts();

    await Printing.layoutPdf(
      onLayout: (format) async {
        final pdf = pw.Document();
        pdf.addPage(
          pw.Page(
            theme: pw.ThemeData.withFont(
              base: fonts.base,
              bold: fonts.bold,
            ),
            pageFormat: format,
            textDirection: pw.TextDirection.rtl,
            build: (context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildHeader(document),
                  pw.SizedBox(height: 20),
                  _buildCustomerInfo(customer),
                  pw.SizedBox(height: 20),
                  _buildItemsTable(document),
                  pw.SizedBox(height: 20),
                  _buildTotals(document),
                  if (document.notes != null || document.attachment != null) ...[
                    pw.SizedBox(height: 20),
                    _buildNotesAndAttachment(document),
                  ],
                ],
              );
            },
          ),
        );
        return pdf.save();
      },
    );
  }

  Future<_PdfFonts> _loadFonts() async {
    final base = await _tryLoadFont(
      _regularFontPath,
      fallback: pw.Font.helvetica(),
    );
    final bold = await _tryLoadFont(
      _boldFontPath,
      fallback: pw.Font.helveticaBold(),
    );
    return _PdfFonts(base: base, bold: bold);
  }

  Future<pw.Font> _tryLoadFont(String assetPath, {required pw.Font fallback}) async {
    try {
      final ttf = await rootBundle.load(assetPath);
      return pw.Font.ttf(ttf);
    } catch (_) {
      return fallback;
    }
  }

  pw.Widget _buildHeader(DocumentEntity document) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(width: 2),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                document.documentType == DocumentType.invoice ? 'فاکتور فروش' : 'پیش‌فاکتور',
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 5),
              pw.Text('شماره سند: ${document.documentNumber}'),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('تاریخ: ${_formatDate(document.documentDate)}'),
              pw.Text('وضعیت: ${_getStatusText(document.status)}'),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildCustomerInfo(CustomerEntity customer) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('مشتری:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 5),
          pw.Text('نام: ${customer.name}'),
          pw.Text('تلفن: ${customer.phone}'),
          if (customer.company != null) pw.Text('شرکت: ${customer.company}'),
          if (customer.address != null) pw.Text('آدرس: ${customer.address}'),
        ],
      ),
    );
  }

  pw.Widget _buildItemsTable(DocumentEntity document) {
    final showInternal = document.documentType.showInternalDetails;
    
    return pw.Table(
      border: pw.TableBorder.all(),
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _buildTableCell('ردیف', isHeader: true),
            _buildTableCell('محصول', isHeader: true),
            _buildTableCell('تعداد', isHeader: true),
            _buildTableCell('واحد', isHeader: true),
            if (showInternal) _buildTableCell('قیمت خرید', isHeader: true),
            if (showInternal) _buildTableCell('درصد سود', isHeader: true),
            _buildTableCell('قیمت فروش', isHeader: true),
            if (showInternal) _buildTableCell('سود', isHeader: true),
            _buildTableCell('مبلغ کل', isHeader: true),
          ],
        ),
        // Items
        ...document.items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return pw.TableRow(
            children: [
              _buildTableCell((index + 1).toString()),
              _buildTableCell(item.productName),
              _buildTableCell(item.quantity.toString()),
              _buildTableCell(item.unit),
              if (showInternal) _buildTableCell(_formatNumber(item.purchasePrice)),
              if (showInternal) _buildTableCell('${item.profitPercentage.toStringAsFixed(1)}%'),
              _buildTableCell(_formatNumber(item.sellPrice)),
              if (showInternal) _buildTableCell(_formatNumber(item.profitAmount)),
              _buildTableCell(_formatNumber(item.totalPrice)),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _buildTotals(DocumentEntity document) {
    final showInternal = document.documentType.showInternalDetails;

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(),
        borderRadius: pw.BorderRadius.circular(5),
        color: PdfColors.grey200,
      ),
      child: pw.Column(
        children: [
          if (showInternal) ...[
            _buildTotalRow('جمع کل خرید:', document.totalPurchaseAmount),
            _buildTotalRow('جمع سود:', document.totalProfitAmount),
            pw.Divider(),
          ],
          _buildTotalRow('جمع کل فروش:', document.totalAmount),
          if (document.discount > 0)
            _buildTotalRow('تخفیف:', document.discount),
          pw.Divider(thickness: 2),
          _buildTotalRow('مبلغ قابل پرداخت:', document.finalAmount, isBold: true),
        ],
      ),
    );
  }

  pw.Widget _buildNotesAndAttachment(DocumentEntity document) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (document.notes != null) ...[
            pw.Text('یادداشت:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 5),
            pw.Text(document.notes!),
            if (document.attachment != null) pw.SizedBox(height: 10),
          ],
          if (document.attachment != null) ...[
            pw.Text('پیوست:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 5),
            pw.Text(document.attachment!),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  pw.Widget _buildTotalRow(String label, double amount, {bool isBold = false}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            fontSize: isBold ? 14 : 12,
          ),
        ),
        pw.Text(
          '${_formatNumber(amount)} ریال',
          style: pw.TextStyle(
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            fontSize: isBold ? 14 : 12,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  String _formatNumber(double number) {
    return number.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  String _getStatusText(DocumentStatus status) {
    // This will be replaced with proper enum handling
    return status.toString().split('.').last;
  }
}

class _PdfFonts {
  final pw.Font base;
  final pw.Font bold;

  const _PdfFonts({required this.base, required this.bold});
}
