# 🔧 دستور العمل حل مشکل Role Enum

## مشکل:
کاربر admin قدیمی با `role: 'user'` ذخیره شده که با enum جدید سازگار نیست.

## راه حل:

### 1. برنامه را ببندید (q در terminal)

### 2. فایل‌های دیتابیس را پاک کنید:
```powershell
Remove-Item -Path "C:\Users\Moein\Documents\*.hive" -Force
Remove-Item -Path "C:\Users\Moein\Documents\*.lock" -Force
```

### 3. برنامه را دوباره اجرا کنید:
```powershell
flutter run -d windows
```

### 4. با کاربر جدید لاگین کنید:
- **Username**: `admin`
- **Password**: `admin123`

---

## ✅ حل شده:
- فایل `user_roles.dart` آپدیت شد
- admin جدید با `role: 'admin'` ایجاد می‌شود
- برنامه آماده تست است
