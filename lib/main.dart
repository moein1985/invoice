import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/themes/app_theme.dart';
import 'core/utils/init_default_admin.dart';
import 'core/utils/logger.dart';
import 'core/observers/bloc_observer.dart';
import 'core/constants/hive_boxes.dart';
import 'core/utils/window_arguments.dart';
import 'features/auth/data/models/user_model.dart';
import 'features/customer/data/models/customer_model.dart';
import 'features/document/data/models/document_model.dart';
import 'features/document/data/models/document_item_model.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'features/dashboard/presentation/pages/dashboard_page.dart';
import 'features/user_management/presentation/bloc/user_bloc.dart';
import 'features/user_management/presentation/pages/user_list_page.dart';
import 'features/user_management/presentation/pages/user_form_page.dart';
import 'features/user_management/presentation/pages/user_detail_page.dart';
import 'features/customer/presentation/bloc/customer_bloc.dart';
import 'features/customer/presentation/pages/customer_list_page.dart';
import 'features/customer/presentation/pages/customer_form_page.dart';
import 'features/customer/presentation/pages/customer_detail_page.dart';
import 'features/document/presentation/bloc/document_bloc.dart';
import 'features/document/presentation/pages/document_list_page.dart';
import 'features/document/presentation/pages/document_form_page.dart';
import 'features/document/presentation/pages/document_preview_page.dart';
import 'core/enums/document_type.dart';
import 'injection_container.dart' as di;

bool _appServicesInitialized = false;

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  final windowArguments = await _resolveWindowArguments();

  if (windowArguments.isPreview && 
      windowArguments.documentId != null && 
      windowArguments.documentData != null) {
    // Preview windows don't need database - use serialized data
    runApp(PreviewWindowApp(
      documentId: windowArguments.documentId!,
      documentData: windowArguments.documentData!,
      customerData: windowArguments.customerData,
    ));
    return;
  }

  await _initializeAppServices();
  runApp(const MainApp());
}

Future<AppWindowArguments> _resolveWindowArguments() async {
  if (_isDesktop) {
    try {
      final controller = await WindowController.fromCurrentEngine();
      return AppWindowArguments.decode(controller.arguments);
    } catch (_) {
      // fallthrough to main window behaviour
    }
  }
  return const AppWindowArguments.main();
}

Future<void> _initializeAppServices() async {
  if (_appServicesInitialized) {
    return;
  }

  // فعال‌سازی BLoC Observer برای لاگینگ
  Bloc.observer = AppBlocObserver();

  // تنظیم سطح لاگ (می‌توانید به debug، info یا warning تغییر دهید)
  AppLogger.currentLevel = LogLevel.debug;

  AppLogger.info('🚀 Application Starting...', 'MAIN');

  // مقداردهی اولیه Hive
  await Hive.initFlutter();

  // ثبت Adapter های Hive
  Hive.registerAdapter(UserModelAdapter());
  Hive.registerAdapter(CustomerModelAdapter());
  Hive.registerAdapter(DocumentModelAdapter());
  Hive.registerAdapter(DocumentItemModelAdapter());

  // باز کردن Boxes فقط در صورت نیاز
  if (!Hive.isBoxOpen(HiveBoxes.users)) {
    await Hive.openBox<UserModel>(HiveBoxes.users);
  }
  if (!Hive.isBoxOpen(HiveBoxes.auth)) {
    await Hive.openBox(HiveBoxes.auth);
  }
  if (!Hive.isBoxOpen(HiveBoxes.currentUser)) {
    await Hive.openBox<String>(HiveBoxes.currentUser);
  }
  if (!Hive.isBoxOpen(HiveBoxes.customers)) {
    await Hive.openBox<CustomerModel>(HiveBoxes.customers);
  }
  if (!Hive.isBoxOpen(HiveBoxes.documents)) {
    await Hive.openBox<DocumentModel>(HiveBoxes.documents);
  }

  // مقداردهی اولیه Dependency Injection
  await di.init();

  // ایجاد ادمین پیش‌فرض
  await initDefaultAdmin();

  _appServicesInitialized = true;
}

