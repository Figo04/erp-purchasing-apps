import 'package:erp_purchasing_apps/core/service/api_service.dart';
import 'package:erp_purchasing_apps/core/constants/api_constants.dart';
import 'package:erp_purchasing_apps/data/models/tracking_model.dart';

class TrackingRepository {
  final ApiService _apiService = ApiService();

  // ============================================
  // DOCUMENT TRACKING
  // ============================================

  Future<List<DocumentTracking>> getAllDocumentTracking({
    String? prId,
    String? poId,
    String? shipmentId,
    String? lpbId,
    String? documentType,
    String? currentStatus,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};

      if (prId != null) queryParams['pr_id'] = prId;
      if (poId != null) queryParams['po_id'] = poId;
      if (shipmentId != null) queryParams['shipment_id'] = shipmentId;
      if (lpbId != null) queryParams['lpb_id'] = lpbId;
      if (documentType != null) queryParams['document_type'] = documentType;
      if (currentStatus != null) queryParams['current_status'] = currentStatus;
      if (fromDate != null) {
        queryParams['from_date'] = fromDate.toIso8601String().split('T')[0];
      }
      if (toDate != null) {
        queryParams['to_date'] = toDate.toIso8601String().split('T')[0];
      }

      final response = await _apiService.get(
        ApiEndpoints.documentTracking,
        queryParameters: queryParams,
      );

      if (response.success && response.data != null) {
        final List<dynamic> dataList = response.data as List<dynamic>;
        return dataList.map((json) => DocumentTracking.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      throw Exception('Failed to get document tracking: $e');
    }
  }

  Future<DocumentTracking?> getDocumentTrackingById(String id) async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.documentTrackingById(id),
      );

      if (response.success && response.data != null) {
        return DocumentTracking.fromJson(response.data);
      }

      return null;
    } catch (e) {
      throw Exception('Failed to get document tracking: $e');
    }
  }

  Future<List<TrackingTimeline>> getTrackingTimeline(String prId) async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.trackingTimeline(prId),
      );

      if (response.success && response.data != null) {
        final List<dynamic> dataList = response.data as List<dynamic>;
        return dataList.map((json) => TrackingTimeline.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      throw Exception('Failed to get tracking timeline: $e');
    }
  }

  // ============================================
  // ACTIVITY LOG
  // ============================================

  Future<List<ActivityLog>> getAllActivityLogs({
    String? userId,
    String? action,
    String? entityType,
    String? entityId,
    DateTime? fromDate,
    DateTime? toDate,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{};

      if (userId != null) queryParams['user_id'] = userId;
      if (action != null) queryParams['action'] = action;
      if (entityType != null) queryParams['entity_type'] = entityType;
      if (entityId != null) queryParams['entity_id'] = entityId;
      if (fromDate != null) {
        queryParams['from_date'] = fromDate.toIso8601String().split('T')[0];
      }
      if (toDate != null) {
        queryParams['to_date'] = toDate.toIso8601String().split('T')[0];
      }
      if (search != null) queryParams['search'] = search;

      final response = await _apiService.get(
        ApiEndpoints.activityLogs,
        queryParameters: queryParams,
      );

      if (response.success && response.data != null) {
        final List<dynamic> dataList = response.data as List<dynamic>;
        return dataList.map((json) => ActivityLog.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      throw Exception('Failed to get activity logs: $e');
    }
  }

  Future<List<ActivityLog>> getUserActivityHistory(
    String userId, {
    int limit = 100,
  }) async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.userActivityHistory(userId),
        queryParameters: {'limit': limit.toString()},
      );

      if (response.success && response.data != null) {
        final List<dynamic> dataList = response.data as List<dynamic>;
        return dataList.map((json) => ActivityLog.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      throw Exception('Failed to get user activity history: $e');
    }
  }

  // ============================================
  // ITEM TRACKING
  // ============================================

  Future<List<ItemTracking>> getAllItemTracking({
    String? productId,
    String? categoryId,
    String? currentStage,
    bool? isComplete,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{};

      if (productId != null) queryParams['product_id'] = productId;
      if (categoryId != null) queryParams['category_id'] = categoryId;
      if (currentStage != null) queryParams['current_stage'] = currentStage;
      if (isComplete != null) {
        queryParams['is_complete'] = isComplete.toString();
      }
      if (search != null) queryParams['search'] = search;

      final response = await _apiService.get(
        ApiEndpoints.itemTracking,
        queryParameters: queryParams,
      );

      if (response.success && response.data != null) {
        final List<dynamic> dataList = response.data as List<dynamic>;
        return dataList.map((json) => ItemTracking.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      throw Exception('Failed to get item tracking: $e');
    }
  }

  Future<ItemTracking?> getItemTrackingById(String id) async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.itemTrackingById(id),
      );

      if (response.success && response.data != null) {
        return ItemTracking.fromJson(response.data);
      }

      return null;
    } catch (e) {
      throw Exception('Failed to get item tracking: $e');
    }
  }

  Future<List<ItemTracking>> getItemTrackingByProduct(String productId) async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.itemTrackingByProduct(productId),
      );

      if (response.success && response.data != null) {
        final List<dynamic> dataList = response.data as List<dynamic>;
        return dataList.map((json) => ItemTracking.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      throw Exception('Failed to get item tracking by product: $e');
    }
  }

  // ============================================
  // PURCHASE FLOW SUMMARY
  // ============================================

  Future<List<PurchaseFlowSummary>> getPurchaseFlowSummary({
    String? divisionId,
    String? processingType,
    String? overallStatus,
    DateTime? fromDate,
    DateTime? toDate,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{};

      if (divisionId != null) queryParams['division_id'] = divisionId;
      if (processingType != null) {
        queryParams['processing_type'] = processingType;
      }
      if (overallStatus != null) queryParams['overall_status'] = overallStatus;
      if (fromDate != null) {
        queryParams['from_date'] = fromDate.toIso8601String().split('T')[0];
      }
      if (toDate != null) {
        queryParams['to_date'] = toDate.toIso8601String().split('T')[0];
      }
      if (search != null) queryParams['search'] = search;

      final response = await _apiService.get(
        ApiEndpoints.purchaseFlowSummary,
        queryParameters: queryParams,
      );

      if (response.success && response.data != null) {
        final List<dynamic> dataList = response.data as List<dynamic>;
        return dataList
            .map((json) => PurchaseFlowSummary.fromJson(json))
            .toList();
      }

      return [];
    } catch (e) {
      throw Exception('Failed to get purchase flow summary: $e');
    }
  }

  Future<PurchaseFlowSummary?> getFlowDetailsByPR(String prId) async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.flowDetailsByPR(prId),
      );

      if (response.success && response.data != null) {
        return PurchaseFlowSummary.fromJson(response.data);
      }

      return null;
    } catch (e) {
      throw Exception('Failed to get flow details: $e');
    }
  }
}