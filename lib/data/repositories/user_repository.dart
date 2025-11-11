import '../models/user_model.dart';
import 'package:erp_purchasing_apps/core/service/api_service.dart';
import '../../core/constants/api_constants.dart';

/// User Repository
/// Handles user management operations (admin only)
/// Different from AuthRepository (login/logout)
class UserRepository {
  final ApiService _apiService;

  UserRepository({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  /// Get all users (admin only)
  Future<List<UserModel>> getAllUsers({
    String? role,
    String? divisionId,
    String? search,
    bool? isActive,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (role != null) queryParams['role'] = role;
      if (divisionId != null) queryParams['division_id'] = divisionId;
      if (search != null) queryParams['search'] = search;
      if (isActive != null) queryParams['is_active'] = isActive.toString();

      final response = await _apiService.get(
        ApiEndpoints.users,
        queryParameters: queryParams,
        fromJson: (json) {
          if (json is List) {
            return json.map((item) => UserModel.fromJson(item)).toList();
          }
          return <UserModel>[];
        },
      );

      if (!response.isSuccess || response.data == null) {
        throw Exception(response.errorMessage);
      }

      return response.data as List<UserModel>;
    } catch (e) {
      throw Exception('Failed to load users: $e');
    }
  }

  /// Get user by ID
  Future<UserModel> getUserById(String id) async {
    try {
      final response = await _apiService.get<UserModel>(
        ApiEndpoints.userById(id),
        fromJson: (json) => UserModel.fromJson(json),
      );

      if (!response.isSuccess || response.data == null) {
        throw Exception(response.errorMessage);
      }

      return response.data!;
    } catch (e) {
      throw Exception('Failed to load user: $e');
    }
  }

  /// Create new user (admin only)
  Future<UserModel> createUser({
    required String username,
    required String email,
    required String password,
    String? fullName,
    required String role,
    String? divisionId,
  }) async {
    try {
      final body = {
        'username': username,
        'email': email,
        'password': password,
        'full_name': fullName,
        'role': role,
        'division_id': divisionId,
      };

      final response = await _apiService.post<UserModel>(
        ApiEndpoints.users,
        body: body,
        fromJson: (json) => UserModel.fromJson(json),
      );

      if (!response.isSuccess || response.data == null) {
        throw Exception(response.errorMessage);
      }

      return response.data!;
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }

  /// Update user
  Future<UserModel> updateUser({
    required String id,
    required String username,
    required String email,
    String? fullName,
    required String role,
    String? divisionId,
    required bool isActive,
  }) async {
    try {
      final body = {
        'full_name': fullName,
        'role': role,
        'division_id': divisionId,
        'is_active': isActive,
      };

      final response = await _apiService.put<UserModel>(
        ApiEndpoints.userById(id),
        body: body,
        fromJson: (json) => UserModel.fromJson(json),
      );

      if (!response.isSuccess || response.data == null) {
        throw Exception(response.errorMessage);
      }

      return response.data!;
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  /// Delete user (soft delete)
  Future<void> deleteUser(String id) async {
    try {
      final response = await _apiService.delete(
        ApiEndpoints.userById(id),
      );

      if (!response.isSuccess) {
        throw Exception(response.errorMessage);
      }
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

  /// Search users
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      return await getAllUsers(search: query);
    } catch (e) {
      throw Exception('Failed to search users: $e');
    }
  }
}