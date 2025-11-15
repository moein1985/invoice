import 'package:equatable/equatable.dart';
import '../../domain/entities/user_entity.dart';

abstract class UserState extends Equatable {
  const UserState();

  @override
  List<Object?> get props => [];
}

/// وضعیت اولیه
class UserInitial extends UserState {
  const UserInitial();
}

/// در حال بارگذاری
class UserLoading extends UserState {
  const UserLoading();
}

/// لیست کاربران بارگذاری شده
class UsersLoaded extends UserState {
  final List<UserEntity> users;
  final String? searchQuery;

  const UsersLoaded(this.users, {this.searchQuery});

  @override
  List<Object?> get props => [users, searchQuery];
}

/// عملیات موفق (برای ایجاد، بروزرسانی، حذف)
class UserOperationSuccess extends UserState {
  final String message;

  const UserOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

/// خطا
class UserError extends UserState {
  final String message;

  const UserError(this.message);

  @override
  List<Object?> get props => [message];
}

/// کاربر واحد بارگذاری شده (برای جزئیات)
class UserLoaded extends UserState {
  final UserEntity user;

  const UserLoaded(this.user);

  @override
  List<Object?> get props => [user];
}
