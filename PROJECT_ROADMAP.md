# نقشه راه پروژه مدیریت فاکتور و پیش‌فاکتور
## Flutter + Clean Architecture + BLoC

---

## 📋 مشخصات پروژه

### اطلاعات کلی
- **زبان برنامه‌نویسی**: Dart & Flutter
- **معماری**: Clean Architecture
- **State Management**: BLoC (flutter_bloc)
- **دیتابیس**: Hive (NoSQL Local Database)
- **پلتفرم**: Windows Desktop
- **زبان رابط کاربری**: فارسی (RTL)

### قابلیت‌های اصلی
1. مدیریت کاربران (Admin + Users)
2. مدیریت مشتریان
3. ایجاد و مدیریت فاکتور و پیش‌فاکتور
4. جستجوی پیشرفته
5. آمار و گزارشات
6. خروجی PDF, Excel و پرینت

---

## 🏗️ ساختار معماری (Clean Architecture)

```
┌─────────────────────────────────────────────┐
│         Presentation Layer                  │
│  (UI, Pages, Widgets, BLoC)                 │
└─────────────────┬───────────────────────────┘
                  │
┌─────────────────▼───────────────────────────┐
│           Domain Layer                      │
│  (Entities, Use Cases, Repositories)        │
└─────────────────┬───────────────────────────┘
                  │
┌─────────────────▼───────────────────────────┐
│            Data Layer                       │
│  (Models, Data Sources, Repository Impl)    │
└─────────────────────────────────────────────┘
```

---

## 📁 ساختار فولدرها

