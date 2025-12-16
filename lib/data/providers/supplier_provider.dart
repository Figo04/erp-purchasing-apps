import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:erp_purchasing_apps/data/models/supplier_model.dart';
import 'package:erp_purchasing_apps/data/repositories/supplier_repository.dart';
import 'package:flutter_riverpod/legacy.dart';

final supplierRepositoryProvider = Provider<SupplierRepository>((ref) {
  return SupplierRepository();
});

final supplierListProvider = FutureProvider<List<SupplierModel>>((ref) async {
  final repo = ref.watch(supplierRepositoryProvider);
  return await repo.getAllSuppliers(isActive: true);
});

// Selected Supplier Provider
final selectedSupplierProvider = StateProvider<SupplierModel?>((ref) => null);

// Supplier Search Query Provider
final supplierSearchQueryProvider = StateProvider<String>((ref) => '');

// Active/Inactive Filter State
final supplierActiveFilterProvider = StateProvider<bool?>((ref) => true);

// Filterd Suppliers Provider
final filteredSuppliersProvider =
    FutureProvider<List<SupplierModel>>((ref) async {
  final repo = ref.watch(supplierRepositoryProvider);
  final searchQuery = ref.watch(supplierSearchQueryProvider);
  final activeFilter = ref.watch(supplierActiveFilterProvider);

  return await repo.getAllSuppliers(
    search: searchQuery.isEmpty ? null : searchQuery,
    isActive: activeFilter,
  );
});

// Supplier State Notifier (for CRUD operations)
class SupplierNotifier extends StateNotifier<AsyncValue<List<SupplierModel>>> {
  final SupplierRepository _repository;
  final Ref ref;

  SupplierNotifier(this.ref, this._repository)
      : super(const AsyncValue.loading()) {
    loadSuppliers();
  }

  /// Load all suppliers
  Future<void> loadSuppliers() async {
    try {
      state = const AsyncValue.loading();

      // READ filters from providers
      final searchQuery = ref.read(supplierSearchQueryProvider);
      final activeFilter = ref.read(supplierActiveFilterProvider);

      final suppliers = await _repository.getAllSuppliers(
        search: searchQuery.isEmpty ? null : searchQuery,
        isActive: activeFilter, 
      );

      state = AsyncValue.data(suppliers);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Create new supplier
  Future<void> createSupplier(CreateSupplierRequest request) async {
    try {
      await _repository.createSupplier(request);
      await loadSuppliers(); // Reload list
    } catch (e) {
      rethrow;
    }
  }

  // Update supplier
  Future<void> updateSupplier(String id, UpdateSupplierRequest request) async {
    try {
      await _repository.updatedSupplier(id, request);
      await loadSuppliers();
    } catch (e) {
      rethrow;
    }
  }

  // Delete supplier
  Future<void> deleteSupplier(String id) async {
    try {
      await _repository.deleteSupplier(id);
      await loadSuppliers();
    } catch (e) {
      rethrow;
    }
  }

  // Refresh suppliers
  Future<void> refresh() async {
    await loadSuppliers();
  }

  // Search suppliers
  Future<void> searchSuppliers(String query) async {
    try {
      state = const AsyncValue.loading();

      // ✅ Also read active filter when searching
      final activeFilter = ref.read(supplierActiveFilterProvider);

      final suppliers = await _repository.getAllSuppliers(
        search: query.isEmpty ? null : query,
        isActive: activeFilter, 
      );

      state = AsyncValue.data(suppliers);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

/// Supplier State Notifier Provider
final supplierNotifierProvider =
    StateNotifierProvider<SupplierNotifier, AsyncValue<List<SupplierModel>>>(
        (ref) {
  final repository = ref.watch(supplierRepositoryProvider);
  return SupplierNotifier(ref, repository);
});

// final activeSupplierListProvider =
//     FutureProvider<List<SupplierModel>>((ref) async {
//   final repo = ref.watch(supplierRepositoryProvider);
//   return await repo.getActiveSuppliers();
// });
