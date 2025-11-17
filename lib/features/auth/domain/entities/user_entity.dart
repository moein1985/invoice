import 'package:equatable/equatable.dart';
import '../../../../core/enums/user_role.dart';

class UserEntity extends Equatable {
  final String id;
  final String username;
  final String password;
  final String fullName;
  final UserRole role;
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

  bool get isAdmin => role == UserRole.admin;
  bool get isUser => role == UserRole.employee || role == UserRole.supervisor || role == UserRole.manager;

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

  UserEntity copyWith({
    String? id,
    String? username,
    String? password,
    String? fullName,
    UserRole? role,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastLogin,
  }) {
    return UserEntity(
      id: id ?? this.id,
      username: username ?? this.username,
      password: password ?? this.password,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'fullName': fullName,
      'role': role.name,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
    };
  }

  factory UserEntity.fromJson(Map<String, dynamic> json) {
    return UserEntity(
      id: json['id'] as String,
      username: json['username'] as String,
      password: json['password'] as String,
      fullName: json['fullName'] as String,
      role: UserRole.values.byName(json['role'] as String),
      isActive: json['isActive'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastLogin: json['lastLogin'] != null ? DateTime.parse(json['lastLogin'] as String) : null,
    );
  }

  @override
  String toString() {
    return 'UserEntity(id: $id, username: $username, fullName: $fullName, role: $role)';
  }
}