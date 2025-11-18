class UserRoles {
  static const String admin = 'admin';
  static const String manager = 'manager';
  static const String supervisor = 'supervisor';
  static const String employee = 'employee';
  
  @Deprecated('Use employee instead')
  static const String user = 'employee'; // برای سازگاری با کد قدیمی
}