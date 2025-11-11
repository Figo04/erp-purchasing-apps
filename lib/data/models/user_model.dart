import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String authId;
  final String username;
  final String email;
  final String? fullName;
  final String role;
  final String? divisionId;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
    required this.id,
    required this.authId,
    required this.username,
    required this.email,
    this.fullName,
    required this.role,
    this.divisionId,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      authId: json['auth_id'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
      role: json['role'] as String,
      divisionId: json['division_id'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'auth_id': authId,
      'username': username,
      'email': email,
      'full_name': fullName,
      'role': role,
      'division_id': divisionId,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helper to get display name
  String get displayName => fullName ?? username;

  // Helper to check if user is admin
  bool get isAdmin => role == 'admin';

  // Helper to check id user is kadiv
  bool get isKadiv => role == 'kadiv';

  // helper to check if user is purchasing
  bool get isPurchasing => role == 'purchasing';

  @override
  List<Object?> get props => [
        id,
        authId,
        username,
        email,
        fullName,
        role,
        divisionId,
        isActive,
        createdAt,
        updatedAt,
      ];
}

// Register Request DTO (for future use)
class RegisterRequest {
  final String username;
  final String email;
  final String password;
  final String? fullName;
  final String role;
  final String? divisionId;

  const RegisterRequest({
    required this.username,
    required this.email,
    required this.password,
    this.fullName,
    required this.role,
    this.divisionId,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
      'password': password,
      'full_name': fullName,
      'role': role,
      'division_id': divisionId,
    };
  }
}
