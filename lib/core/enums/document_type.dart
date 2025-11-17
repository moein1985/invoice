enum DocumentType {
  tempProforma,  // پیش‌فاکتور موقت (با تمام جزئیات)
  proforma,      // پیش‌فاکتور (برای مشتری)
  invoice,       // فاکتور
  returnInvoice; // برگشت از فروش

  String toFarsi() {
    switch (this) {
      case DocumentType.tempProforma:
        return 'پیش‌فاکتور موقت';
      case DocumentType.proforma:
        return 'پیش‌فاکتور';
      case DocumentType.invoice:
        return 'فاکتور';
      case DocumentType.returnInvoice:
        return 'برگشت از فروش';
    }
  }

  /// آیا این نوع سند باید تمام جزئیات داخلی را نمایش دهد؟
  bool get showInternalDetails {
    return this == DocumentType.tempProforma;
  }

  /// آیا این نوع سند قابل تبدیل به نوع دیگر است؟
  DocumentType? get nextType {
    switch (this) {
      case DocumentType.tempProforma:
        return DocumentType.proforma;
      case DocumentType.proforma:
        return DocumentType.invoice;
      case DocumentType.invoice:
      case DocumentType.returnInvoice:
        return null;
    }
  }

  /// متن دکمه تبدیل
  String? get convertButtonText {
    switch (this) {
      case DocumentType.tempProforma:
        return 'تبدیل به پیش‌فاکتور';
      case DocumentType.proforma:
        return 'تبدیل به فاکتور';
      case DocumentType.invoice:
      case DocumentType.returnInvoice:
        return null;
    }
  }
}