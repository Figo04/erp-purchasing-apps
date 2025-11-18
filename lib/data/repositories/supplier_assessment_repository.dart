import 'package:erp_purchasing_apps/core/service/api_service.dart';
import 'package:erp_purchasing_apps/core/constants/api_constants.dart';
import 'package:erp_purchasing_apps/data/models/supplier_assessment_model.dart';

// Supplier Assessment Repository
// Handles API calls for supplier assessment operations

class SupplierAssessmentRepository {
  final ApiService _apiService;

  SupplierAssessmentRepository(this._apiService);

  // Get all supplier assessments
  Future<List<SupplierAssessmentModel>> getAllSupplierAssessments({
    String? status,
    String? search,
  }) async {
    final queryParams = <String, dynamic>{};
    if (status != null) queryParams['status'] = status;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    final response = await _apiService.get<List<dynamic>>(
      ApiEndpoints.supplierAssessments,
      queryParameters: queryParams,
      fromJson: (json) => json as List<dynamic>,
    );

    if (response.data == null) return [];

    return response.data!
        .map((item) =>
            SupplierAssessmentModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Get supplier assessment by ID
  Future<SupplierAssessmentModel> getSupplierAssessmentById(String id) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiEndpoints.supplierAssessmentById(id),
      fromJson: (json) => json as Map<String, dynamic>,
    );

    if (response.data == null) {
      throw Exception('Supplier assessment not found');
    }

    return SupplierAssessmentModel.fromJson(response.data!);
  }

  /// Create new supplier assessment
  Future<SupplierAssessmentModel> createSupplierAssessment(
    CreateSupplierAssessmentRequest request,
  ) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiEndpoints.supplierAssessments,
      body: request.toJson(),
      fromJson: (json) => json as Map<String, dynamic>,
    );

    if (response.data == null) {
      throw Exception('Failed to create supplier assessment');
    }

    return SupplierAssessmentModel.fromJson(response.data!);
  }

  // Update supplier assessment (only requester can update)
  Future<SupplierAssessmentModel> updateSupplierAssessment(
    String id,
    UpdateSupplierAssessmentRequest request,
  ) async {
    final response = await _apiService.put<Map<String, dynamic>>(
      ApiEndpoints.supplierAssessmentById(id),
      body: request.toJson(),
      fromJson: (json) => json as Map<String, dynamic>,
    );

    if (response.data == null) {
      throw Exception('Failed to update supplier assessment');
    }

    return SupplierAssessmentModel.fromJson(response.data!);
  }

  /// Delete supplier assessment (only requester can delete)
  Future<void> deleteSupplierAssessment(String id) async {
    await _apiService.delete(
      ApiEndpoints.supplierAssessmentById(id),
    );
  }

  /// Verify supplier assessment (warehouse/logistik role)
  Future<SupplierAssessmentModel> verifySupplierAssessment(
    String id, {
    String? notes,
  }) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiEndpoints.verifySupplierAssessment(id),
      body: SupplierAssessmentActionRequest(notes: notes).toJson(),
      fromJson: (json) => json as Map<String, dynamic>,
    );

    if (response.data == null) {
      throw Exception('Failed to verify supplier assessment');
    }

    return SupplierAssessmentModel.fromJson(response.data!);
  }

  // Approve supplier assessment (admin role)
  Future<SupplierAssessmentModel> approveSupplierAssessment(
    String id, {
    String? notes,
  }) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiEndpoints.approveSupplierAssessment(id),
      body: SupplierAssessmentActionRequest(notes: notes).toJson(),
      fromJson: (json) => json as Map<String, dynamic>,
    );

    if (response.data == null) {
      throw Exception('Failed to approve supplier assesment');
    }

    return SupplierAssessmentModel.fromJson(response.data!);
  }

   // Reject supplier assessment (admin or warehouse role)
  Future<SupplierAssessmentModel> rejectSupplierAssessment(
    String id,
    String rejectionReason,
  ) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiEndpoints.rejectSupplierAssessment(id),
      body: SupplierAssessmentActionRequest(rejectionReason: rejectionReason).toJson(),
      fromJson: (json) => json as Map<String, dynamic>,
    );

    if (response.data == null) {
      throw Exception('Failed to reject supplier assessment');
    }

    return SupplierAssessmentModel.fromJson(response.data!);
  }
}
