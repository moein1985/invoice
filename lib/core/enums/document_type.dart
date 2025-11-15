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