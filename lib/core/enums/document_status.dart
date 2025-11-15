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