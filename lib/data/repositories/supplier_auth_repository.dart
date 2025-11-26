import 'package:erp_purchasing_apps/core/constants/api_constants.dart';
import 'package:erp_purchasing_apps/core/service/api_service.dart';
import '../models/supplier_model.dart';

/// Supplier Authentication Repository
/// Uses Golang backend API (no more Supabase)
class SupplierAuthRepository {
  final ApiService _apiService = ApiService();

  /// Sign in supplier menggunakan backend Golang
  Future<SupplierModel?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      print('🔐 SupplierAuthRepository: Starting sign in...');
      print('📧 Email: $email');

      // ✅ Pakai endpoint /auth/login (sama seperti internal user)
      final response = await _apiService.post(
        ApiEndpoints.login,
        body: {
          'email': email,
          'password': password,
        },
        requiresAuth: false,
      );

      print('📦 Response: ${response.success}');

      if (!response.success) {
        throw Exception(response.message);
      }

      // ✅ Check apakah response untuk supplier (bukan internal user)
      final data = response.data as Map<String, dynamic>;
      
      print('🔍 Response data: $data');
      print('🔍 Role: ${data['role']}');

      if (data['role'] != 'supplier') {
        throw Exception('Unauthorized: This is not a supplier account');
      }

      // ✅ Save JWT token
      final token = data['token'] as String;
      await _apiService.saveToken(token);
      print('✅ Token saved');

      // ✅ Parse supplier data
      final supplierData = data['supplier'] as Map<String, dynamic>;
      final supplier = SupplierModel.fromJson(supplierData);

      print('✅ Supplier model created: ${supplier.name}');
      print('   - ID: ${supplier.id}');
      print('   - Can Login: ${supplier.canLogin}');

      return supplier;
    } catch (e) {
      print('❌ Supplier login failed: $e');
      rethrow;
    }
  }

  /// ✅ Get current supplier dari JWT token
  /// (Backend akan validasi token dan return supplier info)
  Future<SupplierModel?> getCurrentSupplier() async {
    try {
      print('🔍 Getting current supplier from token...');

      // Check if token exists
      final hasToken = await _apiService.hasToken();
      if (!hasToken) {
        print('ℹ️ No token found');
        return null;
      }

      // Call profile endpoint (backend will validate token)
      final response = await _apiService.get(
        ApiEndpoints.profile,
        requiresAuth: true,
      );

      if (!response.success) {
        print('⚠️ Failed to get profile: ${response.message}');
        return null;
      }

      final data = response.data as Map<String, dynamic>;
      
      // Check if this is supplier (not internal user)
      if (data['role'] != 'supplier') {
        print('⚠️ Not a supplier account');
        return null;
      }

      // Parse supplier data
      final supplierData = data['supplier'] as Map<String, dynamic>;
      final supplier = SupplierModel.fromJson(supplierData);

      print('✅ Current supplier: ${supplier.name}');
      return supplier;
    } catch (e) {
      print('❌ Get current supplier error: $e');
      return null;
    }
  }

  /// ✅ Sign out supplier
  Future<void> signOut() async {
    try {
      print('👋 SupplierAuthRepository: Logging out...');
      await _apiService.removeToken();
      print('✅ Logout complete');
    } catch (e) {
      print('❌ SupplierAuthRepository sign out error: $e');
      rethrow;
    }
  }
}