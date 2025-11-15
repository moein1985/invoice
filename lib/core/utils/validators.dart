class Validators {
  /// اعتبارسنجی فیلد الزامی ساده
  static String? required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'این فیلد الزامی است';
    }
    return null;
  }

  /// اعتبارسنجی فیلد الزامی با نام فیلد
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