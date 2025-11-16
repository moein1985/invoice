import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/usecases/create_user_usecase.dart';
import '../../domain/usecases/delete_user_usecase.dart';
import '../../domain/usecases/get_users_usecase.dart';
import '../../domain/usecases/search_users_usecase.dart';
import '../../domain/usecases/toggle_user_status_usecase.dart';
import '../../domain/usecases/update_user_usecase.dart';
import 'user_event.dart';
import 'user_state.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  final GetUsersUseCase getUsersUseCase;
  final CreateUserUseCase createUserUseCase;
  final UpdateUserUseCase updateUserUseCase;
  final DeleteUserUseCase deleteUserUseCase;
  final SearchUsersUseCase searchUsersUseCase;
  final ToggleUserStatusUseCase toggleUserStatusUseCase;

  UserBloc({
    required this.getUsersUseCase,
    required this.createUserUseCase,
    required this.updateUserUseCase,
    required this.deleteUserUseCase,
    required this.searchUsersUseCase,
    required this.toggleUserStatusUseCase,
  }) : super(const UserInitial()) {
    on<LoadUsers>(_onLoadUsers);
    on<SearchUsers>(_onSearchUsers);
    on<CreateUser>(_onCreateUser);
    on<UpdateUser>(_onUpdateUser);
    on<DeleteUser>(_onDeleteUser);
    on<ToggleUserStatus>(_onToggleUserStatus);
  }

  Future<void> _onLoadUsers(
    LoadUsers event,
    Emitter<UserState> emit,
  ) async {
    logInfo('Loading users...');
    emit(const UserLoading());

    final result = await getUsersUseCase();

    result.fold(
      (failure) {
        logError('Failed to load users', failure.message);
        emit(UserError(failure.message));
      },
      (users) {
        logInfo('Users loaded successfully: ${users.length} users');
        emit(UsersLoaded(users));
      },
    );
  }

  Future<void> _onSearchUsers(
    SearchUsers event,
    Emitter<UserState> emit,
  ) async {
    emit(const UserLoading());

    final result = await searchUsersUseCase(event.query);

    result.fold(
      (failure) => emit(UserError(failure.message)),
      (users) => emit(UsersLoaded(users, searchQuery: event.query)),
    );
  }

  Future<void> _onCreateUser(
    CreateUser event,
    Emitter<UserState> emit,
  ) async {
    emit(const UserLoading());

    final result = await createUserUseCase(
      username: event.username,
      password: event.password,
      fullName: event.fullName,
      role: event.role,
    );

    result.fold(
      (failure) => emit(UserError(failure.message)),
      (user) => emit(const UserOperationSuccess('کاربر با موفقیت ایجاد شد')),
    );
  }

  Future<void> _onUpdateUser(
    UpdateUser event,
    Emitter<UserState> emit,
  ) async {
    emit(const UserLoading());

    final result = await updateUserUseCase(
      id: event.id,
      username: event.username,
      password: event.password,
      fullName: event.fullName,
      role: event.role,
      isActive: event.isActive,
    );

    result.fold(
      (failure) => emit(UserError(failure.message)),
      (user) => emit(const UserOperationSuccess('کاربر با موفقیت بروزرسانی شد')),
    );
  }

  Future<void> _onDeleteUser(
    DeleteUser event,
    Emitter<UserState> emit,
  ) async {
    emit(const UserLoading());

    final result = await deleteUserUseCase(event.id);

    result.fold(
      (failure) => emit(UserError(failure.message)),
      (_) => emit(const UserOperationSuccess('کاربر با موفقیت حذف شد')),
    );
  }

  Future<void> _onToggleUserStatus(
    ToggleUserStatus event,
    Emitter<UserState> emit,
  ) async {
    emit(const UserLoading());

    final result = await toggleUserStatusUseCase(event.id);

    result.fold(
      (failure) => emit(UserError(failure.message)),
      (user) => emit(const UserOperationSuccess('وضعیت کاربر تغییر یافت')),
    );
  }
}
