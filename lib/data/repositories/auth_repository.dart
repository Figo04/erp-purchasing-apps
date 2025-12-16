import 'package:erp_purchasing_apps/core/service/api_service.dart';
import 'package:erp_purchasing_apps/data/models/auth_model.dart';
import 'package:erp_purchasing_apps/core/constants/api_constants.dart';
import 'package:erp_purchasing_apps/data/models/user_model.dart';
import 'package:http/http.dart';

/// Auth Repository
/// Handles authentication operations via Golang backend API
/// Replaces Supabase authentication
class AuthRepository {
  final ApiService _apiService;

  AuthRepository({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  // Sign In / Login
  // Returns LoginResponse containing token and user data
  Future<LoginResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      print('AuthRepository: Attemping login for $email');

      final loginRequest = LoginRequest(
        email: email,
        password: password,
      );

      final response = await _apiService.post<LoginResponse>(
        ApiEndpoints.login,
        body: loginRequest.toJson(),
        requiresAuth: false,
        fromJson: (json) => LoginResponse.fromJson(json),
      );

      if (!response.isSuccess || response.data == null) {
        throw Exception(response.errorMessage);
      }

      // Save token to secure strage
      await _apiService.saveToken(response.data!.token);

      print('AuthRepository: Login successful');
      print('User: ${response.data!.user.email}');
      print('Role: ${response.data!.user.role}');

      return response.data!;
    } catch (e) {
      print('AuthRepository: Login failed - $e');
      rethrow;
    }
  }

  // Sign Out / Logout
  // Removes stored token
  Future<void> signOut() async {
    try {
      print(' AuthRepository: Logging out...');
      await _apiService.removeToken();
      print('AuthRepository: Logout successful');
    } catch (e) {
      print('AuthRepository: Logout failed - $e');
      rethrow;
    }
  }

  // Get Current User Profile
  // Fetches user data using stored token
  Future<UserModel> getCurrentUser() async {
    try {
      print('🔵 AuthRepository: Fetching current user profile');

      final response = await _apiService.get<UserModel>(
        ApiEndpoints.profile,
        requiresAuth: true,
        fromJson: (json) => UserModel.fromJson(json),
      );

      if (!response.isSuccess || response.data == null) {
        throw Exception(response.errorMessage);
      }

      print('AuthRepository: Profile fetched');
      print('User: ${response.data!.email}');

      return response.data!;
    } catch (e) {
      print('AuthRepository: Failed to fetch profile - $e');
      rethrow;
    }
  }

  // Check if user is logged in
  // Returns true if valid token exists
  Future<bool> isLoggedIn() async {
    return await _apiService.hasToken();
  }

  // Register new user (admin only)
  // For future implementation when register end point is available
  Future<LoginResponse> register({
    required String username,
    required String email,
    required String password,
    String? fullName,
    required String role,
    String? divisionId,
  }) async {
    try {
      print('AuthRepository: Registering user $email');

      final registerRequest = RegisterRequest(
        username: username,
        email: email,
        password: password,
        fullName: fullName,
        role: role,
        divisionId: divisionId,
      );

      final response = await _apiService.post<LoginResponse>(
        ApiEndpoints.register,
        body: registerRequest.toJson(),
        requiresAuth: false,
        fromJson: (json) => LoginResponse.fromJson(json),
      );

      if (!response.isSuccess || response.data == null) {
        throw Exception(response.errorMessage);
      }

      // Save token to secure storage
      await _apiService.saveToken(response.data!.token);

      print('AuthRepository: Registration successful');

      return response.data!;
    } catch (e) {
      print('AuthRepository: Registration failed - $e');
      rethrow;
    }
  }

  // Validate current session
  // Checks if stored token is still valid by fetching profile
  Future<bool> validateSession() async {
    try {
      if (!await isLoggedIn()) {
        return false;
      }

      await getCurrentUser();
      return true;
    } catch (e) {
      print('AuthRepository: Session invalid - $e');
      await _apiService.removeToken();
      return false;
    }
  }
}
