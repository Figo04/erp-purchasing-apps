import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:erp_purchasing_apps/core/service/api_service.dart';
import 'package:erp_purchasing_apps/data/repositories/supplier_assessment_repository.dart';
import 'package:erp_purchasing_apps/data/models/supplier_assessment_model.dart';
import 'package:flutter_riverpod/legacy.dart';

/// Supplier Assessment Repository Provider
final supplierAssessmentRepositoryProvider = Provider<SupplierAssessmentRepository>((ref) {
  return SupplierAssessmentRepository(ApiService());
});

/// Supplier Assessment Notifier
class SupplierAssessmentNotifier extends StateNotifier<AsyncValue<List<SupplierAssessmentModel>>> {
  final SupplierAssessmentRepository _repository;

  SupplierAssessmentNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadAssessments();
  }

  /// Load all supplier assessments
  Future<void> loadAssessments({String? status, String? search}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await _repository.getAllSupplierAssessments(
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
  Future<SupplierAssessmentModel> getById(String id) async {
    return await _repository.getSupplierAssessmentById(id);
  }

  /// Create new supplier assessment
  Future<void> createAssessment(CreateSupplierAssessmentRequest request) async {
    await _repository.createSupplierAssessment(request);
    await refresh();
  }

  /// Update supplier assessment
  Future<void> updateAssessment(String id, UpdateSupplierAssessmentRequest request) async {
    await _repository.updateSupplierAssessment(id, request);
    await refresh();
  }

  /// Delete supplier assessment
  Future<void> deleteAssessment(String id) async {
    await _repository.deleteSupplierAssessment(id);
    await refresh();
  }

  /// Verify assessment (warehouse/logistik)
  Future<void> verifyAssessment(String id, {String? notes}) async {
    await _repository.verifySupplierAssessment(id, notes: notes);
    await refresh();
  }

  /// Approve assessment (admin)
  Future<void> approveAssessment(String id, {String? notes}) async {
    await _repository.approveSupplierAssessment(id, notes: notes);
    await refresh();
  }

  /// Reject assessment
  Future<void> rejectAssessment(String id, String reason) async {
    await _repository.rejectSupplierAssessment(id, reason);
    await refresh();
  }
}

/// Supplier Assessment State Provider
final supplierAssessmentNotifierProvider =
    StateNotifierProvider<SupplierAssessmentNotifier, AsyncValue<List<SupplierAssessmentModel>>>((ref) {
  final repository = ref.watch(supplierAssessmentRepositoryProvider);
  return SupplierAssessmentNotifier(repository);
});

/// Search Query Provider
final supplierAssessmentSearchQueryProvider = StateProvider <String>((ref) => '');

/// Status Filter Provider
final supplierAssessmentStatusFilterProvider = StateProvider<String?>((ref) => null);

/// Filtered Supplier Assessments Provider
final filteredSupplierAssessmentsProvider = Provider<AsyncValue<List<SupplierAssessmentModel>>>((ref) {
  final assessmentsAsync = ref.watch(supplierAssessmentNotifierProvider);
  final searchQuery = ref.watch(supplierAssessmentSearchQueryProvider);
  final statusFilter = ref.watch(supplierAssessmentStatusFilterProvider);

  return assessmentsAsync.whenData((assessments) {
    var filtered = assessments;

    // Apply search filter
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((assessment) {
        return assessment.supplierName.toLowerCase().contains(searchQuery.toLowerCase()) ||
            (assessment.contactName?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false) ||
            (assessment.email?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false);
      }).toList();
    }

    // Apply status filter
    if (statusFilter != null) {
      filtered = filtered.where((assessment) => assessment.status == statusFilter).toList();
    }

    return filtered;
  });
});