enum UserRole {
  employee,     // کارمند عادی
  supervisor,   // سرپرست
  manager,      // مدیر
  admin;        // ادمین

  String get persianName {
    switch (this) {
      case UserRole.employee:
        return 'کارمند';
      case UserRole.supervisor:
        return 'سرپرست';
      case UserRole.manager:
        return 'مدیر';
      case UserRole.admin:
        return 'ادمین';
    }
  }

  // حداکثر مبلغی که می‌تواند بدون تأیید تبدیل کند
  double get maxApprovalAmount {
    switch (this) {
      case UserRole.employee:
        return 10000000; // 10 میلیون
      case UserRole.supervisor:
        return 100000000; // 100 میلیون
      case UserRole.manager:
        return 500000000; // 500 میلیون
      case UserRole.admin:
        return double.infinity; // نامحدود
    }
  }

  bool canApprove(double amount) {
    return amount <= maxApprovalAmount;
  }
}