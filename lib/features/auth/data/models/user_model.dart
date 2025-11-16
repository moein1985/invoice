import 'package:hive/hive.dart';
import '../../domain/entities/user_entity.dart';

part 'user_model.g.dart';

@HiveType(typeId: 0)
class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.username,
    required super.password,
    required super.fullName,
    required super.role,
    required super.isActive,
    required super.createdAt,
    super.lastLogin,
  });

  @override
  @HiveField(0)
  String get id => super.id;

  @override
  @HiveField(1)
  String get username => super.username;

  @override
  @HiveField(2)
  String get password => super.password;

  @override
  @HiveField(3)
  String get fullName => super.fullName;

  @override
  @HiveField(4)
  String get role => super.role;

  @override
  @HiveField(5)
  bool get isActive => super.isActive;

  @override
  @HiveField(6)
  DateTime get createdAt => super.createdAt;

  @override
  @HiveField(7)
  DateTime? get lastLogin => super.lastLogin;

  /// تبدیل از JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      username: json['username'],
      password: json['password'],
      fullName: json['fullName'],
      role: json['role'],
      isActive: json['isActive'],
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
