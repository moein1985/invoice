import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/themes/app_theme.dart';
import 'core/utils/init_default_admin.dart';
import 'core/utils/logger.dart';
import 'core/observers/bloc_observer.dart';
import 'core/utils/window_arguments.dart';
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
import 'features/document/presentation/bloc/approval_bloc.dart';
import 'features/document/presentation/bloc/approval_event.dart';
import 'features/document/presentation/pages/approval_queue_page.dart';
import 'core/services/approval_polling_service.dart';
import 'core/enums/document_type.dart';
import 'core/enums/user_role.dart';
import 'injection_container.dart' as di;
import 'core/services/sip_integration_service.dart';
import 'core/models/sip_config.dart';
import 'core/services/backend_service.dart';
import 'dart:js' as js;

bool _appServicesInitialized = false;
bool _sipInitialized = false;

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

  // راه‌اندازی Backend (Docker + MySQL + Node.js)
  final backendStarted = await BackendService.startBackend();
  if (!backendStarted) {
    AppLogger.error('❌ Failed to start backend services!', 'MAIN');
    AppLogger.error('⚠️  Please ensure Docker Desktop is running', 'MAIN');
    // می‌توانید در اینجا یک دیالوگ به کاربر نشان دهید
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

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  @override
  void initState() {
    super.initState();
    // Start polling service
    WidgetsBinding.instance.addPostFrameCallback((_) {
      di.sl<ApprovalPollingService>().start();
      
      // SIP Integration بعد از login فراخوانی می‌شود (در BlocListener)
    });
  }

  @override
  void dispose() {
    di.sl<ApprovalPollingService>().stop();
    
    // توقف SIP Integration (فقط برای Web)
    if (kIsWeb && _sipInitialized) {
      di.sl<SipIntegrationService>().stop();
    }
    
    super.dispose();
  }

  /// بررسی لود شدن JsSIP از طریق JavaScript
  Future<bool> _checkJsSIPLoaded() async {
    if (!kIsWeb) return false;
    
    try {
      // چک کردن window.jsSipLoaded
      final loaded = js.context['jsSipLoaded'];
      return loaded == true;
    } catch (e) {
      return false;
    }
  }

  /// مقداردهی SIP Integration برای Web (فقط برای Admin)
  Future<void> _initializeSipIntegration() async {
    try {
      debugPrint('📞 شروع مقداردهی SIP Integration...');
      
      // چک کردن کاربر فعلی Admin است یا نه
      final authBloc = di.sl<AuthBloc>();
      final currentState = authBloc.state;
      
      if (currentState is! Authenticated) {
        debugPrint('⚠️ کاربر لاگین نکرده - لغو SIP');
        return;
      }
      
      // فقط برای کاربر با نقش admin
      if (currentState.user.role != UserRole.admin) {
        debugPrint('⚠️ SIP فقط برای Admin فعال است - کاربر فعلی: ${currentState.user.role.persianName}');
        return;
      }
      
      debugPrint('✅ کاربر Admin تأیید شد - ادامه مقداردهی SIP');
      
      // بررسی لود شدن JsSIP
      if (kIsWeb) {
        final isLoaded = await _checkJsSIPLoaded();
        if (!isLoaded) {
          debugPrint('⚠️ JsSIP لود نشده - صبر 2 ثانیه...');
          await Future.delayed(const Duration(seconds: 2));
          
          final isLoadedNow = await _checkJsSIPLoaded();
          if (!isLoadedNow) {
            debugPrint('❌ JsSIP همچنان لود نشده - لغو مقداردهی SIP');
            return;
          }
        }
        debugPrint('✅ JsSIP آماده است');
      }
      
      // پیکربندی SIP - اتصال به سرور تلفنی
      final config = SipConfig(
        sipServer: '192.168.85.88',
        sipPort: '8088',  // WebSocket port
        extension: '1010',
        password: 'Abc@1010',
        displayName: 'Invoice',
        autoAnswer: false,
      );
      
      final sipService = di.sl<SipIntegrationService>();
      
      // تنظیم callback ها
      sipService.onCustomerCallReceived = (customerData) {
        debugPrint('✅ تماس از مشتری: ${customerData.customer.name}');
        debugPrint('   شماره تلفن: ${customerData.phoneNumber}');
        
        if (customerData.lastDocument != null) {
          debugPrint('   آخرین سند: ${customerData.lastDocument!.documentNumber}');
        }
        
        // TODO: نمایش پاپ‌آپ با اطلاعات مشتری و سند
      };
      
      sipService.onUnknownCallReceived = (phoneNumber) {
        debugPrint('⚠️ تماس از شماره ناشناس: $phoneNumber');
        
        // TODO: نمایش پاپ‌آپ برای ثبت مشتری جدید
      };
      
      sipService.onStatusChanged = (status) {
        debugPrint('📞 تغییر وضعیت SIP: $status');
      };
      
      sipService.onError = (error) {
        debugPrint('❌ خطای SIP: $error');
      };
      
      // مقداردهی و اتصال
      sipService.initialize(config);
      
      debugPrint('✅ SIP Integration با موفقیت راه‌اندازی شد (Admin only)');
    } catch (e, stackTrace) {
      debugPrint('❌ خطا در مقداردهی SIP Integration: $e');
      debugPrint('Stack: $stackTrace');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => di.sl<AuthBloc>()..add(const CheckAuthStatus()),
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          // وقتی کاربر لاگین کرد، SIP را راه‌اندازی کن (فقط برای Admin)
          if (state is Authenticated && kIsWeb && !_sipInitialized) {
            _initializeSipIntegration();
            _sipInitialized = true;
          }
          // وقتی logout کرد، SIP را متوقف کن
          if (state is Unauthenticated && _sipInitialized) {
            try {
              di.sl<SipIntegrationService>().stop();
            } catch (_) {}
            _sipInitialized = false;
          }
        },
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
          '/approvals': (context) => BlocProvider(
            create: (_) => di.sl<ApprovalBloc>()..add(LoadPendingApprovals()),
            child: const ApprovalQueuePage(),
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
