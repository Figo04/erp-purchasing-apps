import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class AuthRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Sign In
  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final authResponse = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (authResponse.user != null) {
        // Get user data from users table
        final response = await _supabase
            .from('users')
            .select()
            .eq('auth_id', authResponse.user!.id)
            .maybeSingle();

        if (response == null) {
          throw Exception('User tidak ditemukan di tabel users');
        }

        return UserModel.fromJson(response);
      }
      return null;
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw Exception('Logout failed: $e');
    }
  }

  // Get Current User
  Future<UserModel?> getCurrentUser() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final response = await _supabase
          .from('users')
          .select()
          .eq('auth_id', user.id)
          .maybeSingle(); // ✅ aman

      if (response == null) return null;
      return UserModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  // Admin creates user (with auto-generated password)
  Future<UserModel?> adminCreateUser({
    required String email,
    required String username,
    required String fullName,
    required String role,
    required String password, // Admin set password
  }) async {
    try {
      // 1. Create auth user via Admin API
      final authResponse = await _supabase.auth.admin.createUser(
        AdminUserAttributes(
          email: email,
          password: password,
          emailConfirm: true, // Skip email verification
        ),
      );

      if (authResponse.user != null) {
        // 2. Insert to users table
        final userData = {
          'auth_id': authResponse.user!.id,
          'username': username,
          'email': email,
          'full_name': fullName,
          'role': role,
          'is_active': true,
        };

        final response =
            await _supabase.from('users').insert(userData).select().single();

        return UserModel.fromJson(response);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }

  // Sign Up / Register
  // Future<UserModel?> signUp({
  //   required String email,
  //   required String password,
  //   required String username,
  //   required String fullName,
  //   required String role,
  // }) async {
  //   try {
  //     // 1. Create auth user
  //     final authResponse = await _supabase.auth.signUp(
  //       email: email,
  //       password: password,
  //     );

  //     if (authResponse.user != null) {
  //       // 2. Create user record in users table
  //       final userData = {
  //         'auth_id': authResponse.user!.id,
  //         'username': username,
  //         'email': email,
  //         'full_name': fullName,
  //         'role': role,
  //         'is_active': true,
  //       };

  //       final response =
  //           await _supabase.from('users').insert(userData).select().single();

  //       return UserModel.fromJson(response);
  //     }
  //     return null;
  //   } catch (e) {
  //     throw Exception('Registration failed: $e');
  //   }
  // }

  // Check if user is logged in
  bool isLoggedIn() {
    return _supabase.auth.currentUser != null;
  }
}