```
lib/
├── main.dart
│
├── core/
│   ├── constants/
│   │   ├── app_constants.dart          # ثابت‌های برنامه
│   │   ├── user_roles.dart             # نقش‌های کاربری (Admin, User)
│   │   └── hive_boxes.dart             # نام‌های Box های Hive
│   │
│   ├── enums/
│   │   ├── document_type.dart          # فاکتور یا پیش‌فاکتور
│   │   └── document_status.dart        # وضعیت سند
│   │
│   ├── utils/
│   │   ├── date_utils.dart             # تبدیل میلادی/شمسی
│   │   ├── number_formatter.dart       # فرمت سه رقمی + اعداد فارسی
│   │   ├── validators.dart             # اعتبارسنجی فرم‌ها
│   │   └── string_extensions.dart      # توابع کمکی String
│   │
│   ├── widgets/
│   │   ├── custom_text_field.dart      # TextField سفارشی
│   │   ├── custom_button.dart          # دکمه سفارشی
│   │   ├── custom_dropdown.dart        # Dropdown سفارشی
│   │   ├── loading_widget.dart         # لودینگ
│   │   ├── error_widget.dart           # نمایش خطا
│   │   ├── empty_state_widget.dart     # حالت خالی
│   │   └── confirmation_dialog.dart    # دیالوگ تایید
│   │
│   ├── themes/
│   │   ├── app_theme.dart              # تم اصلی (RTL + فارسی)
│   │   ├── app_colors.dart             # رنگ‌ها
│   │   └── app_text_styles.dart        # استایل متن‌ها
│   │
│   └── error/
│       ├── failures.dart               # کلاس‌های خطا
│       └── exceptions.dart             # Exception ها
│
├── features/
│   │
│   ├── auth/                           # احراز هویت
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   └── user_model.dart
│   │   │   ├── datasources/
│   │   │   │   └── auth_local_datasource.dart
│   │   │   └── repositories/
│   │   │       └── auth_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── user_entity.dart
│   │   │   ├── repositories/
│   │   │   │   └── auth_repository.dart
│   │   │   └── usecases/
│   │   │       ├── login_usecase.dart
│   │   │       ├── logout_usecase.dart
│   │   │       └── get_current_user_usecase.dart
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── auth_bloc.dart
│   │       │   ├── auth_event.dart
│   │       │   └── auth_state.dart
│   │       ├── pages/
│   │       │   └── login_page.dart
│   │       └── widgets/
│   │           └── login_form.dart
│   │
│   ├── user_management/                # مدیریت کاربران (Admin فقط)
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   └── user_model.dart     # همان مدل auth
│   │   │   ├── datasources/
│   │   │   │   └── user_local_datasource.dart
│   │   │   └── repositories/
│   │   │       └── user_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── user_entity.dart    # همان entity auth
│   │   │   ├── repositories/
│   │   │   │   └── user_repository.dart
│   │   │   └── usecases/
│   │   │       ├── create_user_usecase.dart
│   │   │       ├── update_user_usecase.dart
│   │   │       ├── delete_user_usecase.dart
│   │   │       ├── get_all_users_usecase.dart
│   │   │       └── toggle_user_status_usecase.dart
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── user_management_bloc.dart
│   │       │   ├── user_management_event.dart
│   │       │   └── user_management_state.dart
│   │       ├── pages/
│   │       │   ├── users_list_page.dart
│   │       │   └── user_form_page.dart
│   │       └── widgets/
│   │           ├── user_list_item.dart
│   │           └── user_form_fields.dart
│   │
│   ├── customer/                       # مدیریت مشتریان
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   └── customer_model.dart
│   │   │   ├── datasources/
│   │   │   │   └── customer_local_datasource.dart
│   │   │   └── repositories/
│   │   │       └── customer_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── customer_entity.dart
│   │   │   ├── repositories/
│   │   │   │   └── customer_repository.dart
│   │   │   └── usecases/
│   │   │       ├── create_customer_usecase.dart
│   │   │       ├── update_customer_usecase.dart
│   │   │       ├── delete_customer_usecase.dart
│   │   │       ├── get_customers_usecase.dart
│   │   │       └── search_customers_usecase.dart
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── customer_bloc.dart
│   │       │   ├── customer_event.dart
│   │       │   └── customer_state.dart
│   │       ├── pages/
│   │       │   ├── customers_list_page.dart
│   │       │   └── customer_form_page.dart
│   │       └── widgets/
│   │           ├── customer_list_item.dart
│   │           ├── customer_search_bar.dart
│   │           └── customer_selector_dialog.dart
│   │
│   ├── document/                       # فاکتور و پیش‌فاکتور
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   ├── document_model.dart
│   │   │   │   └── document_item_model.dart
│   │   │   ├── datasources/
│   │   │   │   └── document_local_datasource.dart
│   │   │   └── repositories/
│   │   │       └── document_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── document_entity.dart
│   │   │   │   └── document_item_entity.dart
│   │   │   ├── repositories/
│   │   │   │   └── document_repository.dart
│   │   │   └── usecases/
│   │   │       ├── create_document_usecase.dart
│   │   │       ├── update_document_usecase.dart
│   │   │       ├── delete_document_usecase.dart
│   │   │       ├── get_documents_usecase.dart
│   │   │       ├── search_documents_usecase.dart
│   │   │       ├── get_document_by_id_usecase.dart
│   │   │       └── convert_proforma_to_invoice_usecase.dart
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── document_bloc.dart
│   │       │   ├── document_event.dart
│   │       │   ├── document_state.dart
│   │       │   ├── document_form_bloc.dart     # برای فرم جداگانه
│   │       │   ├── document_form_event.dart
│   │       │   └── document_form_state.dart
│   │       ├── pages/
│   │       │   ├── documents_list_page.dart
│   │       │   ├── document_form_page.dart
│   │       │   └── document_preview_page.dart
│   │       └── widgets/
│   │           ├── document_list_item.dart
│   │           ├── document_search_bar.dart
│   │           ├── document_filter_chips.dart
│   │           ├── document_item_table.dart
│   │           ├── document_item_row.dart
│   │           ├── add_item_dialog.dart
│   │           └── document_summary_card.dart
│   │
│   ├── statistics/                     # آمار و گزارشات
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   └── statistics_model.dart
│   │   │   ├── datasources/
│   │   │   │   └── statistics_local_datasource.dart
│   │   │   └── repositories/
│   │   │       └── statistics_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── statistics_entity.dart
│   │   │   ├── repositories/
│   │   │   │   └── statistics_repository.dart
│   │   │   └── usecases/
│   │   │       ├── get_user_statistics_usecase.dart
│   │   │       └── get_period_statistics_usecase.dart
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── statistics_bloc.dart
│   │       │   ├── statistics_event.dart
│   │       │   └── statistics_state.dart
│   │       ├── pages/
│   │       │   └── statistics_page.dart
│   │       └── widgets/
│   │           ├── stat_card.dart
│   │           ├── period_selector.dart
│   │           └── statistics_chart.dart
│   │
│   ├── export/                         # خروجی PDF, Excel, Print
│   │   ├── data/
│   │   │   ├── services/
│   │   │   │   ├── excel_export_service.dart
│   │   │   │   ├── pdf_export_service.dart
│   │   │   │   └── print_service.dart
│   │   │   └── repositories/
│   │   │       └── export_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── repositories/
│   │   │   │   └── export_repository.dart
│   │   │   └── usecases/
│   │   │       ├── export_to_excel_usecase.dart
│   │   │       ├── export_to_pdf_usecase.dart
│   │   │       └── print_document_usecase.dart
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── export_bloc.dart
│   │       │   ├── export_event.dart
│   │       │   └── export_state.dart
│   │       └── widgets/
│   │           └── export_options_dialog.dart
│   │
│   ├── dashboard/                      # داشبورد کاربر
│   │   └── presentation/
│   │       ├── pages/
│   │       │   └── dashboard_page.dart
│   │       └── widgets/
│   │           ├── quick_action_card.dart
│   │           └── recent_documents_list.dart
│   │
│   └── settings/                       # تنظیمات
│       └── presentation/
│           └── pages/
│               └── settings_page.dart
│
└── injection_container.dart            # Dependency Injection
```

