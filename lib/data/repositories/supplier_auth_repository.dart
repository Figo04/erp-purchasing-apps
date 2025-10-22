import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/supplier_model.dart';

class SupplierAuthRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// ✅ Sign in supplier menggunakan Supabase Auth
  Future<SupplierModel?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      print('🔐 SupplierAuthRepository: Starting sign in...');
      print('📧 Email: $email');

      // 1. ✅ Login via Supabase Auth (untuk validasi password)
      final authResponse = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      print('✅ Supabase auth success');
      print('👤 User ID: ${authResponse.user?.id}');

      if (authResponse.user == null) {
        throw Exception('Authentication failed: No user returned');
      }

      // 2. ✅ Fetch supplier data dari database menggunakan auth_email
      print('🔍 Fetching supplier data from database...');
      final supplierData = await _supabase
          .from('suppliers')
          .select()
          .eq('auth_email', email)  // ✅ Pakai auth_email
          .maybeSingle();

      print('📦 Supplier response: $supplierData');

      if (supplierData == null) {
        // Logout jika supplier tidak ditemukan
        await _supabase.auth.signOut();
        throw Exception('Data supplier tidak ditemukan di database');
      }

      // 3. ✅ Check apakah supplier boleh login
      if (supplierData['can_login'] != true) {
        await _supabase.auth.signOut();
        throw Exception('Akun supplier tidak memiliki akses login. Hubungi admin.');
      }

      // 4. ✅ Check apakah supplier aktif
      if (supplierData['is_active'] != true) {
        await _supabase.auth.signOut();
        throw Exception('Akun supplier tidak aktif. Hubungi admin.');
      }

      // 5. ✅ Convert ke SupplierModel
      final supplier = SupplierModel.fromJson(supplierData);
      print('✅ Supplier model created: ${supplier.name}');
      print('   - ID: ${supplier.id}');
      print('   - Name: ${supplier.name}');
      print('   - Email: ${supplier.email}');
      print('   - Can Login: ${supplier.canLogin}');
      
      return supplier;
    } on AuthException catch (e) {
      // Error dari Supabase Auth
      print('❌ Auth error: ${e.message}');
      throw Exception('Login gagal: ${e.message}');
    } catch (e) {
      print('❌ SupplierAuthRepository sign in error: $e');
      rethrow;
    }
  }

  /// ✅ Get current supplier dari session aktif
  Future<SupplierModel?> getCurrentSupplier() async {
    try {
      final session = _supabase.auth.currentSession;
      
      if (session == null) {
        print('ℹ️ No active session');
        return null;
      }

      final email = session.user.email;
      if (email == null) {
        print('⚠️ Session exists but no email');
        return null;
      }

      print('🔍 Found active session, fetching supplier data...');
      final supplierData = await _supabase
          .from('suppliers')
          .select()
          .eq('auth_email', email)
          .maybeSingle();

      if (supplierData != null && 
          supplierData['can_login'] == true && 
          supplierData['is_active'] == true) {
        final supplier = SupplierModel.fromJson(supplierData);
        print('✅ Current supplier: ${supplier.name}');
        return supplier;
      }

      print('⚠️ Supplier data not found or not authorized');
      return null;
    } catch (e) {
      print('❌ Get current supplier error: $e');
      return null;
    }
  }

  /// ✅ Sign out supplier
  Future<void> signOut() async {
    try {
      print('👋 SupplierAuthRepository: Logging out...');
      await _supabase.auth.signOut();
      print('✅ Logout complete');
    } catch (e) {
      print('❌ SupplierAuthRepository sign out error: $e');
      rethrow;
    }
  }
}