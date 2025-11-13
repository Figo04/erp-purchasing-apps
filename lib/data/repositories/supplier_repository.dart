import 'package:erp_purchasing_apps/data/models/supplier_model.dart';
import 'package:erp_purchasing_apps/core/service/api_service.dart';
import 'package:erp_purchasing_apps/core/constants/api_constants.dart';

class SupplierRepository {
  final ApiService _apiService;

  SupplierRepository({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  // Get all suppliers
  Future<List<SupplierModel>> getAllSuppliers({
    String? search,
    bool? isActive,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (isActive != null) {
        queryParams['is_active'] = isActive.toString();
      }

      final response = await _apiService.get(
        ApiEndpoints.suppliers,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
        fromJson: (json) {
          if (json is List) {
            return json.map((item) => SupplierModel.fromJson(item)).toList();
          }
          return <SupplierModel>[];
        },
      );

      if (!response.isSuccess || response.data == null) {
        throw Exception(response.errorMessage);
      }

      return response.data as List<SupplierModel>;
    } catch (e) {
      throw Exception('Failed to load suppliers : $e');
    }
  }

  // // Mendapatkan hanya suppliers aktif
  // Future<List<SupplierModel>> getActiveSuppliers() async {
  //   try {
  //     final response = await _supabase
  //         .from('suppliers')
  //         .select()
  //         .eq('is_active', true)
  //         .order('name', ascending: true);

  //     return (response as List)
  //         .map((json) => SupplierModel.fromJson(json))
  //         .toList();
  //   } catch (e) {
  //     throw Exception('Failed to load active suppliers: $e');
  //   }
  // }

  // mendapatkan supplier by ID
  Future<SupplierModel?> getSupplierById(String id) async {
    try {
      final response = await _apiService.get<SupplierModel>(
        ApiEndpoints.supplierById(id),
        fromJson: (json) => SupplierModel.fromJson(json),
      );

      if (!response.isSuccess || response.data == null) {
        throw Exception(response.errorMessage);
      }

      return response.data!;
    } catch (e) {
      throw Exception('Failed to load supplier: $e');
    }
  }

  /// Create new supplier
  Future<SupplierModel> createSupplier(CreateSupplierRequest request) async {
    try {
      final response = await _apiService.post<SupplierModel>(
        ApiEndpoints.suppliers,
        body: request.toJson(),
        fromJson: (json) => SupplierModel.fromJson(json),
      );

      if (!response.isSuccess || response.data == null) {
        throw Exception(response.errorMessage);
      }

      return response.data!;
    } catch (e) {
      throw Exception('Failed to create supplier: $e');
    }
  }

  // Update supplier
  Future<SupplierModel> updatedSupplier(
    String id,
    UpdateSupplierRequest request,
  ) async {
    try {
      final response = await _apiService.put<SupplierModel>(
        ApiEndpoints.supplierById(id),
        body: request.toJson(),
        fromJson: (json) => SupplierModel.fromJson(json),
      );

      if (!response.isSuccess || response.data == null) {
        throw Exception(response.errorMessage);
      }

      return response.data!;
    } catch (e) {
      throw Exception('Failed to update supplier: $e');
    }
  }

  // menghapus supplier (soft delet - set inactive)
  Future<void> deleteSupplier(String id) async {
    try {
      final response = await _apiService.delete(
        ApiEndpoints.supplierById(id),
      );

      if (!response.isSuccess) {
        throw Exception(response.errorMessage);
      }
    } catch (e) {
      throw Exception('Failed to delete supplier: $e');
    }
  }

  // Search suppliers
  Future<List<SupplierModel>> searchSuppliers(String query) async {
    try {
      return await getAllSuppliers(search: query, isActive: true);
    } catch (e) {
      throw Exception('Failed to search suppliers: $e');
    }
  }
}
