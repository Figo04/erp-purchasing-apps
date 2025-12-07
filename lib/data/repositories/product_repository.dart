import 'package:erp_purchasing_apps/core/service/api_service.dart';
import 'package:erp_purchasing_apps/data/models/product_model.dart';
import 'package:erp_purchasing_apps/core/api/api_response.dart';
import 'package:erp_purchasing_apps/core/constants/api_constants.dart';

/// Product Repository
/// Handles product CRUD operations
class ProductRepository {
  final ApiService _apiService;

  ProductRepository({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  /// Get all products
  Future<List<ProductModel>> getAllProducts({
    String? search,
    String? categoryId,
    String? supplierId,    // ✅ NEW: Filter by supplier
    bool? isActive,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (categoryId != null) {
        queryParams['category_id'] = categoryId;
      }
      // ✅ NEW: Add supplier filter
      if (supplierId != null) {
        queryParams['supplier_id'] = supplierId;
      }
      if (isActive != null) {
        queryParams['is_active'] = isActive.toString();
      }

      final response = await _apiService.get(ApiEndpoints.products,
          queryParameters: queryParams.isNotEmpty ? queryParams : null,
          fromJson: (json) {
        if (json is List) {
          return json.map((item) => ProductModel.fromJson(item)).toList();
        }
        return <ProductModel>[];
      });

      if (!response.isSuccess || response.data == null) {
        throw Exception(response.errorMessage);
      }

      return response.data as List<ProductModel>;
    } catch (e) {
      throw Exception('Failed to load products: $e');
    }
  }

  /// Get product by ID
  Future<ProductModel> getProductById(String id) async {
    try {
      final response = await _apiService.get<ProductModel>(
        ApiEndpoints.productById(id),
        fromJson: (json) => ProductModel.fromJson(json),
      );

      if (!response.isSuccess || response.data == null) {
        throw Exception(response.errorMessage);
      }

      return response.data!;
    } catch (e) {
      throw Exception('Failed to load product: $e');
    }
  }

  /// ✅ NEW: Get products by supplier
  Future<List<ProductModel>> getProductsBySupplier(String supplierId) async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.productsBySupplier(supplierId),
        fromJson: (json) {
          if (json is List) {
            return json.map((item) => ProductModel.fromJson(item)).toList();
          }
          return <ProductModel>[];
        },
      );

      if (!response.isSuccess || response.data == null) {
        throw Exception(response.errorMessage);
      }

      return response.data as List<ProductModel>;
    } catch (e) {
      throw Exception('Failed to load products by supplier: $e');
    }
  }

  /// Create new product
  Future<ProductModel> createProduct(CreateProductRequest request) async {
    try {
      final response = await _apiService.post<ProductModel>(
        ApiEndpoints.products,
        body: request.toJson(),
        fromJson: (json) => ProductModel.fromJson(json),
      );

      if (!response.isSuccess || response.data == null) {
        throw Exception(response.errorMessage);
      }

      return response.data!;
    } catch (e) {
      throw Exception('Failed to create product: $e');
    }
  }

  /// Update product
  Future<ProductModel> updateProduct(
    String id,
    UpdateProductRequest request,
  ) async {
    try {
      final response = await _apiService.put<ProductModel>(
        ApiEndpoints.productById(id),
        body: request.toJson(),
        fromJson: (json) => ProductModel.fromJson(json),
      );

      if (!response.isSuccess || response.data == null) {
        throw Exception(response.errorMessage);
      }

      return response.data!;
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  /// Delete product
  Future<void> deleteProduct(String id) async {
    try {
      final response = await _apiService.delete(
        ApiEndpoints.productById(id),
      );

      if (!response.isSuccess) {
        throw Exception(response.errorMessage);
      }
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }

  /// Get products by category
  Future<List<ProductModel>> getProductsByCategory(String categoryId) async {
    try {
      return await getAllProducts(categoryId: categoryId, isActive: true);
    } catch (e) {
      throw Exception('Failed to load products by category: $e');
    }
  }

  /// Search products
  Future<List<ProductModel>> searchProducts(String query) async {
    try {
      return await getAllProducts(search: query, isActive: true);
    } catch (e) {
      throw Exception('Failed to search products: $e');
    }
  }
}