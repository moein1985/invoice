import 'package:shamsi_date/shamsi_date.dart';

class PersianDateUtils {
  /// تبدیل DateTime به تاریخ شمسی (1403/08/25)
  static String toJalali(DateTime date) {
    final jalali = Jalali.fromDateTime(date);
    return '${jalali.year}/${jalali.month.toString().padLeft(2, '0')}/${jalali.day.toString().padLeft(2, '0')}';
  }

  /// تبدیل تاریخ شمسی به DateTime
  static DateTime fromJalali(int year, int month, int day) {
    final jalali = Jalali(year, month, day);
    return jalali.toDateTime();
  }

  /// فرمت کامل فارسی (جمعه ۲۵ آبان ۱۴۰۳)
  static String formatPersian(DateTime date) {
    final jalali = Jalali.fromDateTime(date);
    return '${jalali.formatter.wN} ${jalali.day} ${jalali.formatter.mN} ${jalali.year}';
  }

  /// دریافت تاریخ امروز
  static DateTime today() {
    return DateTime.now();
  }

  /// دریافت اول ماه جاری
  static DateTime startOfMonth() {
    final now = Jalali.now();
    return Jalali(now.year, now.month, 1).toDateTime();
  }

  /// دریافت آخر ماه جاری
  static DateTime endOfMonth() {
    final now = Jalali.now();
    final daysInMonth = now.monthLength;
    return Jalali(now.year, now.month, daysInMonth).toDateTime();
  }

  /// دریافت اول سال جاری
  static DateTime startOfYear() {
    final now = Jalali.now();
    return Jalali(now.year, 1, 1).toDateTime();
  }

  /// دریافت آخر سال جاری
  static DateTime endOfYear() {
    final now = Jalali.now();
    return Jalali(now.year, 12, 29).toDateTime();
  }
}