import 'package:get_it/get_it.dart';
import 'features/auth/data/datasources/auth_local_datasource.dart';
import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/login_usecase.dart';
import 'features/auth/domain/usecases/logout_usecase.dart';
import 'features/auth/domain/usecases/get_current_user_usecase.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/dashboard/data/datasources/dashboard_local_datasource.dart';
import 'features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'features/dashboard/domain/repositories/dashboard_repository.dart';
import 'features/dashboard/domain/usecases/get_dashboard_data_usecase.dart';
import 'features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'features/user_management/data/datasources/user_local_datasource.dart';
import 'features/user_management/data/datasources/user_remote_datasource.dart';
import 'features/user_management/data/repositories/user_repository_impl.dart';
import 'features/user_management/domain/repositories/user_repository.dart';
import 'features/user_management/domain/usecases/create_user_usecase.dart';
import 'features/user_management/domain/usecases/delete_user_usecase.dart';
import 'features/user_management/domain/usecases/get_users_usecase.dart';
import 'features/user_management/domain/usecases/search_users_usecase.dart';
import 'features/user_management/domain/usecases/toggle_user_status_usecase.dart';
import 'features/user_management/domain/usecases/update_user_usecase.dart';
import 'features/user_management/presentation/bloc/user_bloc.dart';
import 'features/customer/data/datasources/customer_local_datasource.dart';
import 'features/customer/data/datasources/customer_remote_datasource.dart';
import 'features/customer/data/repositories/customer_repository_impl.dart';
import 'features/customer/domain/repositories/customer_repository.dart';
import 'features/customer/domain/usecases/create_customer_usecase.dart';
import 'features/customer/domain/usecases/delete_customer_usecase.dart';
import 'features/customer/domain/usecases/get_customers_usecase.dart';
import 'features/customer/domain/usecases/search_customers_usecase.dart';
import 'features/customer/domain/usecases/toggle_customer_status_usecase.dart';
import 'features/customer/domain/usecases/update_customer_usecase.dart';
import 'features/customer/presentation/bloc/customer_bloc.dart';
import 'features/document/domain/usecases/create_document_usecase.dart';
import 'features/document/domain/usecases/update_document_usecase.dart';
import 'features/document/domain/usecases/delete_document_usecase.dart';
import 'features/document/domain/usecases/get_documents_usecase.dart';
import 'features/document/domain/usecases/get_document_by_id_usecase.dart';
import 'features/document/domain/usecases/search_documents_usecase.dart';
import 'features/document/domain/usecases/convert_proforma_to_invoice_usecase.dart';
import 'features/document/domain/usecases/convert_document_usecase.dart';
import 'features/document/domain/usecases/get_next_document_number_usecase.dart';
import 'features/document/domain/usecases/request_approval_usecase.dart';
import 'features/document/domain/usecases/approve_document_usecase.dart';
import 'features/document/domain/usecases/reject_document_usecase.dart';
import 'features/document/domain/usecases/get_pending_approvals_usecase.dart';
import 'features/document/presentation/bloc/document_bloc.dart';
import 'features/document/presentation/bloc/approval_bloc.dart';
import 'features/document/domain/repositories/document_repository.dart';
import 'features/document/data/repositories/document_repository_impl.dart';
import 'features/document/data/datasources/document_local_datasource.dart';
import 'features/document/data/datasources/document_remote_datasource.dart';
import 'features/export/services/pdf_export_service.dart';
import 'features/export/services/excel_export_service.dart';
import 'core/services/api_client.dart';
import 'core/services/approval_polling_service.dart';

final sl = GetIt.instance;
bool _initialized = false;

