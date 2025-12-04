import 'package:erp_purchasing_apps/core/constants/api_constants.dart';
import 'package:erp_purchasing_apps/core/service/api_service.dart';
import 'package:erp_purchasing_apps/data/models/inventory_model.dart';

class InventoryRepository {
  final ApiService _apiService = ApiService();

  // Get all inventory
  Future<List<InventoryModel>> getAllInventory({
    String? productId,
    String? categoryId,
    String? status,
    String? location,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{};

      if (productId != null) queryParams['product_id'] = productId;
      if (categoryId != null) queryParams['category_id'] = categoryId;
      if (status != null && status != 'all') queryParams['status'] = status;
      if (location != null) queryParams['location'] = location;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await _apiService.get(
        ApiEndpoints.inventory,
        queryParameters: queryParams,
      );

      if (response.data == null) return [];

      final List<dynamic> dataList =
          response.data is List ? response.data as List : [response.data];

      return dataList
          .map((json) => InventoryModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load inventory: $e');
    }
  }

  // Get inventory by ID
  Future<InventoryModel?> getInventoryById(String id) async {
    try {
      final response = await _apiService.get(ApiEndpoints.inventoryById(id));
      if (response.data == null) return null;
      return InventoryModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to load inventory: $e');
    }
  }

  // Create inventory
  Future<InventoryModel> createInventory({
    required String productId,
    required int quantity,
    String? location,
    DateTime? receivedDate,
    String? notes,
  }) async {
    try {
      final body = {
        'product_id': productId,
        'quantity': quantity,
        if (location != null) 'location': location,
        if (receivedDate != null)
          'received_date': receivedDate.toIso8601String(),
        if (notes != null) 'notes': notes,
      };

      final response =
          await _apiService.post(ApiEndpoints.inventory, body: body);
      return InventoryModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create inventory: $e');
    }
  }

  // Update inventory
  Future<InventoryModel> updateInventory({
    required String id,
    required int quantity,
    String? location,
    required String status,
    String? notes,
  }) async {
    try {
      final body = {
        'quantity': quantity,
        'location': location,
        'status': status,
        'notes': notes,
      };

      final response =
          await _apiService.put(ApiEndpoints.inventoryById(id), body: body);
      return InventoryModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update inventory: $e');
    }
  }

  // // Search inventory
  // Future<List<InventoryModel>> searchInventory(String query) async {
  //   try {
  //     final response = await _supabase
  //         .from('inventory')
  //         .select()
  //         .or('item_name.ilike.%$query%,location.ilike.%$query%')
  //         .order('item_name', ascending: true);

  //     return (response as List)
  //         .map((json) => InventoryModel.fromJson(json))
  //         .toList();
  //   } catch (e) {
  //     throw Exception('Failed to search inventory: $e');
  //   }
  // }

  // ADJUST INVENTORY
  Future<InventoryModel> adjustInventory({
    required String id,
    required int quantity,
    required String reason,
    String? notes,
  }) async {
    try {
      final body = {
        'quantity': quantity,
        'reason': reason,
        if (notes != null) 'notes': notes,
      };

      final response = await _apiService.post(
        ApiEndpoints.adjustInventory(id),
        body: body,
      );
      return InventoryModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to adjust inventory: $e');
    }
  }

  // DELETE INVENTORY
  Future<void> deleteInventory(String id) async {
    try {
      await _apiService.delete(ApiEndpoints.inventoryById(id));
    } catch (e) {
      throw Exception('Failed to delete inventory: $e');
    }
  }

  // GET TRANSACTION HISTORY
  Future<List<InventoryTransactionModel>> getTransactionHistory(
      String inventoryId) async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.inventoryTransactions(inventoryId),
      );

      if (response.data == null) return [];

      final List<dynamic> dataList =
          response.data is List ? response.data as List : [response.data];

      return dataList
          .map((json) =>
              InventoryTransactionModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load transaction history: $e');
    }
  }

  // HELPER: LOW STOCK
  Future<List<InventoryModel>> getLowStockItems() async {
    try {
      final allItems = await getAllInventory(status: 'available');
      return allItems.where((item) => item.quantity < 10).toList();
    } catch (e) {
      throw Exception('Failed to load low stock items: $e');
    }
  }

  // LEGACY: Stock Out
  Future<InventoryModel> stockOut({
    required String id,
    required int quantityOut,
    required String reason,
  }) async {
    return adjustInventory(
        id: id, quantity: -quantityOut, reason: 'Stock Out: $reason');
  }

  // LEGACY: Stock Adjustment
  Future<InventoryModel> stockAdjustment({
    required String id,
    required int adjustmentQuantity,
    required String reason,
  }) async {
    return adjustInventory(
        id: id, quantity: adjustmentQuantity, reason: reason);
  }

  // LEGACY: Update Status
  Future<InventoryModel> updateStatus({
    required String id,
    required String status,
    String? reason,
  }) async {
    final current = await getInventoryById(id);
    if (current == null) throw Exception('Inventory not found');

    return updateInventory(
      id: id,
      quantity: current.quantity,
      location: current.location,
      status: status,
      notes: reason != null
          ? '${current.notes ?? ''}\n[STATUS CHANGE] ${current.status} → $status: $reason'
              .trim()
          : current.notes,
    );
  }

  /// Search inventory by Beacukai
  Future<List<InventoryModel>> searchByBeacukai({
    String? beacukaiNo,
    String? beacukaiNoAju,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};

      if (beacukaiNo != null) queryParams['beacukai_no'] = beacukaiNo;
      if (beacukaiNoAju != null) queryParams['beacukai_no_aju'] = beacukaiNoAju;
      if (fromDate != null) {
        queryParams['beacukai_from'] = fromDate.toIso8601String().split('T')[0];
      }
      if (toDate != null) {
        queryParams['beacukai_to'] = toDate.toIso8601String().split('T')[0];
      }

      final response = await _apiService.get(
        ApiEndpoints.inventory,
        queryParameters: queryParams,
      );

      if (response.data == null) return [];

      final List<dynamic> dataList =
          response.data is List ? response.data as List : [response.data];

      return dataList
          .map((json) => InventoryModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to search inventory by beacukai: $e');
    }
  }
}
