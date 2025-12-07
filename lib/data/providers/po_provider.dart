import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:erp_purchasing_apps/data/models/purchase_order_model.dart';
import 'package:erp_purchasing_apps/data/repositories/po_repository.dart';
import 'package:flutter_riverpod/legacy.dart';

/// PO Repository Provider
final poRepositoryProvider = Provider<PurchaseOrderRepository>((ref) {
  return PurchaseOrderRepository();
});

/// PO List Provider
final poListProvider = FutureProvider<List<PurchaseOrderModel>>((ref) async {
  final repo = ref.watch(poRepositoryProvider);
  return await repo.getAllPOs();
});

/// Selected PO Provider
final selectedPOProvider = StateProvider<PurchaseOrderModel?>((ref) => null);

/// PO Search Query Provider
final poSearchQueryProvider = StateProvider<String>((ref) => '');

/// PO Status Filter Provider
final poStatusFilterProvider = StateProvider<String?>((ref) => null);

/// This is the CORRECT provider that matches backend logic
final prSupplierGroupingsProvider =
    FutureProvider<List<PRSupplierGroup>>((ref) async {
  final repo = ref.watch(poRepositoryProvider);
  return await repo.getPRGroupingsBySupplier();
});

/// Keep for backward compatibility but should not be used
@Deprecated('Use prSupplierGroupingsProvider instead')
final prCategoryGroupingsProvider =
    FutureProvider<List<PRCategoryGroup>>((ref) async {
  final repo = ref.watch(poRepositoryProvider);
  return await repo.getPRGroupingsByCategory();
});

/// ⚠️ DEPRECATED: Old PR Groupings Provider
@Deprecated('Use prSupplierGroupingsProvider instead')
final prGroupingsProvider = FutureProvider<List<dynamic>>((ref) async {
  final repo = ref.watch(poRepositoryProvider);
  return await repo.getPRGroupings();
});

/// Filtered POs Provider
final filteredPOsProvider =
    FutureProvider<List<PurchaseOrderModel>>((ref) async {
  final repo = ref.watch(poRepositoryProvider);
  final searchQuery = ref.watch(poSearchQueryProvider);
  final statusFilter = ref.watch(poStatusFilterProvider);

  return await repo.getAllPOs(
    search: searchQuery.isEmpty ? null : searchQuery,
    status: statusFilter,
  );
});

/// ============================================
/// PO STATE NOTIFIER (NO CHANGES)
/// ============================================

class PONotifier extends StateNotifier<AsyncValue<List<PurchaseOrderModel>>> {
  final PurchaseOrderRepository _repository;
  final Ref ref;

  PONotifier(this.ref, this._repository) : super(const AsyncValue.loading()) {
    loadPOs();
  }

  /// Load all POs
  Future<void> loadPOs() async {
    try {
      state = const AsyncValue.loading();
      final pos = await _repository.getAllPOs();
      state = AsyncValue.data(pos);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Create new PO
  Future<void> createPO(CreatePORequest request) async {
    try {
      await _repository.createPO(request);
      await loadPOs(); // Reload list
    } catch (e) {
      rethrow;
    }
  }

  /// Update PO
  Future<void> updatePO(String id, UpdatePORequest request) async {
    try {
      await _repository.updatePO(id, request);
      await loadPOs(); // Reload list
    } catch (e) {
      rethrow;
    }
  }

  /// Delete PO
  Future<void> deletePO(String id) async {
    try {
      await _repository.deletePO(id);
      await loadPOs(); // Reload list
    } catch (e) {
      rethrow;
    }
  }

  /// Approve PO
  Future<void> approvePO(String id) async {
    try {
      await _repository.approvePO(id);
      await loadPOs(); // Reload list
    } catch (e) {
      rethrow;
    }
  }

  /// Cancel PO
  Future<void> cancelPO(String id) async {
    try {
      await _repository.cancelPO(id);
      await loadPOs(); // Reload list
    } catch (e) {
      rethrow;
    }
  }

  /// Refresh POs
  Future<void> refresh() async {
    await loadPOs();
  }

  /// Load POs by status
  Future<void> loadPOsByStatus(String status) async {
    try {
      state = const AsyncValue.loading();
      final pos = await _repository.getAllPOs(status: status);
      state = AsyncValue.data(pos);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

/// PO State Notifier Provider
final poNotifierProvider =
    StateNotifierProvider<PONotifier, AsyncValue<List<PurchaseOrderModel>>>(
        (ref) {
  final repository = ref.watch(poRepositoryProvider);
  return PONotifier(ref, repository);
});