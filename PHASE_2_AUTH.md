# فاز 2: Authentication (احراز هویت)

این فاز شامل پیاده‌سازی کامل سیستم ورود و خروج با معماری Clean Architecture و BLoC است.

---

## 📁 ساختار Feature Auth

```
lib/features/auth/
├── data/
│   ├── models/
│   │   └── user_model.dart
│   ├── datasources/
│   │   └── auth_local_datasource.dart
│   └── repositories/
│       └── auth_repository_impl.dart
├── domain/
│   ├── entities/
│   │   └── user_entity.dart
│   ├── repositories/
│   │   └── auth_repository.dart
│   └── usecases/
│       ├── login_usecase.dart
│       ├── logout_usecase.dart
│       └── get_current_user_usecase.dart
└── presentation/
    ├── bloc/
    │   ├── auth_bloc.dart
    │   ├── auth_event.dart
    │   └── auth_state.dart
    ├── pages/
    │   └── login_page.dart
    └── widgets/
        └── login_form.dart
```

---

## گام 2.1: Domain Layer - Entity

### `lib/features/auth/domain/entities/user_entity.dart`

```dart
import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String username;
  final String password;
  final String fullName;
  final String role; // 'admin' یا 'user'
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

  bool get isAdmin => role == 'admin';
  bool get isUser => role == 'user';

  @override
  List<Object?> get props => [
        id,
        username,
        fullName,
        role,
        isActive,
        createdAt,
      ];

  @override
  String toString() {
    return 'UserEntity(id: $id, username: $username, fullName: $fullName, role: $role)';
  }
}
```

---

## گام 2.2: Domain Layer - Repository Interface

### `lib/features/auth/domain/repositories/auth_repository.dart`

```dart
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  /// ورود کاربر
  Future<Either<Failure, UserEntity>> login({
    required String username,
    required String password,
  });

  /// خروج کاربر
  Future<Either<Failure, void>> logout();

  /// دریافت کاربر فعلی
  Future<Either<Failure, UserEntity?>> getCurrentUser();

  /// بررسی اینکه کاربر وارد شده یا نه
  Future<bool> isLoggedIn();
}
```

---

## گام 2.3: Domain Layer - Use Cases

### `lib/features/auth/domain/usecases/login_usecase.dart`

```dart
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  Future<Either<Failure, UserEntity>> call({
    required String username,
    required String password,
  }) async {
    // اعتبارسنجی ورودی
    if (username.trim().isEmpty) {
      return const Left(ValidationFailure('نام کاربری را وارد کنید'));
    }

    if (password.trim().isEmpty) {
      return const Left(ValidationFailure('رمز عبور را وارد کنید'));
    }

    return await repository.login(
      username: username.trim(),
      password: password.trim(),
    );
  }
}
```

### `lib/features/auth/domain/usecases/logout_usecase.dart`

```dart
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/auth_repository.dart';

class LogoutUseCase {
  final AuthRepository repository;

  LogoutUseCase(this.repository);

  Future<Either<Failure, void>> call() async {
    return await repository.logout();
  }
}
```

### `lib/features/auth/domain/usecases/get_current_user_usecase.dart`

```dart
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class GetCurrentUserUseCase {
  final AuthRepository repository;

  GetCurrentUserUseCase(this.repository);

  Future<Either<Failure, UserEntity?>> call() async {
    return await repository.getCurrentUser();
  }
}
```

---

## گام 2.4: Data Layer - Model

### `lib/features/auth/data/models/user_model.dart`

```dart
import 'package:hive/hive.dart';
import '../../domain/entities/user_entity.dart';

part 'user_model.g.dart';

@HiveType(typeId: 0)
class UserModel extends UserEntity {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String username;

  @HiveField(2)
  final String password;

  @HiveField(3)
  final String fullName;

  @HiveField(4)
  final String role;

  @HiveField(5)
  final bool isActive;

  @HiveField(6)
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.username,
    required this.password,
    required this.fullName,
    required this.role,
    required this.isActive,
    required this.createdAt,
  }) : super(
          id: id,
          username: username,
          password: password,
          fullName: fullName,
          role: role,
          isActive: isActive,
          createdAt: createdAt,
        );

  /// تبدیل از Entity به Model
  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      username: entity.username,
      password: entity.password,
      fullName: entity.fullName,
      role: entity.role,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
    );
  }

  /// تبدیل از Model به Entity
  UserEntity toEntity() {
    return UserEntity(
      id: id,
      username: username,
      password: password,
      fullName: fullName,
      role: role,
      isActive: isActive,
      createdAt: createdAt,
    );
  }

  /// CopyWith برای ویرایش
  UserModel copyWith({
    String? id,
    String? username,
    String? password,
    String? fullName,
    String? role,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      password: password ?? this.password,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
```

