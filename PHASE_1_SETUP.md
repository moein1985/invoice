# راهنمای پیاده‌سازی فاز به فاز

این سند راهنمای گام‌به‌گام پیاده‌سازی پروژه است. هر فاز را به ترتیب و کامل پیاده‌سازی کنید.

---

## 🎯 فاز 1: راه‌اندازی پروژه و Core Setup

### گام 1.1: تنظیم pubspec.yaml

```yaml
name: invoice
description: A Flutter invoice management application
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  flutter_bloc: ^8.1.3
  equatable: ^2.0.5
  get_it: ^7.6.0
  
  # Database
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  
  # Persian Support
  shamsi_date: ^1.0.1
  persian_number_utility: ^1.1.3
  persian_datetime_picker: ^2.6.0
  
  # Export
  excel: ^4.0.0
  pdf: ^3.10.0
  printing: ^5.11.0
  
  # File Handling
  path_provider: ^2.1.0
  file_picker: ^6.0.0
  open_file: ^3.3.2
  
  # Utilities
  intl: ^0.19.0
  uuid: ^4.0.0
  dartz: ^0.10.1
  
  # UI
  flutter_localizations:
    sdk: flutter

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
  hive_generator: ^2.0.0
  build_runner: ^2.4.0

flutter:
  uses-material-design: true
  
  # فونت‌های فارسی - باید فایل‌ها را دانلود کنید
  fonts:
    - family: Vazir
      fonts:
        - asset: assets/fonts/Vazir-Regular.ttf
        - asset: assets/fonts/Vazir-Bold.ttf
          weight: 700
```

### گام 1.2: دانلود فونت Vazir

