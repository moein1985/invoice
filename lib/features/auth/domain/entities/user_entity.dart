import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String username;
  final String password;
  final String fullName;
  final String role; // 'admin' یا 'user'
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastLogin;

  const UserEntity({
    required this.id,
    required this.username,
    required this.password,
    required this.fullName,
    required this.role,
    required this.isActive,
    required this.createdAt,
    this.lastLogin,
  });

  bool get isAdmin => role == 'admin';
  bool get isUser => role == 'user';

  @override
  List<Object?> get props => [
        id,
        username,
        fullName,
        role,
        isActive,
        createdAt,
        lastLogin,
      ];

  @override
  String toString() {
    return 'UserEntity(id: $id, username: $username, fullName: $fullName, role: $role)';
  }
}