/// مقداردهی اولیه Dependency Injection
Future<void> init() async {
  if (_initialized) {
    return;
  }
  _initialized = true;
  // Core - Api Client
  sl.registerLazySingleton(() => ApiClient());
  //! Features - Auth
  // Bloc
  sl.registerLazySingleton(
    () => AuthBloc(
      loginUseCase: sl(),
      logoutUseCase: sl(),
      getCurrentUserUseCase: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));
  sl.registerLazySingleton(() => GetCurrentUserUseCase(sl()));

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(localDataSource: sl(), remoteDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(),
  );
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(dio: sl<ApiClient>().dio),
  );

  //! Features - Dashboard
  // Bloc
  sl.registerFactory(
    () => DashboardBloc(
      getDashboardDataUseCase: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetDashboardDataUseCase(sl()));

  // Repository
  sl.registerLazySingleton<DashboardRepository>(
    () => DashboardRepositoryImpl(localDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<DashboardLocalDataSource>(
    () => DashboardLocalDataSourceImpl(),
  );

  //! Features - User Management
  // Bloc
  sl.registerLazySingleton(
    () => UserBloc(
      getUsersUseCase: sl(),
      createUserUseCase: sl(),
      updateUserUseCase: sl(),
      deleteUserUseCase: sl(),
      searchUsersUseCase: sl(),
      toggleUserStatusUseCase: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetUsersUseCase(sl()));
  sl.registerLazySingleton(() => CreateUserUseCase(sl()));
  sl.registerLazySingleton(() => UpdateUserUseCase(sl()));
  sl.registerLazySingleton(() => DeleteUserUseCase(sl()));
  sl.registerLazySingleton(() => SearchUsersUseCase(sl()));
  sl.registerLazySingleton(() => ToggleUserStatusUseCase(sl()));

  // Repository
  sl.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(localDataSource: sl(), remoteDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<UserLocalDataSource>(
    () => UserLocalDataSourceImpl(),
  );
  sl.registerLazySingleton<UserRemoteDataSource>(
    () => UserRemoteDataSourceImpl(dio: sl<ApiClient>().dio),
  );

  //! Features - Customer Management
  // Bloc
  sl.registerFactory(
    () => CustomerBloc(
      getCustomersUseCase: sl(),
      createCustomerUseCase: sl(),
      updateCustomerUseCase: sl(),
      deleteCustomerUseCase: sl(),
      searchCustomersUseCase: sl(),
      toggleCustomerStatusUseCase: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetCustomersUseCase(sl()));
  sl.registerLazySingleton(() => CreateCustomerUseCase(sl()));
  sl.registerLazySingleton(() => UpdateCustomerUseCase(sl()));
  sl.registerLazySingleton(() => DeleteCustomerUseCase(sl()));
  sl.registerLazySingleton(() => SearchCustomersUseCase(sl()));
  sl.registerLazySingleton(() => ToggleCustomerStatusUseCase(sl()));

  // Repository
  sl.registerLazySingleton<CustomerRepository>(
    () => CustomerRepositoryImpl(localDataSource: sl(), remoteDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<CustomerLocalDataSource>(
    () => CustomerLocalDataSourceImpl(),
  );
  sl.registerLazySingleton<CustomerRemoteDataSource>(
    () => CustomerRemoteDataSourceImpl(dio: sl<ApiClient>().dio),
  );

  //! Features - Document Management
  // Bloc
  sl.registerFactory(
    () => DocumentBloc(
      getDocumentsUseCase: sl(),
      getDocumentByIdUseCase: sl(),
      createDocumentUseCase: sl(),
      updateDocumentUseCase: sl(),
      deleteDocumentUseCase: sl(),
      searchDocumentsUseCase: sl(),
      convertProformaToInvoiceUseCase: sl(),
      convertDocumentUseCase: sl(),
    ),
  );

  // Approval Bloc
  sl.registerFactory(
    () => ApprovalBloc(
      getPendingApprovals: sl(),
      approveDocument: sl(),
      rejectDocument: sl(),
      requestApproval: sl(),
      authRepository: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetDocumentsUseCase(sl()));
  sl.registerLazySingleton(() => GetDocumentByIdUseCase(sl()));
  sl.registerLazySingleton(() => CreateDocumentUseCase(sl()));
  sl.registerLazySingleton(() => UpdateDocumentUseCase(sl()));
  sl.registerLazySingleton(() => DeleteDocumentUseCase(sl()));
  sl.registerLazySingleton(() => SearchDocumentsUseCase(sl()));
  sl.registerLazySingleton(() => ConvertProformaToInvoiceUseCase(sl()));
  sl.registerLazySingleton(() => ConvertDocumentUseCase(sl(), sl()));
  sl.registerLazySingleton(() => GetNextDocumentNumberUseCase(sl()));
  sl.registerLazySingleton(() => RequestApprovalUseCase(sl()));
  sl.registerLazySingleton(() => ApproveDocumentUseCase(sl()));
  sl.registerLazySingleton(() => RejectDocumentUseCase(sl()));
  sl.registerLazySingleton(() => GetPendingApprovalsUseCase(sl()));

  // Repository
  sl.registerLazySingleton<DocumentRepository>(
    () => DocumentRepositoryImpl(localDataSource: sl(), remoteDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<DocumentLocalDataSource>(
    () => DocumentLocalDataSourceImpl(),
  );
  sl.registerLazySingleton<DocumentRemoteDataSource>(
    () => DocumentRemoteDataSourceImpl(dio: sl<ApiClient>().dio),
  );

  // Export Services
  sl.registerLazySingleton(() => PdfExportService());
  sl.registerLazySingleton(() => ExcelExportService());

  // Approval Polling Service
  sl.registerLazySingleton(
    () => ApprovalPollingService(
      getPendingApprovals: sl(),
      authRepository: sl(),
    ),
  );
}