---

## 📦 Dependencies (pubspec.yaml)

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
  
  # فونت‌های فارسی
  fonts:
    - family: Vazir
      fonts:
        - asset: assets/fonts/Vazir-Regular.ttf
        - asset: assets/fonts/Vazir-Bold.ttf
          weight: 700
```

---

## 🎯 Entities (Domain Layer)

### 1. UserEntity
```dart
class UserEntity extends Equatable {
  final String id;
  final String username;
  final String password;  // باید hash شود
  final String fullName;
  final UserRole role;    // admin یا user
  final bool isActive;
  final DateTime createdAt;

  const UserEntity({
    required this.id,
    required this.username,
    required this.password,
    required this.fullName,
    required this.role,
    required this.isActive,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, username, fullName, role, isActive];
}

enum UserRole { admin, user }
```

### 2. CustomerEntity
```dart
class CustomerEntity extends Equatable {
  final String id;
  final String userId;        // متعلق به کدام کاربر
  final String customerCode;  // کد مشتری
  final String fullName;
  final String phone;
  final String address;
  final String? email;
  final String? notes;
  final DateTime createdAt;

  const CustomerEntity({
    required this.id,
    required this.userId,
    required this.customerCode,
    required this.fullName,
    required this.phone,
    required this.address,
    this.email,
    this.notes,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, userId, customerCode, fullName, phone];
}
```

### 3. DocumentEntity (فاکتور و پیش‌فاکتور)
```dart
class DocumentEntity extends Equatable {
  final String id;
  final String userId;
  final String documentNumber;        // شماره سند
  final DocumentType documentType;    // invoice یا proforma
  final String customerId;
  final DateTime documentDate;        // تاریخ قابل ویرایش
  final List<DocumentItemEntity> items;
  final double totalAmount;           // جمع کل
  final double discount;              // تخفیف
  final double finalAmount;           // مبلغ نهایی
  final DocumentStatus status;        // پرداخت شده / نشده
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DocumentEntity({
    required this.id,
    required this.userId,
    required this.documentNumber,
    required this.documentType,
    required this.customerId,
    required this.documentDate,
    required this.items,
    required this.totalAmount,
    required this.discount,
    required this.finalAmount,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [id, documentNumber, documentType, customerId];
}

enum DocumentType { invoice, proforma }
enum DocumentStatus { paid, unpaid, pending }
```

### 4. DocumentItemEntity (ردیف فاکتور)
```dart
class DocumentItemEntity extends Equatable {
  final String id;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final double profitPercentage;  // درصد سود
  final String supplier;          // تامین کننده
  final String? description;      // توضیحات

  const DocumentItemEntity({
    required this.id,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.profitPercentage,
    required this.supplier,
    this.description,
  });

  @override
  List<Object?> get props => [id, productName, quantity, unitPrice];
}
```

### 5. StatisticsEntity
```dart
class StatisticsEntity extends Equatable {
  final int totalInvoices;
  final int totalProformas;
  final double totalInvoicesAmount;
  final double totalProformasAmount;
  final DateTime startDate;
  final DateTime endDate;

  const StatisticsEntity({
    required this.totalInvoices,
    required this.totalProformas,
    required this.totalInvoicesAmount,
    required this.totalProformasAmount,
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object?> get props => [
        totalInvoices,
        totalProformas,
        totalInvoicesAmount,
        totalProformasAmount,
      ];
}
```

---

## 🗄️ Hive Database Setup

### Hive Boxes
```dart
// core/constants/hive_boxes.dart
class HiveBoxes {
  static const String users = 'users_box';
  static const String currentUser = 'current_user_box';
  static const String customers = 'customers_box';
  static const String documents = 'documents_box';
  static const String settings = 'settings_box';
}
```

### Initialize Hive در main.dart
```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Register Adapters
  Hive.registerAdapter(UserModelAdapter());
  Hive.registerAdapter(CustomerModelAdapter());
  Hive.registerAdapter(DocumentModelAdapter());
  Hive.registerAdapter(DocumentItemModelAdapter());
  
  // Open Boxes
  await Hive.openBox<UserModel>(HiveBoxes.users);
  await Hive.openBox<String>(HiveBoxes.currentUser);
  await Hive.openBox<CustomerModel>(HiveBoxes.customers);
  await Hive.openBox<DocumentModel>(HiveBoxes.documents);
  await Hive.openBox(HiveBoxes.settings);
  
  // ایجاد کاربر ادمین پیش‌فرض
  await createDefaultAdmin();
  
  // Dependency Injection
  await initializeDependencies();
  
  runApp(const MyApp());
}

Future<void> createDefaultAdmin() async {
  final usersBox = Hive.box<UserModel>(HiveBoxes.users);
  
  // بررسی اگر ادمین وجود ندارد
  final adminExists = usersBox.values.any(
    (user) => user.username == 'ادمین' && user.role == 'admin',
  );
  
  if (!adminExists) {
    final admin = UserModel(
      id: const Uuid().v4(),
      username: 'ادمین',
      password: '12321',  // باید hash شود
      fullName: 'مدیر سیستم',
      role: 'admin',
      isActive: true,
      createdAt: DateTime.now(),
    );
    await usersBox.put(admin.id, admin);
  }
}
```

---

## 🎨 Theme & Styling

### app_theme.dart
```dart
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Vazir',
      
      // RTL Support
      textDirection: TextDirection.rtl,
      
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ),
      
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
```

### app_colors.dart
```dart
class AppColors {
  static const Color primary = Color(0xFF1976D2);
  static const Color secondary = Color(0xFF424242);
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFFA726);
  static const Color background = Color(0xFFF5F5F5);
}
```

---

## 🔧 Core Utils

### number_formatter.dart
```dart
class NumberFormatter {
  // تبدیل عدد به فرمت سه رقمی: 1234567 => 1,234,567
  static String formatWithComma(double number) {
    final formatter = NumberFormat('#,###', 'en_US');
    return formatter.format(number);
  }
  
