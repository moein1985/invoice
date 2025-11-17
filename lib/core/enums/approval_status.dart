enum ApprovalStatus {
  notRequired,  // نیاز به تأیید ندارد
  pending,      // منتظر تأیید
  approved,     // تأیید شده
  rejected;     // رد شده

  String get persianName {
    switch (this) {
      case ApprovalStatus.notRequired:
        return 'نیاز به تأیید ندارد';
      case ApprovalStatus.pending:
        return 'منتظر تأیید';
      case ApprovalStatus.approved:
        return 'تأیید شده';
      case ApprovalStatus.rejected:
        return 'رد شده';
    }
  }

  String get icon {
    switch (this) {
      case ApprovalStatus.notRequired:
        return '✓';
      case ApprovalStatus.pending:
        return '⏳';
      case ApprovalStatus.approved:
        return '✅';
      case ApprovalStatus.rejected:
        return '❌';
    }
  }
}