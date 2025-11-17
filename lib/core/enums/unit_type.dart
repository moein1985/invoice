enum UnitType {
  piece,      // عدد
  kilogram,   // کیلوگرم
  meter,      // متر
  liter,      // لیتر
  box,        // بسته
  carton,     // کارتن
  package,    // بسته‌بندی
  roll,       // رول
  sheet,      // ورق
  set;        // ست

  String toFarsi() {
    switch (this) {
      case UnitType.piece:
        return 'عدد';
      case UnitType.kilogram:
        return 'کیلوگرم';
      case UnitType.meter:
        return 'متر';
      case UnitType.liter:
        return 'لیتر';
      case UnitType.box:
        return 'بسته';
      case UnitType.carton:
        return 'کارتن';
      case UnitType.package:
        return 'بسته‌بندی';
      case UnitType.roll:
        return 'رول';
      case UnitType.sheet:
        return 'ورق';
      case UnitType.set:
        return 'ست';
    }
  }

  static UnitType fromString(String unit) {
    switch (unit.toLowerCase()) {
      case 'عدد':
      case 'piece':
        return UnitType.piece;
      case 'کیلوگرم':
      case 'kilogram':
      case 'kg':
        return UnitType.kilogram;
      case 'متر':
      case 'meter':
      case 'm':
        return UnitType.meter;
      case 'لیتر':
      case 'liter':
      case 'l':
        return UnitType.liter;
      case 'بسته':
      case 'box':
        return UnitType.box;
      case 'کارتن':
      case 'carton':
        return UnitType.carton;
      case 'بسته‌بندی':
      case 'package':
        return UnitType.package;
      case 'رول':
      case 'roll':
        return UnitType.roll;
      case 'ورق':
      case 'sheet':
        return UnitType.sheet;
      case 'ست':
      case 'set':
        return UnitType.set;
      default:
        return UnitType.piece;
    }
  }
}