  // تبدیل به اعداد فارسی: 123 => ۱۲۳
  static String toPersianNumber(String number) {
    return number.toPersianDigit();
  }
  
  // ترکیب هر دو: 1234567 => ۱,۲۳۴,۵۶۷ ریال
  static String formatCurrency(double amount) {
    final formatted = formatWithComma(amount);
    final persian = toPersianNumber(formatted);
    return '$persian ریال';
  }
}
```

### date_utils.dart
```dart
class PersianDateUtils {
  // تبدیل DateTime به تاریخ شمسی
  static String toJalali(DateTime date) {
    final jalali = Jalali.fromDateTime(date);
    return '${jalali.year}/${jalali.month.toString().padLeft(2, '0')}/${jalali.day.toString().padLeft(2, '0')}';
  }
  
  // تبدیل تاریخ شمسی به DateTime
  static DateTime fromJalali(int year, int month, int day) {
    final jalali = Jalali(year, month, day);
    return jalali.toDateTime();
  }
  
  // فرمت کامل فارسی
  static String formatPersian(DateTime date) {
    final jalali = Jalali.fromDateTime(date);
    return '${jalali.formatter.wN} ${jalali.day} ${jalali.formatter.mN} ${jalali.year}';
  }
}
```

### validators.dart
```dart
class Validators {
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName الزامی است';
    }
    return null;
  }
  
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'شماره تلفن الزامی است';
    }
    if (value.length < 11) {
      return 'شماره تلفن معتبر نیست';
    }
    return null;
  }
  
  static String? validateNumber(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName الزامی است';
    }
    if (double.tryParse(value) == null) {
      return '$fieldName باید عدد باشد';
    }
    return null;
  }
  
  static String? validatePositiveNumber(String? value, String fieldName) {
    final error = validateNumber(value, fieldName);
    if (error != null) return error;
    
    if (double.parse(value!) <= 0) {
      return '$fieldName باید بزرگتر از صفر باشد';
    }
    return null;
  }
}
```

---

## 🔄 BLoC Pattern Implementation

### مثال: AuthBloc

#### auth_event.dart
```dart
abstract class AuthEvent extends Equatable {
  const AuthEvent();
  
  @override
  List<Object?> get props => [];
}

class LoginRequested extends AuthEvent {
  final String username;
  final String password;
  
  const LoginRequested({required this.username, required this.password});
  
  @override
  List<Object?> get props => [username, password];
}

class LogoutRequested extends AuthEvent {}

