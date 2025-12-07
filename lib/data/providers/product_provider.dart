import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:erp_purchasing_apps/data/models/product_model.dart';
import 'package:erp_purchasing_apps/data/repositories/product_repository.dart';
import 'package:flutter_riverpod/legacy.dart';

// ============================================
// REPOSITORY PROVIDER
// ============================================

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository();
});

// ============================================
// FILTER STATE PROVIDERS
// ============================================

/// Product Search Query
final productSearchQueryProvider = StateProvider<String>((ref) => '');

/// Selected Category Filter
final productCategoryFilterProvider = StateProvider<String?>((ref) => null);

/// ✅ NEW: Selected Supplier Filter
final productSupplierFilterProvider = StateProvider<String?>((ref) => null);

/// Selected Product (for detail view)
final selectedProductProvider = StateProvider<ProductModel?>((ref) => null);

// ============================================
// MAIN PRODUCT NOTIFIER (AsyncNotifier)
// ============================================

class ProductNotifier extends AsyncNotifier<List<ProductModel>> {
  @override
  Future<List<ProductModel>> build() async {
    // Watch filters - auto rebuild when changed
    final searchQuery = ref.watch(productSearchQueryProvider);
    final categoryFilter = ref.watch(productCategoryFilterProvider);
    final supplierFilter = ref.watch(productSupplierFilterProvider); // ✅ NEW

    // Fetch with filters applied
    final repo = ref.read(productRepositoryProvider);
    final products = await repo.getAllProducts(
      search: searchQuery.isEmpty ? null : searchQuery,
      categoryId: categoryFilter,
      supplierId: supplierFilter, // ✅ NEW
      isActive: true,
    );

    return products;
  }

  /// Create new product
  Future<void> createProduct(CreateProductRequest request) async {
    final repo = ref.read(productRepositoryProvider);
    await repo.createProduct(request);
    ref.invalidateSelf(); // Trigger rebuild
  }

  /// Update product
  Future<void> updateProduct(String id, UpdateProductRequest request) async {
    final repo = ref.read(productRepositoryProvider);
    await repo.updateProduct(id, request);
    ref.invalidateSelf(); // Trigger rebuild
  }

  /// Delete product
  Future<void> deleteProduct(String id) async {
    final repo = ref.read(productRepositoryProvider);
    await repo.deleteProduct(id);
    ref.invalidateSelf(); // Trigger rebuild
  }

  /// Manual refresh
  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

// Product Notifier Provider
final productNotifierProvider =
    AsyncNotifierProvider<ProductNotifier, List<ProductModel>>(() {
  return ProductNotifier();
});

// ============================================
// ADDITIONAL PROVIDERS
// ============================================

/// Simple Product List (without filters)
final productListProvider =
    FutureProvider.autoDispose<List<ProductModel>>((ref) async {
  final repo = ref.read(productRepositoryProvider);
  final products = await repo.getAllProducts(isActive: true);
  return products;
});

/// ✅ NEW: Products by Supplier
final productsBySupplierProvider = FutureProvider.autoDispose
    .family<List<ProductModel>, String>((ref, supplierId) async {
  final repo = ref.read(productRepositoryProvider);
  return await repo.getProductsBySupplier(supplierId);
});

/// Filtered Products (alternative approach)
final filteredProductsProvider =
    FutureProvider.autoDispose<List<ProductModel>>((ref) async {
  final repo = ref.read(productRepositoryProvider);
  final searchQuery = ref.watch(productSearchQueryProvider);
  final categoryFilter = ref.watch(productCategoryFilterProvider);
  final supplierFilter = ref.watch(productSupplierFilterProvider); // ✅ NEW

  final products = await repo.getAllProducts(
    search: searchQuery.isEmpty ? null : searchQuery,
    categoryId: categoryFilter,
    supplierId: supplierFilter, // ✅ NEW
    isActive: true,
  );

  return products;
});
