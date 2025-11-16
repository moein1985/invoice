import 'package:get_it/get_it.dart';
import 'features/auth/data/datasources/auth_local_datasource.dart';
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
import 'features/customer/data/repositories/customer_repository_impl.dart';
import 'features/customer/domain/repositories/customer_repository.dart';
import 'features/customer/domain/usecases/create_customer_usecase.dart';
import 'features/customer/domain/usecases/delete_customer_usecase.dart';
import 'features/customer/domain/usecases/get_customers_usecase.dart';
import 'features/customer/domain/usecases/search_customers_usecase.dart';
import 'features/customer/domain/usecases/toggle_customer_status_usecase.dart';
import 'features/customer/domain/usecases/update_customer_usecase.dart';
import 'features/customer/presentation/bloc/customer_bloc.dart';
import 'features/document/data/datasources/document_local_datasource.dart';
import 'features/document/data/repositories/document_repository_impl.dart';
import 'features/document/domain/repositories/document_repository.dart';
import 'features/document/domain/usecases/create_document_usecase.dart';
import 'features/document/domain/usecases/update_document_usecase.dart';
import 'features/document/domain/usecases/delete_document_usecase.dart';
import 'features/document/domain/usecases/get_documents_usecase.dart';
import 'features/document/domain/usecases/get_document_by_id_usecase.dart';
import 'features/document/domain/usecases/search_documents_usecase.dart';
import 'features/document/domain/usecases/convert_proforma_to_invoice_usecase.dart';
import 'features/document/domain/usecases/get_next_document_number_usecase.dart';
import 'features/document/presentation/bloc/document_bloc.dart';
import 'features/export/services/pdf_export_service.dart';
import 'features/export/services/excel_export_service.dart';

final sl = GetIt.instance;

/// مقداردهی اولیه Dependency Injection
Future<void> init() async {
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
    () => AuthRepositoryImpl(localDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(),
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
    () => UserRepositoryImpl(localDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<UserLocalDataSource>(
    () => UserLocalDataSourceImpl(),
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
    () => CustomerRepositoryImpl(localDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<CustomerLocalDataSource>(
    () => CustomerLocalDataSourceImpl(),
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
  sl.registerLazySingleton(() => GetNextDocumentNumberUseCase(sl()));

  // Repository
  sl.registerLazySingleton<DocumentRepository>(
    () => DocumentRepositoryImpl(localDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<DocumentLocalDataSource>(
    () => DocumentLocalDataSourceImpl(),
  );

  // Export Services
  sl.registerLazySingleton(() => PdfExportService());
  sl.registerLazySingleton(() => ExcelExportService());
}