class CheckAuthStatus extends AuthEvent {}
```

#### auth_state.dart
```dart
abstract class AuthState extends Equatable {
  const AuthState();
  
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final UserEntity user;
  
  const AuthAuthenticated({required this.user});
  
  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  
  const AuthError({required this.message});
  
  @override
  List<Object?> get props => [message];
}
```

#### auth_bloc.dart
```dart
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final LogoutUseCase logoutUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;
  
  AuthBloc({
    required this.loginUseCase,
    required this.logoutUseCase,
    required this.getCurrentUserUseCase,
  }) : super(AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<CheckAuthStatus>(_onCheckAuthStatus);
  }
  
  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    final result = await loginUseCase(
      username: event.username,
      password: event.password,
    );
    
    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (user) => emit(AuthAuthenticated(user: user)),
    );
  }
  
  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await logoutUseCase();
    emit(AuthUnauthenticated());
  }
  
  Future<void> _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) async {
    final user = await getCurrentUserUseCase();
    if (user != null) {
      emit(AuthAuthenticated(user: user));
    } else {
      emit(AuthUnauthenticated());
    }
  }
}
```

---

## 📱 Screen Flow & Navigation

### Navigation Structure
```
LoginPage (ورود)
    │
    ├─→ [Admin] → UsersListPage
    │               ├─→ UserFormPage (ایجاد/ویرایش کاربر)
    │               └─→ Logout
    │
    └─→ [User] → DashboardPage
                    ├─→ DocumentsListPage
                    │     ├─→ DocumentFormPage (ایجاد/ویرایش)
                    │     └─→ DocumentPreviewPage (پیش‌نمایش + خروجی)
                    │
                    ├─→ CustomersListPage
                    │     └─→ CustomerFormPage
                    │
                    ├─→ StatisticsPage
                    │
                    ├─→ SettingsPage
                    │
                    └─→ Logout
```

### Main App Structure
```dart
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<AuthBloc>()..add(CheckAuthStatus())),
      ],
      child: MaterialApp(
        title: 'مدیریت فاکتور',
        theme: AppTheme.lightTheme,
        locale: const Locale('fa', 'IR'),
        supportedLocales: const [Locale('fa', 'IR')],
        home: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is AuthAuthenticated) {
              if (state.user.role == UserRole.admin) {
                return const UsersListPage();
              } else {
                return const DashboardPage();
              }
            }
            return const LoginPage();
          },
        ),
      ),
    );
  }
}
```

---

## 🎯 Use Cases Examples

### LoginUseCase
```dart
class LoginUseCase {
  final AuthRepository repository;
  
  LoginUseCase(this.repository);
  
  Future<Either<Failure, UserEntity>> call({
    required String username,
    required String password,
  }) async {
    return await repository.login(username, password);
  }
}
```

### CreateDocumentUseCase
```dart
class CreateDocumentUseCase {
  final DocumentRepository repository;
  
  CreateDocumentUseCase(this.repository);
  
  Future<Either<Failure, DocumentEntity>> call(DocumentEntity document) async {
    // اعتبارسنجی
    if (document.items.isEmpty) {
      return Left(ValidationFailure('حداقل یک ردیف باید وارد شود'));
    }
    
    return await repository.createDocument(document);
  }
}
```

### SearchDocumentsUseCase
```dart
class SearchDocumentsUseCase {
  final DocumentRepository repository;
  
  SearchDocumentsUseCase(this.repository);
  
  Future<Either<Failure, List<DocumentEntity>>> call({
    required String userId,
    String? query,
    DocumentType? type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await repository.searchDocuments(
      userId: userId,
      query: query,
      type: type,
      startDate: startDate,
      endDate: endDate,
    );
  }
}
```

---

## 🖨️ Export Features

### PDF Export Service
```dart
class PdfExportService {
  Future<File> generateInvoicePdf(DocumentEntity document, CustomerEntity customer) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        textDirection: pw.TextDirection.rtl,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // عنوان سند
              pw.Text(
                document.documentType == DocumentType.invoice ? 'فاکتور' : 'پیش‌فاکتور',
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 20),
              
              // اطلاعات مشتری
              pw.Text('نام مشتری: ${customer.fullName}'),
              pw.Text('شماره تماس: ${customer.phone}'),
              pw.Text('آدرس: ${customer.address}'),
              pw.SizedBox(height: 20),
              
