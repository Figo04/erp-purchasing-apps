import 'package:erp_purchasing_apps/data/models/purchase_order_model.dart';
import 'package:erp_purchasing_apps/core/service/api_service.dart';
import 'package:erp_purchasing_apps/core/constants/api_constants.dart';

/// ============================================
/// PURCHASE ORDER REPOSITORY (UPDATED)
/// ✅ Changes:
/// - Changed getPRGroupingsByCategory → getPRGroupingsBySupplier
/// - Updated endpoint from pr-groupings-by-category → pr-groupings-by-supplier
/// - Return type changed from PRCategoryGroup → PRSupplierGroup
/// ============================================

class PurchaseOrderRepository {
  final ApiService _apiService;

  PurchaseOrderRepository({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  /// Get all POs
  Future<List<PurchaseOrderModel>> getAllPOs({
    String? status,
    String? supplierId,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null) queryParams['status'] = status;
      if (supplierId != null) queryParams['supplier_id'] = supplierId;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await _apiService.get(
        ApiEndpoints.purchaseOrders,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
        fromJson: (json) {
          if (json is List) {
            return json
                .map((item) => PurchaseOrderModel.fromJson(item))
                .toList();
          }
          return <PurchaseOrderModel>[];
        },
      );

      if (!response.isSuccess || response.data == null) {
        throw Exception(response.errorMessage);
      }

      return response.data as List<PurchaseOrderModel>;
    } catch (e) {
      throw Exception('Failed to load POs: $e');
    }
  }

  /// Get PO by ID
  Future<PurchaseOrderModel> getPOById(String id) async {
    try {
      final response = await _apiService.get<PurchaseOrderModel>(
        ApiEndpoints.poById(id),
        fromJson: (json) => PurchaseOrderModel.fromJson(json),
      );

      if (!response.isSuccess || response.data == null) {
        throw Exception(response.errorMessage);
      }

      return response.data!;
    } catch (e) {
      throw Exception('Failed to load PO: $e');
    }
  }

  /// ✅ NEW: Get PR groupings by SUPPLIER (replaces by category)
  /// Endpoint: GET /purchase-orders/helpers/pr-groupings-by-supplier
  Future<List<PRSupplierGroup>> getPRGroupingsBySupplier() async {
    try {
      final response = await _apiService.get(
        '${ApiEndpoints.purchaseOrders}/helpers/pr-groupings-by-supplier',
        fromJson: (json) {
          print('🌐 Raw API Response (PR Groupings by Supplier):');
          print(json);

          if (json is List) {
            return json.map((item) => PRSupplierGroup.fromJson(item)).toList();
          }
          return <PRSupplierGroup>[];
        },
      );

      if (!response.isSuccess || response.data == null) {
        throw Exception(response.errorMessage);
      }

      final groupings = response.data as List<PRSupplierGroup>;

      print('📦 Parsed Supplier Groupings: ${groupings.length}');
      for (var g in groupings) {
        print(
            '  - Supplier: ${g.supplierName}, PRs: ${g.totalPRs}, Code: ${g.supplierCode}');
      }

      return groupings;
    } catch (e) {
      print('❌ Error in getPRGroupingsBySupplier: $e');
      throw Exception('Failed to load PR groupings by supplier: $e');
    }
  }

  /// ⚠️ DEPRECATED: Get PR groupings by category (old method)
  /// Keep for backward compatibility but will be removed
  @Deprecated('Use getPRGroupingsBySupplier instead')
  Future<List<PRCategoryGroup>> getPRGroupingsByCategory() async {
    try {
      final response = await _apiService.get(
        '${ApiEndpoints.purchaseOrders}/helpers/pr-groupings-by-category',
        fromJson: (json) {
          if (json is List) {
            return json.map((item) => PRCategoryGroup.fromJson(item)).toList();
          }
          return <PRCategoryGroup>[];
        },
      );

      if (!response.isSuccess || response.data == null) {
        throw Exception(response.errorMessage);
      }

      return response.data as List<PRCategoryGroup>;
    } catch (e) {
      throw Exception('Failed to load PR groupings by category: $e');
    }
  }

  /// ⚠️ DEPRECATED: Old PR groupings method
  @Deprecated('Use getPRGroupingsBySupplier instead')
  Future<List<dynamic>> getPRGroupings() async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.prGroupings,
        fromJson: (json) {
          if (json is List) {
            return json;
          }
          return [];
        },
      );

      if (!response.isSuccess || response.data == null) {
        throw Exception(response.errorMessage);
      }

      return response.data as List<dynamic>;
    } catch (e) {
      throw Exception('Failed to load PR groupings: $e');
    }
  }

  /// Create new PO
  Future<PurchaseOrderModel> createPO(CreatePORequest request) async {
    try {
      final response = await _apiService.post<PurchaseOrderModel>(
        ApiEndpoints.purchaseOrders,
        body: request.toJson(),
        fromJson: (json) => PurchaseOrderModel.fromJson(json),
      );

      if (!response.isSuccess || response.data == null) {
        throw Exception(response.errorMessage);
      }

      return response.data!;
    } catch (e) {
      throw Exception('Failed to create PO: $e');
    }
  }

  /// Update PO
  Future<PurchaseOrderModel> updatePO(
    String id,
    UpdatePORequest request,
  ) async {
    try {
      final response = await _apiService.put<PurchaseOrderModel>(
        ApiEndpoints.poById(id),
        body: request.toJson(),
        fromJson: (json) => PurchaseOrderModel.fromJson(json),
      );

      if (!response.isSuccess || response.data == null) {
        throw Exception(response.errorMessage);
      }

      return response.data!;
    } catch (e) {
      throw Exception('Failed to update PO: $e');
    }
  }

  /// Delete PO
  Future<void> deletePO(String id) async {
    try {
      final response = await _apiService.delete(
        ApiEndpoints.poById(id),
      );

      if (!response.isSuccess) {
        throw Exception(response.errorMessage);
      }
    } catch (e) {
      throw Exception('Failed to delete PO: $e');
    }
  }

  /// Approve PO (kadiv/admin)
  Future<PurchaseOrderModel> approvePO(String id) async {
    try {
      final response = await _apiService.post<PurchaseOrderModel>(
        ApiEndpoints.approvePO(id),
        fromJson: (json) => PurchaseOrderModel.fromJson(json),
      );

      if (!response.isSuccess || response.data == null) {
        throw Exception(response.errorMessage);
      }

      return response.data!;
    } catch (e) {
      throw Exception('Failed to approve PO: $e');
    }
  }

  /// Cancel PO
  Future<PurchaseOrderModel> cancelPO(String id) async {
    try {
      final response = await _apiService.post<PurchaseOrderModel>(
        ApiEndpoints.cancelPO(id),
        fromJson: (json) => PurchaseOrderModel.fromJson(json),
      );

      if (!response.isSuccess || response.data == null) {
        throw Exception(response.errorMessage);
      }

      return response.data!;
    } catch (e) {
      throw Exception('Failed to cancel PO: $e');
    }
  }
}