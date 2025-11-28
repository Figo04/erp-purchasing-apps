import 'package:erp_purchasing_apps/data/models/purchase_order_model.dart';
import 'package:erp_purchasing_apps/core/service/api_service.dart';
import 'package:erp_purchasing_apps/core/constants/api_constants.dart';

/// Purchase Order Repository
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

  /// Get PR groupings (for PO creation)
  Future<List<PRGrouping>> getPRGroupings() async {
    try {
      final response = await _apiService.get(
        ApiEndpoints
            .prGroupings, // Pastikan ini '/purchase-orders/helpers/pr-groupings'
        fromJson: (json) {
          print('🌐 Raw API Response:');
          print(json); // ⭐ Debug log

          if (json is List) {
            return json.map((item) => PRGrouping.fromJson(item)).toList();
          }
          return <PRGrouping>[];
        },
      );

      if (!response.isSuccess || response.data == null) {
        throw Exception(response.errorMessage);
      }

      final groupings = response.data as List<PRGrouping>;

      print('📦 Parsed Groupings: ${groupings.length}');
      for (var g in groupings) {
        print(
            '  - Category: ${g.categoryName}, PRs: ${g.prIds.length}, Items: ${g.items.length}');
      }

      return groupings;
    } catch (e) {
      print('❌ Error in getPRGroupings: $e');
      throw Exception('Failed to load PR groupings: $e');
    }
  }

  /// Get PR groupings by category (NEW)
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