              // جدول ردیف‌ها
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  // هدر جدول
                  pw.TableRow(children: [
                    pw.Text('ردیف'),
                    pw.Text('نام محصول'),
                    pw.Text('تعداد'),
                    pw.Text('قیمت واحد'),
                    pw.Text('قیمت کل'),
                  ]),
                  // ردیف‌ها
                  ...document.items.asMap().entries.map((entry) {
                    final item = entry.value;
                    return pw.TableRow(children: [
                      pw.Text('${entry.key + 1}'),
                      pw.Text(item.productName),
                      pw.Text('${item.quantity}'),
                      pw.Text(NumberFormatter.formatCurrency(item.unitPrice)),
                      pw.Text(NumberFormatter.formatCurrency(item.totalPrice)),
                    ]);
                  }),
                ],
              ),
              
              pw.SizedBox(height: 20),
              
              // جمع کل
              pw.Text('جمع کل: ${NumberFormatter.formatCurrency(document.finalAmount)}'),
            ],
          );
        },
      ),
    );
    
    // ذخیره فایل
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/invoice_${document.documentNumber}.pdf');
    await file.writeAsBytes(await pdf.save());
    
    return file;
  }
}
```

### Excel Export Service
```dart
class ExcelExportService {
  Future<File> exportDocumentsToExcel(List<DocumentEntity> documents) async {
    final excel = Excel.createExcel();
    final sheet = excel['اسناد'];
    
    // هدر
    sheet.appendRow([
      'شماره سند',
      'نوع',
      'تاریخ',
      'مشتری',
      'مبلغ کل',
      'تخفیف',
      'مبلغ نهایی',
    ]);
    
    // داده‌ها
    for (final doc in documents) {
      sheet.appendRow([
        doc.documentNumber,
        doc.documentType == DocumentType.invoice ? 'فاکتور' : 'پیش‌فاکتور',
        PersianDateUtils.toJalali(doc.documentDate),
        doc.customerId, // باید نام مشتری باشد
        doc.totalAmount,
        doc.discount,
        doc.finalAmount,
      ]);
    }
    
    // ذخیره
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/documents_export.xlsx');
    await file.writeAsBytes(excel.encode()!);
    
    return file;
  }
}
```

### Print Service
```dart
class PrintService {
  Future<void> printDocument(DocumentEntity document, CustomerEntity customer) async {
    await Printing.layoutPdf(
      onLayout: (format) async {
        final pdfService = PdfExportService();
        final file = await pdfService.generateInvoicePdf(document, customer);
        return file.readAsBytes();
      },
    );
  }
}
```

---

## 🔍 Search Implementation

### جستجوی پیشرفته در اسناد
```dart
// در DocumentRepository
Future<List<DocumentEntity>> searchDocuments({
  required String userId,
  String? query,           // جستجو در شماره سند، نام مشتری، یادداشت
  DocumentType? type,      // فیلتر نوع
  DateTime? startDate,     // فیلتر تاریخ
  DateTime? endDate,
  DocumentStatus? status,  // فیلتر وضعیت
}) async {
  final box = Hive.box<DocumentModel>(HiveBoxes.documents);
  
  var results = box.values.where((doc) => doc.userId == userId);
  
  // فیلتر نوع
  if (type != null) {
    results = results.where((doc) => doc.documentType == type.toString());
  }
  
  // فیلتر تاریخ
  if (startDate != null) {
    results = results.where((doc) => doc.documentDate.isAfter(startDate));
  }
  if (endDate != null) {
    results = results.where((doc) => doc.documentDate.isBefore(endDate));
  }
  
  // جستجوی متنی
  if (query != null && query.isNotEmpty) {
    results = results.where((doc) {
      return doc.documentNumber.contains(query) ||
             (doc.notes?.contains(query) ?? false);
      // اینجا باید نام مشتری هم چک شود
    });
  }
  
  return results.map((model) => model.toEntity()).toList();
}
```

### جستجو در ردیف‌های سند
```dart
List<DocumentItemEntity> searchItems(String query) {
  return allItems.where((item) {
    return item.productName.contains(query) ||
           item.supplier.contains(query) ||
           (item.description?.contains(query) ?? false);
  }).toList();
}
```

---

## 📊 Statistics Calculation

```dart
class StatisticsRepository {
  Future<StatisticsEntity> getUserStatistics({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final box = Hive.box<DocumentModel>(HiveBoxes.documents);
    
    final userDocs = box.values.where((doc) =>
      doc.userId == userId &&
      doc.documentDate.isAfter(startDate) &&
      doc.documentDate.isBefore(endDate)
    );
    
    final invoices = userDocs.where((d) => d.documentType == 'invoice');
    final proformas = userDocs.where((d) => d.documentType == 'proforma');
    
    return StatisticsEntity(
      totalInvoices: invoices.length,
      totalProformas: proformas.length,
      totalInvoicesAmount: invoices.fold(0.0, (sum, doc) => sum + doc.finalAmount),
      totalProformasAmount: proformas.fold(0.0, (sum, doc) => sum + doc.finalAmount),
      startDate: startDate,
      endDate: endDate,
    );
  }
}
```

---

## ⚙️ Dependency Injection (GetIt)

### injection_container.dart
```dart
final getIt = GetIt.instance;

Future<void> initializeDependencies() async {
  // Data Sources
  getIt.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(),
  );
  
