import 'package:erp_purchasing_apps/data/models/purchase_requisition_model.dart';
import 'package:erp_purchasing_apps/core/service/api_service.dart';
import 'package:erp_purchasing_apps/core/constants/api_constants.dart';

class PRRepository {
  final ApiService _apiService;

  PRRepository({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  // Get all PRs
  Future<List<PurchaseRequisitionModel>> getAllPRs({
    String? status,
    String? divisionId,
    int? year,
    String? supplierId, 
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null) queryParams['status'] = status;
      if (divisionId != null) queryParams['division_id'] = divisionId;
      if (year != null) queryParams['year'] = year.toString();
      if (supplierId != null) queryParams['supplier_id'] = supplierId; 

      final response = await _apiService.get(
        ApiEndpoints.purchaseRequisitions,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
        fromJson: (json) {
          if (json is List) {
            return json
                .map((item) => PurchaseRequisitionModel.fromJson(item))
                .toList();
          }
          return <PurchaseRequisitionModel>[];
        },
      );

      if (!response.isSuccess || response.data == null) {
        throw Exception(response.errorMessage);
      }

      return response.data as List<PurchaseRequisitionModel>;
    } catch (e) {
      throw Exception('Failed to load PRs: $e');
    }
  }

  // Get PRs by user
  Future<List<PurchaseRequisitionModel>> getPRsByUser(String userId) async {
    try {
      final allPRs = await getAllPRs();
      return allPRs.where((pr) => pr.requesterId == userId).toList();
    } catch (e) {
      throw Exception('Failed to load user PRs: $e');
    }
  }

  // Get PR by ID
  Future<PurchaseRequisitionModel?> getPRById(String id) async {
    try {
      final response = await _apiService.get<PurchaseRequisitionModel>(
        ApiEndpoints.prById(id),
        fromJson: (json) => PurchaseRequisitionModel.fromJson(json),
      );

      if (!response.isSuccess || response.data == null) {
        throw Exception(response.errorMessage);
      }

      return response.data!;
    } catch (e) {
      throw Exception('Failed to load PR: $e');
    }
  }

  // Create PR with simplified items
  Future<PurchaseRequisitionModel> createPR(CreatePRRequest request) async {
    try {
      final response = await _apiService.post<PurchaseRequisitionModel>(
        ApiEndpoints.purchaseRequisitions,
        body: request.toJson(),
        fromJson: (json) => PurchaseRequisitionModel.fromJson(json),
      );

      if (!response.isSuccess || response.data == null) {
        throw Exception(response.errorMessage);
      }

      return response.data!;
    } catch (e) {
      throw Exception('Failed to create PR: $e');
    }
  }

  // Update PR (only draft)
  Future<PurchaseRequisitionModel> updatePR(
    String id,
    UpdatePRRequest request,
  ) async {
    try {
      final response = await _apiService.put<PurchaseRequisitionModel>(
        ApiEndpoints.prById(id),
        body: request.toJson(),
        fromJson: (json) => PurchaseRequisitionModel.fromJson(json),
      );

      if (!response.isSuccess || response.data == null) {
        throw Exception(response.errorMessage);
      }

      return response.data!;
    } catch (e) {
      throw Exception('Failed to update PR: $e');
    }
  }

  // Delete PR
  Future<void> deletePR(String id) async {
    try {
      final response = await _apiService.delete(
        ApiEndpoints.prById(id),
      );

      if (!response.isSuccess) {
        throw Exception(response.errorMessage);
      }
    } catch (e) {
      throw Exception('Failed to delete PR: $e');
    }
  }

  // Approve PR (kadiv/admin)
  Future<PurchaseRequisitionModel> approvePR(String id) async {
    try {
      final response = await _apiService.post<PurchaseRequisitionModel>(
        ApiEndpoints.approvePR(id),
        fromJson: (json) => PurchaseRequisitionModel.fromJson(json),
      );

      if (!response.isSuccess || response.data == null) {
        throw Exception(response.errorMessage);
      }

      return response.data!;
    } catch (e) {
      throw Exception('Failed to approve PR: $e');
    }
  }

  // Reject PR (kadiv/admin)
  Future<PurchaseRequisitionModel> rejectPR(
    String id,
    String reason,
  ) async {
    try {
      final response = await _apiService.post<PurchaseRequisitionModel>(
        ApiEndpoints.rejectPR(id),
        body: {
          'rejection_reason': reason
        }, // use rejection_reason (match backend)
        fromJson: (json) => PurchaseRequisitionModel.fromJson(json),
      );

      if (!response.isSuccess || response.data == null) {
        throw Exception(response.errorMessage);
      }

      return response.data!;
    } catch (e) {
      throw Exception('Failed to reject PR: $e');
    }
  }

  // Close PR (after PO created)
  Future<PurchaseRequisitionModel> closePR(String id) async {
    try {
      final response = await _apiService.post<PurchaseRequisitionModel>(
        ApiEndpoints.closePR(id),
        fromJson: (json) => PurchaseRequisitionModel.fromJson(json),
      );

      if (!response.isSuccess || response.data == null) {
        throw Exception(response.errorMessage);
      }

      return response.data!;
    } catch (e) {
      throw Exception('Failed to close PR: $e');
    }
  }
}
