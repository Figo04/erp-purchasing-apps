import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:erp_purchasing_apps/data/models/product_model.dart';
import 'package:erp_purchasing_apps/data/repositories/product_repository.dart';
import 'package:flutter_riverpod/legacy.dart';

// Product Repository Provider
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository();
});

// product List Provider
final productListProvider = FutureProvider<List<ProductModel>>((ref) async {
  final repo = ref.watch(productRepositoryProvider);
  return await repo.getAllProducts(isActive: true);
});

// Selected Product Provider
final selectedProductProvider = StateProvider<ProductModel?>((ref) => null);

// Product Search Query Provider
final productSearchQueryProvider = StateProvider<String>((ref) => '');

// Selected Category Filter Provider
final productCategoryFilterProvider = StateProvider<String?>((ref) => null);

/// Filtered Products Provider
final filteredProductsProvider =
    FutureProvider<List<ProductModel>>((ref) async {
  final repo = ref.watch(productRepositoryProvider);
  final searchQuery = ref.watch(productSearchQueryProvider);
  final categoryFilter = ref.watch(productCategoryFilterProvider);

  return await repo.getAllProducts(
    search: searchQuery.isEmpty ? null : searchQuery,
    categoryId: categoryFilter,
    isActive: true,
  );
});

// Product State Notifier (for CRUD operations)
class ProductNotifier extends StateNotifier<AsyncValue<List<ProductModel>>> {
  final ProductRepository _repository;
  final Ref ref;

  ProductNotifier(this.ref, this._repository)
      : super(const AsyncValue.loading()) {
    loadProducts();
  }

  /// Load all products
  Future<void> loadProducts() async {
    try {
      state = const AsyncValue.loading();
      final products = await _repository.getAllProducts(isActive: true);
      state = AsyncValue.data(products);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Create new product
  Future<void> createProduct(CreateProductRequest request) async {
    try {
      await _repository.createProduct(request);
      await loadProducts(); // Reload list
    } catch (e) {
      rethrow;
    }
  }

  /// Update product
  Future<void> updateProduct(String id, UpdateProductRequest request) async {
    try {
      await _repository.updateProduct(id, request);
      await loadProducts(); // Reload list
    } catch (e) {
      rethrow;
    }
  }

  // Delete product
  Future<void> deleteProduct(String id) async {
    try {
      await _repository.deleteProduct(id);
      await loadProducts();
    } catch (e) {
      rethrow;
    }
  }

  // Refresh products
  Future<void> refresh() async {
    await loadProducts();
  }

  // Load products by category

  Future<void> loadProductsByCategory(String categoryId) async {
    try {
      state = const AsyncValue.loading();
      final products = await _repository.getProductsByCategory(categoryId);
      state = AsyncValue.data(products);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  // Search products
  Future<void> searchProducts(String query) async {
    try {
      state = const AsyncValue.loading();
      final products = await _repository.searchProducts(query);
      state = AsyncValue.data(products);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

// Product State Notifier Provider
final productNotifierProvider =
    StateNotifierProvider<ProductNotifier, AsyncValue<List<ProductModel>>>(
        (ref) {
  final repository = ref.watch(productRepositoryProvider);
  return ProductNotifier(ref, repository);
});
