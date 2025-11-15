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
    final sheet = excel['سند'];

    // تنظیم عرض ستون‌ها
    sheet.setColumnWidth(0, 5);
    sheet.setColumnWidth(1, 25);
    sheet.setColumnWidth(2, 10);
    sheet.setColumnWidth(3, 15);
    sheet.setColumnWidth(4, 15);

    int currentRow = 0;

    // عنوان
    _addMergedCell(
      sheet,
      currentRow,
      0,
      4,
      document.documentType == DocumentType.invoice ? 'فاکتور فروش' : 'پیش‌فاکتور',
      isBold: true,
      fontSize: 16,
    );
    currentRow += 2;

    // اطلاعات سند
    _addCell(sheet, currentRow, 0, 'شماره سند:', isBold: true);
    _addCell(sheet, currentRow, 1, document.documentNumber);
    _addCell(sheet, currentRow, 3, 'تاریخ:', isBold: true);
    _addCell(sheet, currentRow, 4, _formatDate(document.documentDate));
    currentRow += 2;

    // اطلاعات مشتری
    _addCell(sheet, currentRow, 0, 'مشتری:', isBold: true);
    currentRow++;
    _addCell(sheet, currentRow, 0, 'نام:');
    _addCell(sheet, currentRow, 1, customer.name);
    currentRow++;
    _addCell(sheet, currentRow, 0, 'تلفن:');
    _addCell(sheet, currentRow, 1, customer.phone);
    currentRow++;
    if (customer.company != null) {
      _addCell(sheet, currentRow, 0, 'شرکت:');
      _addCell(sheet, currentRow, 1, customer.company!);
      currentRow++;
    }
    currentRow += 2;

    // جدول ردیف‌ها
    _addCell(sheet, currentRow, 0, 'ردیف', isBold: true, withBorder: true);
    _addCell(sheet, currentRow, 1, 'محصول', isBold: true, withBorder: true);
    _addCell(sheet, currentRow, 2, 'تعداد', isBold: true, withBorder: true);
    _addCell(sheet, currentRow, 3, 'قیمت واحد', isBold: true, withBorder: true);
    _addCell(sheet, currentRow, 4, 'مبلغ کل', isBold: true, withBorder: true);
    currentRow++;

    for (int i = 0; i < document.items.length; i++) {
      final item = document.items[i];
      _addCell(sheet, currentRow, 0, (i + 1).toString(), withBorder: true);
      _addCell(sheet, currentRow, 1, item.productName, withBorder: true);
      _addCell(sheet, currentRow, 2, item.quantity.toString(), withBorder: true);
      _addCell(sheet, currentRow, 3, item.unitPrice.toString(), withBorder: true);
      _addCell(sheet, currentRow, 4, item.totalPrice.toString(), withBorder: true);
      currentRow++;
    }
    currentRow += 2;

    // جمع‌بندی
    _addCell(sheet, currentRow, 3, 'جمع کل:', isBold: true);
    _addCell(sheet, currentRow, 4, document.totalAmount.toString());
    currentRow++;

    if (document.discount > 0) {
      _addCell(sheet, currentRow, 3, 'تخفیف:', isBold: true);
      _addCell(sheet, currentRow, 4, document.discount.toString());
      currentRow++;
    }

    _addCell(sheet, currentRow, 3, 'مبلغ قابل پرداخت:', isBold: true);
    _addCell(sheet, currentRow, 4, document.finalAmount.toString(), isBold: true);
    currentRow += 2;

    // یادداشت
    if (document.notes != null) {
      _addCell(sheet, currentRow, 0, 'یادداشت:', isBold: true);
      currentRow++;
      _addCell(sheet, currentRow, 0, document.notes!);
    }

    // ذخیره فایل
    final fileBytes = excel.encode();
    final file = File(savePath);
    await file.writeAsBytes(fileBytes!);
    return file;
  }

  void _addCell(
    Sheet sheet,
    int row,
    int col,
    String value, {
    bool isBold = false,
    bool withBorder = false,
    int fontSize = 12,
  }) {
    final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
    cell.value = TextCellValue(value);
    
    // استایل
    final style = CellStyle(
      fontFamily: getFontFamily(FontFamily.Arial),
      bold: isBold,
      fontSize: fontSize,
    );
    
    cell.cellStyle = style;
  }

  void _addMergedCell(
    Sheet sheet,
    int row,
    int startCol,
    int endCol,
    String value, {
    bool isBold = false,
    int fontSize = 12,
  }) {
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: startCol, rowIndex: row),
      CellIndex.indexByColumnRow(columnIndex: endCol, rowIndex: row),
    );
    _addCell(sheet, row, startCol, value, isBold: isBold, fontSize: fontSize);
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }
}