  // Repositories
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(getIt()),
  );
  
  // Use Cases
  getIt.registerLazySingleton(() => LoginUseCase(getIt()));
  getIt.registerLazySingleton(() => LogoutUseCase(getIt()));
  
  // BLoCs
  getIt.registerFactory(() => AuthBloc(
    loginUseCase: getIt(),
    logoutUseCase: getIt(),
    getCurrentUserUseCase: getIt(),
  ));
  
  // تکرار برای سایر features...
}
```

---

## 🧪 Testing Strategy

### Unit Tests
- تست Use Cases
- تست Repositories
- تست Utils (Formatters, Validators)

### Widget Tests
- تست صفحات
- تست ویجت‌های مشترک

### Integration Tests
- تست جریان کامل (ورود، ایجاد فاکتور، خروجی)

---

## 📝 Implementation Steps (مراحل پیاده‌سازی)

### Phase 1: Setup & Core (هفته 1)
1. ✅ ایجاد ساختار پروژه
2. ✅ تنظیم Dependencies
3. ✅ ایجاد Theme و Colors
4. ✅ پیاده‌سازی Utils (Date, Number Formatter, Validators)
5. ✅ تنظیم Hive و ایجاد Boxes
6. ✅ ایجاد ویجت‌های مشترک (TextField, Button, Dialog)

### Phase 2: Authentication (هفته 1-2)
1. ✅ پیاده‌سازی UserEntity & UserModel
2. ✅ ایجاد AuthRepository & DataSource
3. ✅ پیاده‌سازی Use Cases (Login, Logout)
4. ✅ ایجاد AuthBloc
5. ✅ طراحی LoginPage
6. ✅ ایجاد کاربر Admin پیش‌فرض

### Phase 3: User Management (هفته 2)
1. ✅ پیاده‌سازی UserManagementBloc
2. ✅ طراحی UsersListPage (Admin)
3. ✅ طراحی UserFormPage
4. ✅ CRUD عملیات کاربران

### Phase 4: Customer Management (هفته 2-3)
1. ✅ پیاده‌سازی CustomerEntity & Model
2. ✅ ایجاد CustomerRepository
3. ✅ پیاده‌سازی CustomerBloc
4. ✅ طراحی CustomersListPage
5. ✅ طراحی CustomerFormPage
6. ✅ جستجوی مشتریان

### Phase 5: Document Management (هفته 3-4)
1. ✅ پیاده‌سازی DocumentEntity & DocumentItemEntity
2. ✅ ایجاد DocumentRepository
3. ✅ پیاده‌سازی DocumentBloc & DocumentFormBloc
4. ✅ طراحی DocumentsListPage
5. ✅ طراحی DocumentFormPage (با جدول ردیف‌ها)
6. ✅ جستجوی پیشرفته
7. ✅ DocumentPreviewPage

### Phase 6: Statistics (هفته 4)
1. ✅ پیاده‌سازی StatisticsRepository
2. ✅ ایجاد StatisticsBloc
3. ✅ طراحی StatisticsPage
4. ✅ کارت‌های آماری
5. ✅ فیلتر بازه زمانی

### Phase 7: Export & Print (هفته 5)
1. ✅ پیاده‌سازی PdfExportService
2. ✅ پیاده‌سازی ExcelExportService
3. ✅ پیاده‌سازی PrintService
4. ✅ ایجاد ExportBloc
5. ✅ طراحی ExportOptionsDialog

### Phase 8: Dashboard & Final Touches (هفته 5-6)
1. ✅ طراحی DashboardPage
2. ✅ اتصال تمام بخش‌ها
3. ✅ تنظیمات
4. ✅ بهینه‌سازی
5. ✅ Testing
6. ✅ مستندسازی

---

## 🚀 Key Features Checklist

### احراز هویت
- [ ] ورود با نام کاربری و رمز عبور
- [ ] کاربر Admin پیش‌فرض (ادمین / 12321)
- [ ] تشخیص نقش (Admin / User)
- [ ] خروج از سیستم

### مدیریت کاربران (Admin فقط)
- [ ] لیست کاربران
- [ ] ایجاد کاربر جدید
- [ ] ویرایش کاربر
- [ ] حذف کاربر
- [ ] فعال/غیرفعال کردن کاربر

### مدیریت مشتریان
- [ ] لیست مشتریان (هر کاربر فقط مشتریان خودش)
- [ ] افزودن مشتری
- [ ] ویرایش مشتری
- [ ] حذف مشتری
- [ ] جستجوی مشتری (نام، تلفن، کد)

### مدیریت اسناد (فاکتور و پیش‌فاکتور)
- [ ] لیست اسناد با فیلتر
- [ ] ایجاد فاکتور
- [ ] ایجاد پیش‌فاکتور
- [ ] ویرایش سند
- [ ] حذف سند
- [ ] انتخاب مشتری از لیست
- [ ] تنظیم تاریخ سند
- [ ] افزودن ردیف‌ها (نام، تعداد، قیمت، سود، تامین‌کننده، توضیحات)
- [ ] محاسبه خودکار جمع
- [ ] جستجوی پیشرفته (شماره، مشتری، تاریخ)
- [ ] جستجو در ردیف‌ها

### آمار و گزارشات
- [ ] تعداد فاکتورها
- [ ] تعداد پیش‌فاکتورها
- [ ] مجموع مبلغ فاکتورها
- [ ] مجموع مبلغ پیش‌فاکتورها
- [ ] فیلتر بازه زمانی (روز، هفته، ماه، سال)

### خروجی و چاپ
- [ ] Export به PDF
- [ ] Export به Excel
- [ ] پرینت مستقیم
- [ ] پیش‌نمایش قبل از چاپ

### پشتیبانی فارسی
- [ ] RTL Layout
- [ ] تاریخ شمسی
- [ ] اعداد فارسی (۰۱۲۳۴۵۶۷۸۹)
- [ ] فرمت مبلغ با کاما (۱۲۳،۴۵۶،۷۸۹ ریال)
- [ ] فونت Vazir

---

## 🎯 نکات مهم برای پیاده‌سازی

### 1. امنیت
- رمز عبور کاربران باید Hash شود (bcrypt یا sha256)
- اعتبارسنجی ورودی‌ها در تمام فرم‌ها
- جلوگیری از SQL Injection (در Hive مشکلی نیست)

### 2. Performance
- استفاده از ListView.builder برای لیست‌های بلند
- Pagination در لیست اسناد
- Debouncing در جستجو
- Lazy Loading برای داده‌ها

### 3. UX
- لودینگ برای عملیات طولانی
- پیام‌های خطای واضح و فارسی
- دیالوگ تایید برای حذف
- SnackBar برای موفقیت/خطا
- Empty State برای لیست‌های خالی

### 4. Error Handling
- Try-Catch در تمام عملیات
- Either Pattern برای Result
- پیام‌های خطای کاربرپسند

### 5. Code Quality
- Follow Clean Architecture
- Single Responsibility Principle
- Meaningful names
- کامنت‌گذاری کد فارسی
- Consistent formatting

---

## 📚 منابع و مستندات

### مستندات رسمی
- [Flutter Documentation](https://flutter.dev/docs)
- [BLoC Documentation](https://bloclibrary.dev)
- [Hive Documentation](https://docs.hivedb.dev)

### Packages
- flutter_bloc: https://pub.dev/packages/flutter_bloc
- hive: https://pub.dev/packages/hive
- shamsi_date: https://pub.dev/packages/shamsi_date
- pdf: https://pub.dev/packages/pdf
- excel: https://pub.dev/packages/excel

---

## ✅ Final Checklist قبل از تحویل

- [ ] تمام قابلیت‌ها پیاده‌سازی شده
- [ ] کاربر Admin پیش‌فرض کار می‌کند
- [ ] جداسازی داده‌های کاربران
- [ ] تمام جستجوها کار می‌کنند
- [ ] خروجی PDF/Excel/Print کار می‌کند
- [ ] آمار درست محاسبه می‌شود
- [ ] رابط کاربری فارسی و RTL
- [ ] فرمت اعداد و تاریخ فارسی
- [ ] Error Handling مناسب
- [ ] Testing انجام شده
- [ ] کد تمیز و مستند

---

**نکته نهایی**: این نقشه راه کامل است. می‌توانید مرحله به مرحله پیش بروید. اول Core و Authentication را پیاده کنید، سپس یک Feature کامل (مثلا Customer) را تمام کنید، بعد به سراغ بقیه بروید.

موفق باشید! 🚀