**نکته مهم**: بعد از نوشتن این فایل، باید دستور زیر را اجرا کنید تا فایل `.g.dart` تولید شود:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## گام 2.5: Data Layer - Data Source

### `lib/features/auth/data/datasources/auth_local_datasource.dart`

```dart
import 'package:hive/hive.dart';
import '../../../../core/constants/hive_boxes.dart';
import '../../../../core/error/exceptions.dart';
import '../models/user_model.dart';

abstract class AuthLocalDataSource {
  /// ورود کاربر
  Future<UserModel> login(String username, String password);

  /// خروج کاربر
  Future<void> logout();

  /// دریافت کاربر فعلی
  Future<UserModel?> getCurrentUser();

  /// بررسی ورود
  Future<bool> isLoggedIn();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  @override
  Future<UserModel> login(String username, String password) async {
    try {
      final usersBox = Hive.box<UserModel>(HiveBoxes.users);

      // جستجوی کاربر
      final user = usersBox.values.firstWhere(
        (u) => u.username == username && u.password == password,
        orElse: () => throw AuthException('نام کاربری یا رمز عبور اشتباه است'),
      );

      // بررسی فعال بودن کاربر
      if (!user.isActive) {
        throw AuthException('این کاربر غیرفعال شده است');
      }

      // ذخیره ID کاربر فعلی
      final currentUserBox = Hive.box<String>(HiveBoxes.currentUser);
      await currentUserBox.put('userId', user.id);

      return user;
    } catch (e) {
      if (e is AuthException) {
        rethrow;
      }
      throw AuthException('خطا در ورود: ${e.toString()}');
    }
  }

  @override
  Future<void> logout() async {
    try {
      final currentUserBox = Hive.box<String>(HiveBoxes.currentUser);
      await currentUserBox.clear();
    } catch (e) {
      throw CacheException('خطا در خروج: ${e.toString()}');
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final currentUserBox = Hive.box<String>(HiveBoxes.currentUser);
      final userId = currentUserBox.get('userId');

      if (userId == null) {
        return null;
      }

      final usersBox = Hive.box<UserModel>(HiveBoxes.users);
      return usersBox.get(userId);
    } catch (e) {
      throw CacheException('خطا در دریافت کاربر فعلی: ${e.toString()}');
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    try {
      final currentUserBox = Hive.box<String>(HiveBoxes.currentUser);
      return currentUserBox.get('userId') != null;
    } catch (e) {
      return false;
    }
  }
}
```

---

## گام 2.6: Data Layer - Repository Implementation

### `lib/features/auth/data/repositories/auth_repository_impl.dart`

```dart
import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl(this.localDataSource);

  @override
  Future<Either<Failure, UserEntity>> login({
    required String username,
    required String password,
  }) async {
    try {
      final user = await localDataSource.login(username, password);
      return Right(user.toEntity());
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(AuthFailure('خطای غیرمنتظره: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await localDataSource.logout();
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('خطا در خروج: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, UserEntity?>> getCurrentUser() async {
    try {
      final user = await localDataSource.getCurrentUser();
      return Right(user?.toEntity());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('خطا در دریافت کاربر: ${e.toString()}'));
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    return await localDataSource.isLoggedIn();
  }
}
```

---

## گام 2.7: Presentation Layer - BLoC Events

### `lib/features/auth/presentation/bloc/auth_event.dart`

```dart
import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// درخواست ورود
class LoginRequested extends AuthEvent {
  final String username;
  final String password;

  const LoginRequested({
    required this.username,
    required this.password,
  });

  @override
  List<Object?> get props => [username, password];
}

/// درخواست خروج
class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}

/// بررسی وضعیت احراز هویت
class CheckAuthStatus extends AuthEvent {
  const CheckAuthStatus();
}
```

---

## گام 2.8: Presentation Layer - BLoC States

### `lib/features/auth/presentation/bloc/auth_state.dart`

```dart
import 'package:equatable/equatable.dart';
import '../../domain/entities/user_entity.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// حالت اولیه
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// در حال بارگذاری
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// کاربر وارد شده
class AuthAuthenticated extends AuthState {
  final UserEntity user;

  const AuthAuthenticated({required this.user});

  @override
  List<Object?> get props => [user];
}

/// کاربر وارد نشده
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// خطا در احراز هویت
class AuthError extends AuthState {
  final String message;

  const AuthError({required this.message});

  @override
  List<Object?> get props => [message];
}
```

