import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:erp_purchasing_apps/data/models/inventory_model.dart';

class InventoryRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get all inventory
  Future<List<InventoryModel>> getAllInventory() async {
    try {
      final response = await _supabase
          .from('inventory')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => InventoryModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load inventory: $e');
    }
  }

  // Get inventory by ID
  Future<InventoryModel?> getInventoryById(String id) async {
    try {
      final response =
          await _supabase.from('inventory').select().eq('id', id).maybeSingle();

      if (response == null) return null;
      return InventoryModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to load inventory: $e');
    }
  }

  // Create inventory from PO items (auto-create when PO received)
  Future<void> createInventoryFromPO(String poId, DateTime receivedDate) async {
    try {
      // Get PO items
      final poItemsResponse = await _supabase
          .from('purchase_order_item')
          .select()
          .eq('po_id', poId);

      if (poItemsResponse.isEmpty) return;

      // Create Inventory for each item
      final inventoryData = (poItemsResponse as List).map((item) {
        return {
          'po_item_id': item['id'],
          'item_name': item['item_name'],
          'quantity': item['quantity'],
          'unit': item['unit'] ?? 'pcs',
          'status': 'available',
          'received_date': receivedDate.toIso8601String(),
        };
      }).toList();

      await _supabase.from('inventory').insert(inventoryData);
    } catch (e) {
      throw Exception('Failed to create inventory from PO: $e');
    }
  }

  // Update inventory
  Future<InventoryModel> updateInventory({
    required String id,
    required String itemName,
    required int quantity,
    required String unit,
    String? location,
    required String status,
    String? notes,
  }) async {
    try {
      final data = {
        'item_name': itemName,
        'quantity': quantity,
        'unit': unit,
        'location': location,
        'status': status,
        'notes': notes,
      };

      final response = await _supabase
          .from('inventory')
          .update(data)
          .eq('id', id)
          .select()
          .single();

      return InventoryModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update inventory: $e');
    }
  }

  // Search inventory
  Future<List<InventoryModel>> searchInventory(String query) async {
    try {
      final response = await _supabase
          .from('inventory')
          .select()
          .or('item_name.ilike.%$query%,location.ilike.%$query%')
          .order('item_name', ascending: true);

      return (response as List)
          .map((json) => InventoryModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to search inventory: $e');
    }
  }

  // Get inventory by status
  Future<List<InventoryModel>> getInventoryByStatus(String status) async {
    try {
      final response = await _supabase
          .from('inventory')
          .select()
          .eq('status', status)
          .order('item_name', ascending: true);

      return (response as List)
          .map((json) => InventoryModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load inventory by status: $e');
    }
  }

  // Get low stock items (quatity < 10)
  Future<List<InventoryModel>> getLowStockItems() async {
    try {
      final response = await _supabase
          .from('inventory')
          .select()
          .eq('status', 'available')
          .order('quantity', ascending: true);

      return (response as List)
          .map((json) => InventoryModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load low stock items: $e');
    }
  }
}
