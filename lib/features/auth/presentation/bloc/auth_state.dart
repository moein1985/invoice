import 'package:equatable/equatable.dart';
import '../../domain/entities/user_entity.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// وضعیت اولیه
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// در حال بارگذاری
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// ورود موفق
class Authenticated extends AuthState {
  final UserEntity user;

  const Authenticated(this.user);

  @override
  List<Object?> get props => [user];
}

/// خروج موفق / عدم ورود
class Unauthenticated extends AuthState {
  const Unauthenticated();
}

/// خطا
class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}
