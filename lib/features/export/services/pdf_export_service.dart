import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/enums/document_type.dart';
import '../../document/domain/entities/document_entity.dart';
import '../../customer/domain/entities/customer_entity.dart';

class PdfExportService {
  /// تولید PDF از سند
  Future<File> generatePdf(
    DocumentEntity document,
    CustomerEntity customer,
    String savePath,
  ) async {
    final pdf = pw.Document();

    // بارگذاری فونت فارسی (باید فونت TTF را در assets قرار دهید)
    final ttf = await rootBundle.load('assets/fonts/Vazir-Regular.ttf');
    final font = pw.Font.ttf(ttf);

    pdf.addPage(
      pw.Page(
        theme: pw.ThemeData.withFont(base: font),
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
              if (document.notes != null) ...[
                pw.SizedBox(height: 20),
                _buildNotes(document.notes!),
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
    final ttf = await rootBundle.load('assets/fonts/Vazir-Regular.ttf');
    final font = pw.Font.ttf(ttf);

    await Printing.layoutPdf(
      onLayout: (format) async {
        final pdf = pw.Document();
        pdf.addPage(
          pw.Page(
            theme: pw.ThemeData.withFont(base: font),
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
                  if (document.notes != null) ...[
                    pw.SizedBox(height: 20),
                    _buildNotes(document.notes!),
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
            _buildTableCell('قیمت واحد', isHeader: true),
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
              _buildTableCell(_formatNumber(item.unitPrice)),
              _buildTableCell(_formatNumber(item.totalPrice)),
            ],
          );
        }).toList(),
      ],
    );
  }

  pw.Widget _buildTotals(DocumentEntity document) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(),
        borderRadius: pw.BorderRadius.circular(5),
        color: PdfColors.grey200,
      ),
      child: pw.Column(
        children: [
          _buildTotalRow('جمع کل:', document.totalAmount),
          if (document.discount > 0)
            _buildTotalRow('تخفیف:', document.discount),
          pw.Divider(thickness: 2),
          _buildTotalRow('مبلغ قابل پرداخت:', document.finalAmount, isBold: true),
        ],
      ),
    );
  }

  pw.Widget _buildNotes(String notes) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('یادداشت:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 5),
          pw.Text(notes),
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

  String _getStatusText(status) {
    // This will be replaced with proper enum handling
    return status.toString().split('.').last;
  }
}
