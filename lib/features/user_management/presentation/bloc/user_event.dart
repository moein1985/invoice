import 'package:equatable/equatable.dart';

abstract class UserEvent extends Equatable {
  const UserEvent();

  @override
  List<Object?> get props => [];
}

/// درخواست بارگذاری لیست کاربران
class LoadUsers extends UserEvent {
  const LoadUsers();
}

/// درخواست جستجوی کاربران
class SearchUsers extends UserEvent {
  final String query;

  const SearchUsers(this.query);

  @override
  List<Object?> get props => [query];
}

/// درخواست ایجاد کاربر جدید
class CreateUser extends UserEvent {
  final String username;
  final String password;
  final String fullName;
  final String role;

  const CreateUser({
    required this.username,
    required this.password,
    required this.fullName,
    required this.role,
  });

  @override
  List<Object?> get props => [username, password, fullName, role];
}

/// درخواست بروزرسانی کاربر
class UpdateUser extends UserEvent {
  final String id;
  final String? username;
  final String? password;
  final String? fullName;
  final String? role;
  final bool? isActive;

  const UpdateUser({
    required this.id,
    this.username,
    this.password,
    this.fullName,
    this.role,
    this.isActive,
  });

  @override
  List<Object?> get props => [id, username, password, fullName, role, isActive];
}

/// درخواست حذف کاربر
class DeleteUser extends UserEvent {
  final String id;

  const DeleteUser(this.id);

  @override
  List<Object?> get props => [id];
}

/// درخواست تغییر وضعیت کاربر
class ToggleUserStatus extends UserEvent {
  final String id;

  const ToggleUserStatus(this.id);

  @override
  List<Object?> get props => [id];
}
