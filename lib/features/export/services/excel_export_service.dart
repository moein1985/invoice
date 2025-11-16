import 'dart:io';
import 'package:excel/excel.dart';
import '../../document/domain/entities/document_entity.dart';
import '../../customer/domain/entities/customer_entity.dart';
import '../../../core/enums/document_type.dart';

class ExcelExportService {
  /// تولید فایل Excel از سند
  Future<File> generateExcel(
    DocumentEntity document,
    CustomerEntity customer,
    String savePath,
  ) async {
    final excel = Excel.createExcel();
    final sheet = excel[excel.getDefaultSheet() ?? 'Sheet1'];

    sheet.appendRow(_row([
      document.documentType == DocumentType.invoice ? 'فاکتور فروش' : 'پیش‌فاکتور',
    ]));
    sheet.appendRow([]);

    sheet.appendRow(_row([
      'شماره سند',
      document.documentNumber,
      '',
      'تاریخ',
      _formatDate(document.documentDate),
    ]));
    sheet.appendRow([]);

    sheet.appendRow(_row(['اطلاعات مشتری']));
    sheet.appendRow(_row(['نام', customer.name]));
    sheet.appendRow(_row(['تلفن', customer.phone]));
    if (customer.company != null) {
      sheet.appendRow(_row(['شرکت', customer.company!]));
    }
    if (customer.address != null) {
      sheet.appendRow(_row(['آدرس', customer.address!]));
    }
    sheet.appendRow([]);

    sheet.appendRow(_row(['ردیف', 'محصول', 'تعداد', 'قیمت واحد', 'مبلغ کل']));
    for (int i = 0; i < document.items.length; i++) {
      final item = document.items[i];
      sheet.appendRow(_row([
        i + 1,
        item.productName,
        item.quantity,
        item.unitPrice,
        item.totalPrice,
      ]));
    }
    sheet.appendRow([]);

    sheet.appendRow(_row(['جمع کل', document.totalAmount]));
    if (document.discount > 0) {
      sheet.appendRow(_row(['تخفیف', document.discount]));
    }
    sheet.appendRow(_row(['مبلغ قابل پرداخت', document.finalAmount]));

    if (document.notes != null) {
      sheet.appendRow([]);
      sheet.appendRow(_row(['یادداشت']));
      sheet.appendRow(_row([document.notes!]));
    }

    final fileBytes = excel.encode();
    final file = File(savePath);
    await file.writeAsBytes(fileBytes!);
    return file;
  }

  List<CellValue?> _row(List<dynamic> values) {
    return values.map<CellValue?>((value) {
      if (value == null) return null;
      if (value is int) {
        return IntCellValue(value);
      }
      if (value is double) {
        return DoubleCellValue(value);
      }
      return TextCellValue(value.toString());
    }).toList();
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }
}