1. از [این لینک](https://github.com/rastikerdar/vazir-font/releases) فونت Vazir را دانلود کنید
2. فایل‌ها را در `assets/fonts/` قرار دهید:
   - `Vazir-Regular.ttf`
   - `Vazir-Bold.ttf`

### گام 1.3: ایجاد ساختار فولدرها

```
lib/
├── core/
│   ├── constants/
│   ├── enums/
│   ├── error/
│   ├── themes/
│   ├── utils/
│   └── widgets/
├── features/
│   ├── auth/
│   ├── user_management/
│   ├── customer/
│   ├── document/
│   ├── statistics/
│   ├── export/
│   ├── dashboard/
│   └── settings/
└── injection_container.dart
```

### گام 1.4: ایجاد Constants

#### `lib/core/constants/hive_boxes.dart`
```dart
class HiveBoxes {
  static const String users = 'users_box';
  static const String currentUser = 'current_user_box';
  static const String customers = 'customers_box';
  static const String documents = 'documents_box';
  static const String settings = 'settings_box';
}
```

#### `lib/core/constants/app_constants.dart`
```dart
class AppConstants {
  static const String appName = 'مدیریت فاکتور';
  static const String defaultAdminUsername = 'ادمین';
  static const String defaultAdminPassword = '12321';
  static const int itemsPerPage = 20;
  static const int searchDebounceMs = 500;
}
```

#### `lib/core/constants/user_roles.dart`
```dart
class UserRoles {
  static const String admin = 'admin';
  static const String user = 'user';
}
```

### گام 1.5: ایجاد Enums

#### `lib/core/enums/document_type.dart`
```dart
enum DocumentType {
  invoice,
  proforma;

  String toFarsi() {
    switch (this) {
      case DocumentType.invoice:
        return 'فاکتور';
      case DocumentType.proforma:
        return 'پیش‌فاکتور';
    }
  }
}
```

#### `lib/core/enums/document_status.dart`
```dart
enum DocumentStatus {
  paid,
  unpaid,
  pending;

  String toFarsi() {
    switch (this) {
      case DocumentStatus.paid:
        return 'پرداخت شده';
      case DocumentStatus.unpaid:
        return 'پرداخت نشده';
      case DocumentStatus.pending:
        return 'در انتظار';
    }
  }
}
```

### گام 1.6: Error Handling

#### `lib/core/error/failures.dart`
```dart
import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message);
}
```

#### `lib/core/error/exceptions.dart`
```dart
class ServerException implements Exception {
  final String message;
  ServerException(this.message);
}

class CacheException implements Exception {
  final String message;
  CacheException(this.message);
}

class ValidationException implements Exception {
  final String message;
  ValidationException(this.message);
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
}

class NotFoundException implements Exception {
  final String message;
  NotFoundException(this.message);
}
```

### گام 1.7: Utils - Number Formatter

#### `lib/core/utils/number_formatter.dart`
```dart
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
```

### گام 1.8: Utils - Date Utils

#### `lib/core/utils/date_utils.dart`
```dart
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
```

### گام 1.9: Utils - Validators

#### `lib/core/utils/validators.dart`
```dart
class Validators {
  /// اعتبارسنجی فیلد الزامی
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName الزامی است';
    }
    return null;
  }

  /// اعتبارسنجی شماره تلفن
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'شماره تلفن الزامی است';
    }
    
    // حذف فاصله و خط تیره
    final cleaned = value.replaceAll(RegExp(r'[\s-]'), '');
    
    // بررسی طول
    if (cleaned.length < 10 || cleaned.length > 11) {
      return 'شماره تلفن معتبر نیست';
    }
    
    // بررسی فقط عدد باشد
    if (!RegExp(r'^[0-9]+$').hasMatch(cleaned)) {
      return 'شماره تلفن باید فقط شامل اعداد باشد';
    }
    
    return null;
  }

  /// اعتبارسنجی عدد
  static String? validateNumber(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName الزامی است';
    }
    
    if (double.tryParse(value) == null) {
      return '$fieldName باید عدد باشد';
    }
    
    return null;
  }

  /// اعتبارسنجی عدد مثبت
  static String? validatePositiveNumber(String? value, String fieldName) {
    final error = validateNumber(value, fieldName);
    if (error != null) return error;

    if (double.parse(value!) <= 0) {
      return '$fieldName باید بزرگتر از صفر باشد';
    }
    
    return null;
  }

  /// اعتبارسنجی ایمیل (اختیاری)
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return null; // اختیاری است
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'ایمیل معتبر نیست';
    }

    return null;
  }

  /// اعتبارسنجی رمز عبور
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'رمز عبور الزامی است';
    }

    if (value.length < 5) {
      return 'رمز عبور باید حداقل ۵ کاراکتر باشد';
    }

    return null;
  }

  /// اعتبارسنجی نام کاربری
  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'نام کاربری الزامی است';
    }

    if (value.length < 3) {
      return 'نام کاربری باید حداقل ۳ کاراکتر باشد';
    }

    return null;
  }
}
```

### گام 1.10: Themes

#### `lib/core/themes/app_colors.dart`
```dart
import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF1976D2);
  static const Color primaryDark = Color(0xFF1565C0);
  static const Color primaryLight = Color(0xFF42A5F5);
  
  static const Color secondary = Color(0xFF424242);
  static const Color secondaryLight = Color(0xFF6D6D6D);
  
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFFA726);
  static const Color info = Color(0xFF29B6F6);
  
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textDisabled = Color(0xFFBDBDBD);
  
  static const Color divider = Color(0xFFE0E0E0);
  static const Color border = Color(0xFFBDBDBD);
}
```

#### `lib/core/themes/app_text_styles.dart`
```dart
import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  static const String fontFamily = 'Vazir';

  // Headings
  static const TextStyle h1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle h3 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle h4 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // Body
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    color: AppColors.textSecondary,
  );

  // Button
  static const TextStyle button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  // Caption
  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    color: AppColors.textSecondary,
  );
}
```

#### `lib/core/themes/app_theme.dart`
```dart
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: AppTextStyles.fontFamily,
      
      // Colors
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        error: AppColors.error,
        background: AppColors.background,
        surface: AppColors.surface,
        brightness: Brightness.light,
      ),
      
      // AppBar
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      
      // Card
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(8),
      ),
      
      // Input
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      
      // Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: AppTextStyles.button,
        ),
      ),
      
      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: AppTextStyles.button,
        ),
      ),
      
      // Divider
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
```

### گام 1.11: Common Widgets

#### `lib/core/widgets/custom_text_field.dart`
```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int? maxLines;
  final int? maxLength;
  final bool readOnly;
  final VoidCallback? onTap;
  final List<TextInputFormatter>? inputFormatters;

  const CustomTextField({
    Key? key,
    required this.controller,
    required this.label,
    this.hint,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.maxLength,
    this.readOnly = false,
    this.onTap,
    this.inputFormatters,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
      ),
      validator: validator,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: maxLines,
      maxLength: maxLength,
      readOnly: readOnly,
      onTap: onTap,
      inputFormatters: inputFormatters,
    );
  }
}
```

#### `lib/core/widgets/custom_button.dart`
```dart
import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;

  const CustomButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: backgroundColor != null
          ? ElevatedButton.styleFrom(backgroundColor: backgroundColor)
          : null,
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon),
                  const SizedBox(width: 8),
                ],
                Text(
                  text,
                  style: textColor != null ? TextStyle(color: textColor) : null,
                ),
              ],
            ),
    );
  }
}
```

#### `lib/core/widgets/loading_widget.dart`
```dart
import 'package:flutter/material.dart';

class LoadingWidget extends StatelessWidget {
  final String? message;

  const LoadingWidget({Key? key, this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message!),
          ],
        ],
      ),
    );
  }
}
```

#### `lib/core/widgets/error_widget.dart`
```dart
import 'package:flutter/material.dart';
import '../themes/app_colors.dart';

class ErrorDisplayWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorDisplayWidget({
    Key? key,
    required this.message,
    this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('تلاش مجدد'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

#### `lib/core/widgets/empty_state_widget.dart`
```dart
import 'package:flutter/material.dart';

class EmptyStateWidget extends StatelessWidget {
  final String message;
  final IconData icon;
  final VoidCallback? onAction;
  final String? actionText;

  const EmptyStateWidget({
    Key? key,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.onAction,
    this.actionText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            if (onAction != null && actionText != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

#### `lib/core/widgets/confirmation_dialog.dart`
```dart
import 'package:flutter/material.dart';
import '../themes/app_colors.dart';

class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final VoidCallback onConfirm;

  const ConfirmationDialog({
    Key? key,
    required this.title,
    required this.message,
    this.confirmText = 'تایید',
    this.cancelText = 'لغو',
    required this.onConfirm,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(cancelText),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            onConfirm();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
          ),
          child: Text(confirmText),
        ),
      ],
    );
  }

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'تایید',
    String cancelText = 'لغو',
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }
}
```

---

## ✅ چک‌لیست فاز 1

قبل از رفتن به فاز 2، مطمئن شوید:

- [ ] `pubspec.yaml` با تمام dependencies تنظیم شده
- [ ] فونت Vazir دانلود و در `assets/fonts/` قرار گرفته
- [ ] تمام فولدرهای `core/` ایجاد شده
- [ ] Constants و Enums نوشته شده
- [ ] Error Handling کامل شده
- [ ] Utils (Number, Date, Validators) پیاده‌سازی شده
- [ ] Theme و Colors تنظیم شده
- [ ] Widget های مشترک نوشته شده
- [ ] پروژه بدون خطا کامپایل می‌شود

**بعد از تکمیل فاز 1، به فایل `PHASE_2_AUTH.md` مراجعه کنید.**

