import 'package:erp_purchasing_apps/core/constants/api_constants.dart';
import 'package:erp_purchasing_apps/core/service/api_service.dart';
import 'package:erp_purchasing_apps/data/models/product_assessment_model.dart';

/// Product Assessment Repository
/// Handles API calls for product assessment operations
class ProductAssessmentRepository {
  final ApiService _apiService;

  ProductAssessmentRepository(this._apiService);

  /// Get all product assessments
  Future<List<ProductAssessmentModel>> getAllProductAssessments({
    String? status,
    String? search,
  }) async {
    final queryParams = <String, dynamic>{};
    if (status != null) queryParams['status'] = status;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    final response = await _apiService.get<List<dynamic>>(
      ApiEndpoints.productAssessments,
      queryParameters: queryParams,
      fromJson: (json) => json as List<dynamic>,
    );

    if (response.data == null) return [];

    return response.data!
        .map((item) =>
            ProductAssessmentModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Get product assessment by ID
  Future<ProductAssessmentModel> getProductAssessmentById(String id) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiEndpoints.productAssessmentById(id),
      fromJson: (json) => json as Map<String, dynamic>,
    );

    if (response.data == null) {
      throw Exception('Product assessment not found');
    }

    return ProductAssessmentModel.fromJson(response.data!);
  }

  /// Create new product assessment
  Future<ProductAssessmentModel> createProductAssessment(
    CreateProductAssessmentRequest request,
  ) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiEndpoints.productAssessments,
      body: request.toJson(),
      fromJson: (json) => json as Map<String, dynamic>,
    );

    if (response.data == null) {
      throw Exception('Failed to create product assessment');
    }

    return ProductAssessmentModel.fromJson(response.data!);
  }

  /// Update product assessment (only requester can update)
  Future<ProductAssessmentModel> updateProductAssessment(
    String id,
    UpdateProductAssessmentRequest request,
  ) async {
    final response = await _apiService.put<Map<String, dynamic>>(
      ApiEndpoints.productAssessmentById(id),
      body: request.toJson(),
      fromJson: (json) => json as Map<String, dynamic>,
    );

    if (response.data == null) {
      throw Exception('Failed to update product assessment');
    }

    return ProductAssessmentModel.fromJson(response.data!);
  }

  /// Delete product assessment (only requester can delete)
  Future<void> deleteProductAssessment(String id) async {
    await _apiService.delete(
      ApiEndpoints.productAssessmentById(id),
    );
  }

  /// Verify product assessment (warehouse/logistik role)
  Future<ProductAssessmentModel> verifyProductAssessment(
    String id, {
    String? notes,
  }) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiEndpoints.verifyProductAssessment(id),
      body: AssessmentActionRequest(notes: notes).toJson(),
      fromJson: (json) => json as Map<String, dynamic>,
    );

    if (response.data == null) {
      throw Exception('Failed to verify product assessment');
    }

    // ✅ Same fix for consistency
    final data = response.data!;

    if (data.containsKey('assessment')) {
      return ProductAssessmentModel.fromJson(
          data['assessment'] as Map<String, dynamic>);
    }

    return ProductAssessmentModel.fromJson(data);
  }

  /// Approve product assessment (admin/kadiv role)
  /// Backend will auto-generate product code
  Future<ProductAssessmentModel> approveProductAssessment(
    String id, {
    String? notes,
  }) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiEndpoints.approveProductAssessment(id),
      body: AssessmentActionRequest(notes: notes).toJson(),
      fromJson: (json) => json as Map<String, dynamic>,
    );

    if (response.data == null) {
      throw Exception('Failed to approve product assessment');
    }

    final data = response.data!;

    if (data.containsKey('assessment')) {
      // Nested structure from approve endpoint
      return ProductAssessmentModel.fromJson(
          data['assessment'] as Map<String, dynamic>);
    }

    // Fallback for direct structure (should not happen, but safe)
    return ProductAssessmentModel.fromJson(data);
  }

  /// Reject product assessment (admin or warehouse role)
  Future<ProductAssessmentModel> rejectProductAssessment(
    String id,
    String rejectionReason,
  ) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiEndpoints.rejectProductAssessment(id),
      body: AssessmentActionRequest(rejectionReason: rejectionReason).toJson(),
      fromJson: (json) => json as Map<String, dynamic>,
    );

    if (response.data == null) {
      throw Exception('Failed to reject product assessment');
    }

    return ProductAssessmentModel.fromJson(response.data!);
  }
}
