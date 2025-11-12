import 'package:erp_purchasing_apps/data/models/category_model.dart';
import 'package:erp_purchasing_apps/core/service/api_service.dart';
import 'package:erp_purchasing_apps/core/constants/api_constants.dart';

/// Category Repository
/// Handles category CRUD operations
class CategoryRepository {
  final ApiService _apiService;

  CategoryRepository({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  /// Get all categories (flat list)
  Future<List<CategoryModel>> getAllCategories({
    String? search,
    bool? isActive,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (isActive != null) {
        queryParams['is_active'] = isActive.toString();
      }

      final response = await _apiService.get(
        ApiEndpoints.categories,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
        fromJson: (json) {
          if (json is List) {
            return json.map((item) => CategoryModel.fromJson(item)).toList();
          }
          return <CategoryModel>[];
        },
      );

      if (!response.isSuccess || response.data == null) {
        throw Exception(response.errorMessage);
      }

      return response.data as List<CategoryModel>;
    } catch (e) {
      throw Exception('Failed to load categories: $e');
    }
  }

  /// Get category tree (hierarchical structure)
  Future<List<CategoryModel>> getCategoryTree() async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.categoryTree,
        fromJson: (json) {
          if (json is List) {
            return json.map((item) => CategoryModel.fromJson(item)).toList();
          }
          return <CategoryModel>[];
        },
      );

      if (!response.isSuccess || response.data == null) {
        throw Exception(response.errorMessage);
      }

      return response.data as List<CategoryModel>;
    } catch (e) {
      throw Exception('Failed to load category tree: $e');
    }
  }

  /// Get category by ID
  Future<CategoryModel> getCategoryById(String id) async {
    try {
      final response = await _apiService.get<CategoryModel>(
        ApiEndpoints.categoryById(id),
        fromJson: (json) => CategoryModel.fromJson(json),
      );

      if (!response.isSuccess || response.data == null) {
        throw Exception(response.errorMessage);
      }

      return response.data!;
    } catch (e) {
      throw Exception('Failed to load category: $e');
    }
  }

  /// Create new category
  Future<CategoryModel> createCategory(CreateCategoryRequest request) async {
    try {
      final response = await _apiService.post<CategoryModel>(
        ApiEndpoints.categories,
        body: request.toJson(),
        fromJson: (json) => CategoryModel.fromJson(json),
      );

      if (!response.isSuccess || response.data == null) {
        throw Exception(response.errorMessage);
      }

      return response.data!;
    } catch (e) {
      throw Exception('Failed to create category: $e');
    }
  }

  /// Update category
  Future<CategoryModel> updateCategory(
    String id,
    UpdateCategoryRequest request,
  ) async {
    try {
      final response = await _apiService.put<CategoryModel>(
        ApiEndpoints.categoryById(id),
        body: request.toJson(),
        fromJson: (json) => CategoryModel.fromJson(json),
      );

      if (!response.isSuccess || response.data == null) {
        throw Exception(response.errorMessage);
      }

      return response.data!;
    } catch (e) {
      throw Exception('Failed to update category: $e');
    }
  }

  /// Delete category
  Future<void> deleteCategory(String id) async {
    try {
      final response = await _apiService.delete(
        ApiEndpoints.categoryById(id),
      );

      if (!response.isSuccess) {
        throw Exception(response.errorMessage);
      }
    } catch (e) {
      throw Exception('Failed to delete category: $e');
    }
  }

  /// Get root categories only
  Future<List<CategoryModel>> getRootCategories() async {
    try {
      final allCategories = await getAllCategories(isActive: true);
      return allCategories.where((cat) => cat.isRoot).toList();
    } catch (e) {
      throw Exception('Failed to load root categories: $e');
    }
  }

  /// Get children of specific category
  Future<List<CategoryModel>> getChildCategories(String parentId) async {
    try {
      final allCategories = await getAllCategories(isActive: true);
      return allCategories.where((cat) => cat.parentId == parentId).toList();
    } catch (e) {
      throw Exception('Failed to load child categories: $e');
    }
  }
}