bool get _isDesktop {
  if (kIsWeb) return false;
  switch (defaultTargetPlatform) {
    case TargetPlatform.windows:
    case TargetPlatform.linux:
    case TargetPlatform.macOS:
      return true;
    default:
      return false;
  }
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
        
        initialRoute: '/',
        routes: {
          '/': (context) => BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is Authenticated) {

                return MultiBlocProvider(
                  providers: [
                    BlocProvider.value(value: context.read<AuthBloc>()),
                    BlocProvider(create: (context) => di.sl<DashboardBloc>()),
                    BlocProvider(create: (context) => di.sl<UserBloc>()),
                    BlocProvider(create: (context) => di.sl<CustomerBloc>()),
                    BlocProvider(create: (context) => di.sl<DocumentBloc>()),
                  ],
                  child: const DashboardPage(),
                );
              }
              return const LoginPage();
            },
          ),
          '/users': (context) => BlocProvider.value(
            value: di.sl<UserBloc>(),
            child: const UserListPage(),
          ),
          '/users/create': (context) => BlocProvider.value(
            value: di.sl<UserBloc>(),
            child: const UserFormPage(),
          ),
          '/customers': (context) => BlocProvider(
            create: (_) => di.sl<CustomerBloc>(),
            child: const CustomerListPage(),
          ),
          '/customers/create': (context) => BlocProvider(
            create: (_) => di.sl<CustomerBloc>(),
            child: const CustomerFormPage(),
          ),
          '/documents': (context) => MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => di.sl<DocumentBloc>()),
              BlocProvider(create: (_) => di.sl<CustomerBloc>()),
            ],
            child: const DocumentListPage(),
          ),
          '/documents/create/invoice': (context) => MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => di.sl<DocumentBloc>()),
              BlocProvider(create: (_) => di.sl<CustomerBloc>()),
            ],
            child: const DocumentFormPage(initialType: DocumentType.invoice),
          ),
          '/documents/create/proforma': (context) => MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => di.sl<DocumentBloc>()),
              BlocProvider(create: (_) => di.sl<CustomerBloc>()),
            ],
            child: const DocumentFormPage(initialType: DocumentType.proforma),
          ),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/users/edit') {
            final user = settings.arguments as dynamic;
            return MaterialPageRoute(
              builder: (context) => BlocProvider.value(
                value: di.sl<UserBloc>(),
                child: UserFormPage(user: user),
              ),
            );
          } else if (settings.name == '/users/detail') {
            final userId = settings.arguments as String;
            return MaterialPageRoute(
              builder: (context) => BlocProvider.value(
                value: di.sl<UserBloc>(),
                child: UserDetailPage(userId: userId),
              ),
            );
          } else if (settings.name == '/customers/edit') {
            final customer = settings.arguments as dynamic;
            return MaterialPageRoute(
              builder: (context) => BlocProvider(
                create: (_) => di.sl<CustomerBloc>(),
                child: CustomerFormPage(customer: customer),
              ),
            );
          } else if (settings.name == '/customers/detail') {
            final customerId = settings.arguments as String;
            return MaterialPageRoute(
              builder: (context) => BlocProvider(
                create: (_) => di.sl<CustomerBloc>(),
                child: CustomerDetailPage(customerId: customerId),
              ),
            );
          } else if (settings.name == '/documents/edit') {
            final documentId = settings.arguments as String;
            return MaterialPageRoute(
              builder: (context) => MultiBlocProvider(
                providers: [
                  BlocProvider(create: (_) => di.sl<DocumentBloc>()),
                  BlocProvider(create: (_) => di.sl<CustomerBloc>()),
                ],
                child: DocumentFormPage(
                  documentId: documentId,
                  initialType: DocumentType.invoice, // Will be overridden when loading
                ),
              ),
            );
          } else if (settings.name == '/documents/preview') {
            final documentId = settings.arguments as String;
            return MaterialPageRoute(
              builder: (context) => MultiBlocProvider(
                providers: [
                  BlocProvider(create: (_) => di.sl<DocumentBloc>()),
                  BlocProvider(create: (_) => di.sl<CustomerBloc>()),
                ],
                child: DocumentPreviewPage(documentId: documentId),
              ),
            );
          }
          return null;
        },
      ),
    );
  }
}

class PreviewWindowApp extends StatelessWidget {
  final String documentId;
  final Map<String, dynamic> documentData;
  final Map<String, dynamic>? customerData;

  const PreviewWindowApp({
    super.key, 
    required this.documentId,
    required this.documentData,
    this.customerData,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'پیش‌نمایش سند',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: const Locale('fa', 'IR'),
      supportedLocales: const [Locale('fa', 'IR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: StaticDocumentPreviewPage(
        documentData: documentData,
        customerData: customerData,
      ),
    );
  }
}
