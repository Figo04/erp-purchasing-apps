import 'package:equatable/equatable.dart';
import 'package:erp_purchasing_apps/data/models/user_model.dart';

// Login Request DTO
class LoginRequest {
  final String email;
  final String password;

  const LoginRequest({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }
}

/// Login Response DTO
/// Matches Golang backend response:
/// {
///   "token": "jwt_token_here",
///   "user": { ... }
/// }
class LoginResponse extends Equatable {
  final String token;
  final UserModel user;

  const LoginResponse({
    required this.token,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'] as String,
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'user': user.toJson(),
    };
  }

  @override
  List<Object?> get props => [token, user];
}