---

## گام 2.9: Presentation Layer - BLoC

### `lib/features/auth/presentation/bloc/auth_bloc.dart`

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final LogoutUseCase logoutUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;

  AuthBloc({
    required this.loginUseCase,
    required this.logoutUseCase,
    required this.getCurrentUserUseCase,
  }) : super(const AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<CheckAuthStatus>(_onCheckAuthStatus);
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

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
    emit(const AuthLoading());

    final result = await logoutUseCase();

    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (_) => emit(const AuthUnauthenticated()),
    );
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await getCurrentUserUseCase();

    result.fold(
      (failure) => emit(const AuthUnauthenticated()),
      (user) {
        if (user != null) {
          emit(AuthAuthenticated(user: user));
        } else {
          emit(const AuthUnauthenticated());
        }
      },
    );
  }
}
```

---

## گام 2.10: Presentation Layer - Login Page

### `lib/features/auth/presentation/pages/login_page.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../dashboard/presentation/pages/dashboard_page.dart';
import '../../../user_management/presentation/pages/users_list_page.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/login_form.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          } else if (state is AuthAuthenticated) {
            // هدایت بر اساس نقش کاربر
            if (state.user.isAdmin) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => const UsersListPage(),
                ),
              );
            } else {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => const DashboardPage(),
                ),
              );
            }
          }
        },
        builder: (context, state) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  width: 400,
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // لوگو یا آیکون
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.receipt_long,
                          size: 64,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // عنوان
                      const Text(
                        'مدیریت فاکتور',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'لطفا وارد شوید',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // فرم ورود
                      LoginForm(
                        isLoading: state is AuthLoading,
                        onLogin: (username, password) {
                          context.read<AuthBloc>().add(
                                LoginRequested(
                                  username: username,
                                  password: password,
                                ),
                              );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
```

---

## گام 2.11: Presentation Layer - Login Form Widget

### `lib/features/auth/presentation/widgets/login_form.dart`

```dart
import 'package:flutter/material.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';

class LoginForm extends StatefulWidget {
  final bool isLoading;
  final Function(String username, String password) onLogin;

  const LoginForm({
    Key? key,
    required this.isLoading,
    required this.onLogin,
  }) : super(key: key);

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      widget.onLogin(
        _usernameController.text,
        _passwordController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // نام کاربری
          CustomTextField(
            controller: _usernameController,
            label: 'نام کاربری',
            hint: 'نام کاربری خود را وارد کنید',
            prefixIcon: const Icon(Icons.person_outline),
            validator: Validators.validateUsername,
            keyboardType: TextInputType.text,
          ),
          const SizedBox(height: 16),

          // رمز عبور
          CustomTextField(
            controller: _passwordController,
            label: 'رمز عبور',
            hint: 'رمز عبور خود را وارد کنید',
            prefixIcon: const Icon(Icons.lock_outline),
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            validator: Validators.validatePassword,
          ),
          const SizedBox(height: 24),

          // دکمه ورود
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: 'ورود',
              onPressed: _submit,
              isLoading: widget.isLoading,
              icon: Icons.login,
            ),
          ),

          const SizedBox(height: 16),

          // راهنما برای کاربر Admin پیش‌فرض
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Text(
                      'کاربر پیش‌فرض',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'نام کاربری: ادمین',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
                Text(
                  'رمز عبور: 12321',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## گام 2.12: ایجاد کاربر Admin پیش‌فرض

### `lib/core/utils/init_default_admin.dart`

```dart
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../../features/auth/data/models/user_model.dart';
import '../constants/app_constants.dart';
import '../constants/hive_boxes.dart';
import '../constants/user_roles.dart';

Future<void> initDefaultAdmin() async {
  try {
    final usersBox = Hive.box<UserModel>(HiveBoxes.users);

    // بررسی اگر ادمین وجود ندارد
    final adminExists = usersBox.values.any(
      (user) =>
          user.username == AppConstants.defaultAdminUsername &&
          user.role == UserRoles.admin,
    );

    if (!adminExists) {
      final admin = UserModel(
        id: const Uuid().v4(),
        username: AppConstants.defaultAdminUsername,
        password: AppConstants.defaultAdminPassword,
        fullName: 'مدیر سیستم',
        role: UserRoles.admin,
        isActive: true,
        createdAt: DateTime.now(),
      );

      await usersBox.put(admin.id, admin);
      print('✅ کاربر Admin پیش‌فرض ایجاد شد');
    } else {
      print('✅ کاربر Admin از قبل وجود دارد');
    }
  } catch (e) {
    print('❌ خطا در ایجاد کاربر Admin: $e');
  }
}
```

---

## گام 2.13: تنظیم Dependency Injection

### `lib/injection_container.dart`

```dart
import 'package:get_it/get_it.dart';
import 'features/auth/data/datasources/auth_local_datasource.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/get_current_user_usecase.dart';
import 'features/auth/domain/usecases/login_usecase.dart';
import 'features/auth/domain/usecases/logout_usecase.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';

final getIt = GetIt.instance;

Future<void> initDependencies() async {
  // ========================
  // Auth Feature
  // ========================

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
  getIt.registerLazySingleton(() => GetCurrentUserUseCase(getIt()));

  // BLoC
  getIt.registerFactory(
    () => AuthBloc(
      loginUseCase: getIt(),
      logoutUseCase: getIt(),
      getCurrentUserUseCase: getIt(),
    ),
  );
}
```

---

## گام 2.14: تنظیم main.dart

### `lib/main.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/constants/hive_boxes.dart';
import 'core/themes/app_theme.dart';
import 'core/utils/init_default_admin.dart';
import 'features/auth/data/models/user_model.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/dashboard/presentation/pages/dashboard_page.dart';
import 'features/user_management/presentation/pages/users_list_page.dart';
import 'injection_container.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register Adapters
  Hive.registerAdapter(UserModelAdapter());

  // Open Boxes
  await Hive.openBox<UserModel>(HiveBoxes.users);
  await Hive.openBox<String>(HiveBoxes.currentUser);

  // Create Default Admin
  await initDefaultAdmin();

  // Initialize Dependencies
  await initDependencies();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => getIt<AuthBloc>()..add(const CheckAuthStatus()),
        ),
      ],
      child: MaterialApp(
        title: 'مدیریت فاکتور',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        locale: const Locale('fa', 'IR'),
        supportedLocales: const [Locale('fa', 'IR')],
        home: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is AuthLoading || state is AuthInitial) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (state is AuthAuthenticated) {
              // هدایت بر اساس نقش
              if (state.user.isAdmin) {
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

## گام 2.15: ایجاد صفحات Placeholder

برای اینکه کد کامپایل شود، باید صفحات Dashboard و UsersListPage را به صورت موقت ایجاد کنیم:

### `lib/features/dashboard/presentation/pages/dashboard_page.dart`

```dart
import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('داشبورد کاربر'),
      ),
      body: const Center(
        child: Text('داشبورد کاربر - بزودی پیاده‌سازی می‌شود'),
      ),
    );
  }
}
```

### `lib/features/user_management/presentation/pages/users_list_page.dart`

```dart
import 'package:flutter/material.dart';

class UsersListPage extends StatelessWidget {
  const UsersListPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مدیریت کاربران'),
      ),
      body: const Center(
        child: Text('لیست کاربران - بزودی پیاده‌سازی می‌شود'),
      ),
    );
  }
}
```

---

## گام 2.16: Generate Hive Adapters

در ترمینال دستور زیر را اجرا کنید:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## ✅ چک‌لیست فاز 2

- [ ] Entity و Model برای User ایجاد شده
- [ ] Repository Interface و Implementation نوشته شده
- [ ] Use Cases (Login, Logout, GetCurrentUser) پیاده‌سازی شده
- [ ] AuthBloc با Event و State ایجاد شده
- [ ] LoginPage و LoginForm طراحی شده
- [ ] Dependency Injection تنظیم شده
- [ ] کاربر Admin پیش‌فرض ایجاد می‌شود
- [ ] Hive Adapters تولید شده
- [ ] main.dart تنظیم شده
- [ ] ورود و خروج کار می‌کند
- [ ] هدایت بر اساس نقش کاربر انجام می‌شود

---

## 🧪 تست فاز 2

1. برنامه را اجرا کنید
2. باید صفحه Login نمایش داده شود
3. با نام کاربری "ادمین" و رمز "12321" وارد شوید
4. باید به صفحه UsersListPage هدایت شوید
5. خروج و ورود مجدد را تست کنید

**بعد از تکمیل موفقیت‌آمیز فاز 2، به فایل `PHASE_3_USER_MANAGEMENT.md` بروید.**
