import '../../domain/entities/user_entity.dart';
import '../../../../core/enums/user_role.dart';

class UserModel {
  final String id;
  final String username;
  final String password;
  final String fullName;
  final String role; // ذخیره به صورت String
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastLogin;

  const UserModel({
    required this.id,
    required this.username,
    required this.password,
    required this.fullName,
    required this.role,
    required this.isActive,
    required this.createdAt,
    this.lastLogin,
  });

  /// تبدیل از Entity
  static UserModel fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      username: entity.username,
      password: entity.password,
      fullName: entity.fullName,
      role: entity.role.name, // تبدیل enum به string
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      lastLogin: entity.lastLogin,
    );
  }

  /// تبدیل به Entity
  UserEntity toEntity() {
    return UserEntity(
      id: id,
      username: username,
      password: password,
      fullName: fullName,
      role: UserRole.values.byName(role), // تبدیل string به enum
      isActive: isActive,
      createdAt: createdAt,
      lastLogin: lastLogin,
    );
  }

  /// تبدیل از JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      username: json['username'],
      password: json['password'],
      fullName: json['fullName'],
      role: json['role'],
      isActive: json['isActive'] is bool 
          ? json['isActive'] 
          : (json['isActive'] == 1 || json['isActive'] == true),
      createdAt: DateTime.parse(json['createdAt']),
      lastLogin: json['lastLogin'] != null
          ? DateTime.parse(json['lastLogin'])
          : null,
    );
  }

  /// تبدیل به JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'fullName': fullName,
      'role': role,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
    };
  }

  /// کپی با تغییرات
  UserModel copyWith({
    String? id,
    String? username,
    String? password,
    String? fullName,
    String? role,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastLogin,
  }) {
    return UserModel(
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
}
