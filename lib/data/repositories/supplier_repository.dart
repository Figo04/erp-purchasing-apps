import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:erp_purchasing_apps/data/models/supplier_model.dart';

class SupplierRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Mendapatkan semua suppliers
  Future<List<SupplierModel>> getAllSuppliers() async {
    try {
      final response = await _supabase
          .from('suppliers')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => SupplierModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load suppliers : $e');
    }
  }

  // Mendapatkan hanya suppliers aktif
  Future<List<SupplierModel>> getActiveSuppliers() async {
    try {
      final response = await _supabase
          .from('suppliers')
          .select()
          .eq('is_active', true)
          .order('name', ascending: true);

      return (response as List)
          .map((json) => SupplierModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load active suppliers: $e');
    }
  }

  // mendapatkan supplier by ID
  Future<SupplierModel?> getSupplierById(String id) async {
    try {
      final response =
          await _supabase.from('suppliers').select().eq('id', id).maybeSingle();

      if (response == null) return null;
      return SupplierModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to load supplier: $e');
    }
  }

  // Membuat supplier
  Future<SupplierModel> createSupplier({
    required String name,
    String? contactName,
    String? phone,
    String? email,
    String? address,
  }) async {
    try {
      final data = {
        'name': name,
        'contact_name': contactName,
        'phone': phone,
        'email': email,
        'address': address,
        'is_active': true,
      };

      final response =
          await _supabase.from('suppliers').insert(data).select().single();

      return SupplierModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create supplier: $e');
    }
  }

  // Update supplier
  Future<SupplierModel> updateSupplier({
    required String id,
    required String name,
    String? contactName,
    String? phone,
    String? email,
    String? address,
    required bool isActive,
  }) async {
    try {
      final data = {
        'name': name,
        'contact_name': contactName,
        'phone': phone,
        'email': email,
        'address': address,
        'is_active': isActive,
      };

      final response = await _supabase
          .from('suppliers')
          .update(data)
          .eq('id', id)
          .select()
          .single();

      return SupplierModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update supplier: $e');
    }
  }

  // menghapus supplier (soft delet - set inactive)
  Future<void> deleteSupplier(String id) async {
    try {
      await _supabase
          .from('suppliers')
          .update({'is_active': false}).eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete supplier: $e');
    }
  }

  // Mencari suppliers
  Future<List<SupplierModel>> searchSuppliers(String query) async {
    try {
      final response = await _supabase
          .from('suppliers')
          .select()
          .or('name.ilike.%$query%,contact_name.ilike.%$query%')
          .order('name', ascending: true);

      return (response as List)
          .map((json) => SupplierModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to search suppliers: $e');
    }
  }
}
