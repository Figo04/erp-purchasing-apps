import 'package:erp_purchasing_apps/core/service/api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:erp_purchasing_apps/data/repositories/product_assessment_repository.dart';
import 'package:erp_purchasing_apps/data/models/product_assessment_model.dart';
import 'package:flutter_riverpod/legacy.dart';

/// Product Assessment Repository Provider
final productAssessmentRepositoryProvider =
    Provider<ProductAssessmentRepository>((ref) {
  return ProductAssessmentRepository(ApiService());
});

/// Product Assessment Notifier
class ProductAssessmentNotifier
    extends StateNotifier<AsyncValue<List<ProductAssessmentModel>>> {
  final ProductAssessmentRepository _repository;

  ProductAssessmentNotifier(this._repository)
      : super(const AsyncValue.loading()) {
    loadAssessments();
  }

  /// Load all product assessments
  Future<void> loadAssessments({String? status, String? search}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await _repository.getAllProductAssessments(
        status: status,
        search: search,
      );
    });
  }

  /// Refresh assessments
  Future<void> refresh() async {
    await loadAssessments();
  }

  /// Get assessment by ID
  Future<ProductAssessmentModel> getById(String id) async {
    return await _repository.getProductAssessmentById(id);
  }

  /// Create new product assessment
  Future<void> createAssessment(CreateProductAssessmentRequest request) async {
    await _repository.createProductAssessment(request);
    await refresh();
  }

  /// Update product assessment
  Future<void> updateAssessment(
      String id, UpdateProductAssessmentRequest request) async {
    await _repository.updateProductAssessment(id, request);
    await refresh();
  }

  /// Delete product assessment
  Future<void> deleteAssessment(String id) async {
    await _repository.deleteProductAssessment(id);
    await refresh();
  }

  /// Verify assessment (warehouse/logistik)
  Future<void> verifyAssessment(String id, {String? notes}) async {
    await _repository.verifyProductAssessment(id, notes: notes);
    await refresh();
  }

  /// Approve assessment (admin/kadiv)
  /// Backend auto-generates product code
  Future<void> approveAssessment(String id, {String? notes}) async {
    await _repository.approveProductAssessment(id,
        notes: notes); // ← NO PRODUCT CODE
    await refresh();
  }

  /// Reject assessment
  Future<void> rejectAssessment(String id, String reason) async {
    await _repository.rejectProductAssessment(id, reason);
    await refresh();
  }
}

/// Product Assessment State Provider
final productAssessmentNotifierProvider = StateNotifierProvider<
    ProductAssessmentNotifier, AsyncValue<List<ProductAssessmentModel>>>((ref) {
  final repository = ref.watch(productAssessmentRepositoryProvider);
  return ProductAssessmentNotifier(repository);
});

/// Search Query Provider
final productAssessmentSearchQueryProvider = StateProvider<String>((ref) => '');

/// Status Filter Provider
final productAssessmentStatusFilterProvider =
    StateProvider<String?>((ref) => null);

/// Filtered Product Assessments Provider
final filteredProductAssessmentsProvider =
    Provider<AsyncValue<List<ProductAssessmentModel>>>((ref) {
  final assessmentsAsync = ref.watch(productAssessmentNotifierProvider);
  final searchQuery = ref.watch(productAssessmentSearchQueryProvider);
  final statusFilter = ref.watch(productAssessmentStatusFilterProvider);

  return assessmentsAsync.whenData((assessments) {
    var filtered = assessments;

    // Apply search filter
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((assessment) {
        return assessment.productName
                .toLowerCase()
                .contains(searchQuery.toLowerCase()) ||
            (assessment.categoryName
                    ?.toLowerCase()
                    .contains(searchQuery.toLowerCase()) ??
                false);
      }).toList();
    }

    // Apply status filter
    if (statusFilter != null) {
      filtered = filtered
          .where((assessment) => assessment.status == statusFilter)
          .toList();
    }

    return filtered;
  });
});
