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
