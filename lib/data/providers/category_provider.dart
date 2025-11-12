import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:erp_purchasing_apps/data/models/category_model.dart';
import 'package:erp_purchasing_apps/data/repositories/category_repository.dart';
import 'package:flutter_riverpod/legacy.dart';

// Category Repository Provider
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository();
});

/// Category List Provider (flat list)
final categoryListProvider = FutureProvider<List<CategoryModel>>((ref) async {
  final repo = ref.watch(categoryRepositoryProvider);
  return await repo.getAllCategories(isActive: true);
});

/// Category Tree Provider (hierarchical structure)
final categoryTreeProvider = FutureProvider<List<CategoryModel>>((ref) async {
  final repo = ref.watch(categoryRepositoryProvider);
  return await repo.getCategoryTree();
});

// Root Categories Provider
final rootCategoriesProvider = FutureProvider<List<CategoryModel>>((ref) async {
  final repo = ref.watch(categoryRepositoryProvider);
  return await repo.getRootCategories();
});

// Selected Category Provider
final selectedCategoryProvider = StateProvider<CategoryModel?>((ref) => null);

// Category Search Query Provider
final categorySearchQueryProvider = StateProvider<String>((ref) => '');

// Filtered Categories Provider
final filteredCategoriesProvider =
    FutureProvider<List<CategoryModel>>((ref) async {
  final repo = ref.watch(categoryRepositoryProvider);
  final searchQuery = ref.watch(categorySearchQueryProvider);

  return await repo.getAllCategories(
    search: searchQuery.isEmpty ? null : searchQuery,
    isActive: true,
  );
});

/// Category State Notifier (for CRUD operations)
class CategoryNotifier extends StateNotifier<AsyncValue<List<CategoryModel>>> {
  final CategoryRepository _repository;
  final Ref ref;

  CategoryNotifier(this.ref, this._repository)
      : super(const AsyncValue.loading()) {
    loadCategories();
  }

  /// Load all categories
  Future<void> loadCategories() async {
    try {
      state = const AsyncValue.loading();
      final categories = await _repository.getAllCategories(isActive: true);
      state = AsyncValue.data(categories);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Create new category
  Future<void> createCategory(CreateCategoryRequest request) async {
    try {
      await _repository.createCategory(request);
      await loadCategories(); // Reload list
    } catch (e) {
      rethrow;
    }
  }

  /// Update category
  Future<void> updateCategory(String id, UpdateCategoryRequest request) async {
    try {
      await _repository.updateCategory(id, request);
      await loadCategories(); // Reload list
    } catch (e) {
      rethrow;
    }
  }

  /// Delete category
  Future<void> deleteCategory(String id) async {
    try {
      await _repository.deleteCategory(id);
      await loadCategories(); // Reload list
    } catch (e) {
      rethrow;
    }
  }

  /// Refresh categories
  Future<void> refresh() async {
    await loadCategories();
  }
}

// Category State Notifier Provider
final categoryNotifierProvider =
    StateNotifierProvider<CategoryNotifier, AsyncValue<List<CategoryModel>>>(
        (ref) {
  final repository = ref.watch(categoryRepositoryProvider);
  return CategoryNotifier(ref, repository);
});
