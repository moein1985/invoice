import 'package:intl/intl.dart';
import 'package:persian_number_utility/persian_number_utility.dart';

class NumberFormatter {
  /// تبدیل عدد به فرمت سه رقمی: 1234567 => 1,234,567
  static String formatWithComma(double number) {
    final formatter = NumberFormat('#,###', 'en_US');
    return formatter.format(number);
  }

  /// تبدیل به اعداد فارسی: 123 => ۱۲۳
  static String toPersianNumber(String number) {
    return number.toPersianDigit();
  }

  /// ترکیب هر دو: 1234567 => ۱,۲۳۴,۵۶۷ ریال
  static String formatCurrency(double amount) {
    final formatted = formatWithComma(amount);
    final persian = toPersianNumber(formatted);
    return '$persian ریال';
  }

  /// حذف کاما و تبدیل به double
  static double? parseFormattedNumber(String text) {
    try {
      // حذف اعداد فارسی و تبدیل به انگلیسی
      final english = text.toEnglishDigit();
      // حذف کاما و ریال
      final cleaned = english.replaceAll(',', '').replaceAll('ریال', '').trim();
      return double.parse(cleaned);
    } catch (e) {
      return null;
    }
  }
}