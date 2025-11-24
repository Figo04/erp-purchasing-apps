import 'package:erp_purchasing_apps/data/models/asset_model.dart';
import 'package:erp_purchasing_apps/core/constants/api_constants.dart';
import 'package:erp_purchasing_apps/core/service/api_service.dart';

class AssetRepository {
  final ApiService _apiService = ApiService();

  // GET ALL ASSETS
  Future<List<AssetModel>> getAllAssets({
    String? productId,
    String? categoryId,
    String? assetCategory,
    String? status,
    String? assignedTo,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{};

      if (productId != null) queryParams['product_id'] = productId;
      if (categoryId != null) queryParams['category_id'] = categoryId;
      if (assetCategory != null && assetCategory != 'all') {
        queryParams['asset_category'] = assetCategory;
      }
      if (status != null && status != 'all') queryParams['status'] = status;
      if (assignedTo != null) queryParams['assigned_to'] = assignedTo;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await _apiService.get(
        ApiEndpoints.assets,
        queryParameters: queryParams,
      );

      if (response.data == null) return [];

      final List<dynamic> dataList =
          response.data is List ? response.data as List : [response.data];

      return dataList
          .map((json) => AssetModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load assets: $e');
    }
  }

  // GET ASSET BY ID
  Future<AssetModel?> getAssetById(String id) async {
    try {
      final response = await _apiService.get(ApiEndpoints.assetById(id));
      if (response.data == null) return null;
      return AssetModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to load asset: $e');
    }
  }

  // Create new asset
  Future<AssetModel> createAsset({
    required String assetCode,
    String? productId,
    required String name,
    required String assetCategory,
    required int quantity,
    double? purchasePrice,
    String? notes,
  }) async {
    try {
      final body = {
        'asset_code': assetCode,
        if (productId != null) 'product_id': productId,
        'name': name,
        'asset_category': assetCategory,
        'quantity': quantity,
        if (purchasePrice != null) 'purchase_price': purchasePrice,
        if (notes != null) 'notes': notes,
      };

      final response = await _apiService.post(ApiEndpoints.assets, body: body);
      return AssetModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create asset: $e');
    }
  }

  // UPDATE ASSET
  Future<AssetModel> updateAsset({
    required String id,
    required String name,
    required String assetCategory,
    required String status,
    required int quantity,
    double? purchasePrice,
    String? notes,
  }) async {
    try {
      final body = {
        'name': name,
        'asset_category': assetCategory,
        'status': status,
        'quantity': quantity,
        'purchase_price': purchasePrice,
        'notes': notes,
      };

      final response =
          await _apiService.put(ApiEndpoints.assetById(id), body: body);
      return AssetModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update asset: $e');
    }
  }

  // ASSIGN ASSET TO USER
  Future<AssetModel> assignAsset({
    required String id,
    required String assignedTo,
    String? notes,
  }) async {
    try {
      final body = {
        'assigned_to': assignedTo,
        if (notes != null) 'notes': notes,
      };

      final response = await _apiService.post(
        ApiEndpoints.assignAsset(id),
        body: body,
      );
      return AssetModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to assign asset: $e');
    }
  }

  // UNASSIGN ASSET (Return)
  Future<AssetModel> unassignAsset({
    required String id,
    String? returnNotes,
  }) async {
    try {
      final current = await getAssetById(id);
      if (current == null) throw Exception('Asset not found');

      final body = {
        'name': current.name,
        'asset_category': current.assetCategory,
        'status': 'available',
        'quantity': current.quantity,
        'purchase_price': current.purchasePrice,
        'notes': returnNotes != null
            ? '${current.notes ?? ''}\n[RETURNED] ${DateTime.now()}: $returnNotes'
                .trim()
            : current.notes,
      };

      final response =
          await _apiService.put(ApiEndpoints.assetById(id), body: body);
      return AssetModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to return asset: $e');
    }
  }

  // DELETE ASSET
  Future<void> deleteAsset(String id) async {
    try {
      await _apiService.delete(ApiEndpoints.assetById(id));
    } catch (e) {
      throw Exception('Failed to delete asset: $e');
    }
  }

  // GET TRANSACTION HISTORY
  Future<List<AssetTransactionModel>> getTransactionHistory(
      String assetId) async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.assetTransactions(assetId),
      );

      if (response.data == null) return [];

      final List<dynamic> dataList =
          response.data is List ? response.data as List : [response.data];

      return dataList
          .map((json) =>
              AssetTransactionModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load transaction history: $e');
    }
  }

  // HELPER: GET BY CATEGORY
  Future<List<AssetModel>> getAssetsByCategory(String category) async {
    return await getAllAssets(assetCategory: category);
  }

  // HELPER: GET BY STATUS
  Future<List<AssetModel>> getAssetsByStatus(String status) async {
    return await getAllAssets(status: status);
  }

  // HELPER: GET MY ASSIGNED ASSETS
  Future<List<AssetModel>> getMyAssignedAssets(String userId) async {
    return await getAllAssets(assignedTo: userId);
  }

  // HELPER: SEARCH ASSETS
  Future<List<AssetModel>> searchAssets(String query) async {
    return await getAllAssets(search: query);
  }

  // HELPER: DECREASE QUANTITY (Consumable only)
  Future<AssetModel> decreaseQuantity({
    required String id,
    required int quantity,
    required String reason,
  }) async {
    try {
      final current = await getAssetById(id);
      if (current == null) throw Exception('Asset not found');

      if (current.assetCategory != 'consumable') {
        throw Exception('Only consumable assets can decrease quantity');
      }

      if (quantity > current.quantity) {
        throw Exception('Quantity exceeds available stock');
      }

      final newQuantity = current.quantity - quantity;
      final notes =
          '${current.notes ?? ''}\n[CONSUMED] -$quantity: $reason'.trim();

      return await updateAsset(
        id: id,
        name: current.name,
        assetCategory: current.assetCategory,
        status: current.status,
        quantity: newQuantity,
        purchasePrice: current.purchasePrice,
        notes: notes,
      );
    } catch (e) {
      throw Exception('Failed to decrease quantity: $e');
    }
  }

  // HELPER: UPDATE STATUS ONLY
  Future<AssetModel> updateStatus({
    required String id,
    required String status,
    String? reason,
  }) async {
    try {
      final current = await getAssetById(id);
      if (current == null) throw Exception('Asset not found');

      final notes = reason != null
          ? '${current.notes ?? ''}\n[STATUS CHANGE] ${current.status} → $status: $reason'
              .trim()
          : current.notes;

      return await updateAsset(
        id: id,
        name: current.name,
        assetCategory: current.assetCategory,
        status: status,
        quantity: current.quantity,
        purchasePrice: current.purchasePrice,
        notes: notes,
      );
    } catch (e) {
      throw Exception('Failed to update status: $e');
    }
  }
}
