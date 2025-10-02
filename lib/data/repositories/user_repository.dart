import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:erp_purchasing_apps/data/models/user_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

class UserRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ✅ Ambil semua user
  Future<List<UserModel>> getAllUsers() async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => UserModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load users: $e');
    }
  }

  // ✅ Ambil user berdasarkan ID
  Future<UserModel?> getUserById(String id) async {
    try {
      final response =
          await _supabase.from('users').select().eq('id', id).maybeSingle();

      if (response == null) return null;
      return UserModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to load user: $e');
    }
  }

  // 🔥 UPDATED: Admin membuat user via Edge Function
  Future<UserModel> adminCreateUser({
    required String email,
    required String username,
    required String password,
    String? fullName,
    required String role,
  }) async {
    try {
      print('🔵 Calling Edge Function: create-user');
      print('📧 Email: $email | Username: $username | Role: $role');

      // Panggil Edge Function
      final response = await _supabase.functions.invoke(
        'create-user',
        body: {
          'email': email,
          'password': password,
          'username': username,
          'fullName': fullName,
          'role': role,
        },
      );

      print('📊 Response Status: ${response.status}');
      print('📦 Response Data: ${response.data}');

      // Cek response
      if (response.status != 200) {
        final errorMessage = response.data is Map
            ? (response.data['error'] ?? 'Unknown error')
            : 'Failed to create user';
        throw Exception(errorMessage);
      }

      // Parse response
      final data = response.data;
      if (data is! Map || data['data'] == null) {
        throw Exception('Invalid response format from Edge Function');
      }

      print('✅ User created successfully');
      return UserModel.fromJson(data['data']);
    } on FunctionException catch (e) {
      print('❌ FunctionException: ${e.status} | ${e.details}');

      // Parse error message dari details
      String errorMsg = 'Failed to create user';
      if (e.details is Map && e.details['error'] != null) {
        errorMsg = e.details['error'];
      }

      throw Exception(errorMsg);
    } catch (e) {
      print('❌ Error: $e');
      throw Exception('Failed to create user: $e');
    }
  }

  // ✅ Update data user
  Future<UserModel> updateUser({
    required String id,
    required String username,
    required String email,
    String? fullName,
    required String role,
    required bool isActive,
  }) async {
    try {
      final data = {
        'username': username,
        'email': email,
        'full_name': fullName,
        'role': role,
        'is_active': isActive,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('users')
          .update(data)
          .eq('id', id)
          .select()
          .single();

      return UserModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  // ✅ Update password
  Future<void> updateUserPassword({
    required String authId,
    required String newPassword,
  }) async {
    try {
      await _supabase.auth.admin.updateUserById(
        authId,
        attributes: AdminUserAttributes(password: newPassword),
      );
    } catch (e) {
      throw Exception('Failed to update password: $e');
    }
  }

  // ✅ Soft delete user
  Future<void> deleteUser(String id) async {
    try {
      await _supabase.from('users').update({'is_active': false}).eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

  // ✅ Search users
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .or('username.ilike.%$query%,email.ilike.%$query%,full_name.ilike.%$query%')
          .order('username', ascending: true);

      return (response as List)
          .map((json) => UserModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to search users: $e');
    }
  }
}
