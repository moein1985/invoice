import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/themes/app_theme.dart';
import 'core/utils/init_default_admin.dart';
import 'features/auth/data/models/user_model.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // مقداردهی اولیه Hive
  await Hive.initFlutter();
  
  // ثبت Adapter های Hive
  Hive.registerAdapter(UserModelAdapter());

  // مقداردهی اولیه Dependency Injection
  await di.init();

  // ایجاد ادمین پیش‌فرض
  await initDefaultAdmin();

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => di.sl<AuthBloc>()..add(const CheckAuthStatus()),
      child: MaterialApp(
        title: 'مدیریت فاکتور',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        
        // تنظیمات فارسی‌سازی
        locale: const Locale('fa', 'IR'),
        supportedLocales: const [
          Locale('fa', 'IR'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        
        home: const LoginPage(),
      ),
    );
  }
}
