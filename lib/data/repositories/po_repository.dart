import 'package:erp_purchasing_apps/data/repositories/inventory_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:erp_purchasing_apps/data/models/purchase_order_model.dart';

class PoRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get all POs
  Future<List<PurchaseOrderModel>> getAllPOs() async {
    try {
      final response = await _supabase.from('purchase_order').select('''
          *,
          suppliers!purchase_order_supplier_id_fkey(name)
        ''').order('created_at', ascending: false);

      return (response as List).map((json) {
        // ✅ Extract supplier name dari joined data
        final supplierData = json['suppliers'];
        final Map<String, dynamic> poData = Map.from(json);
        poData.remove('suppliers'); // Remove nested object

        // ✅ Add supplier_name ke root level
        if (supplierData != null) {
          poData['supplier_name'] = supplierData['name'];
        }

        return PurchaseOrderModel.fromJson(poData);
      }).toList();
    } catch (e) {
      throw Exception('Failed to load POs: $e');
    }
  }

  // get PO by ID
  Future<PurchaseOrderModel?> getPOById(String id) async {
    try {
      final response = await _supabase
          .from('purchase_order')
          .select('*, purchase_order_item(*)')
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return PurchaseOrderModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to load PO: $e');
    }
  }

  // Generate PO Number
  Future<String> generatePONumber() async {
    try {
      final response = await _supabase.rpc('generate_po_number');
      return response as String;
    } catch (e) {
      final now = DateTime.now();
      // Ambil data + hitung total baris dari tabel purchase_order
      final res = await _supabase
          .from('purchase_order')
          .select('id')
          .count(CountOption.exact);

      final count = res.count;
      return 'PO-${now.year}${now.month.toString().padLeft(2, '0')}-${(count + 1).toString().padLeft(4, '0')}';
    }
  }

  // create PO with items
  Future<PurchaseOrderModel> createPO({
    required String createdBy,
    String? prId,
    required String supplierId,
    required List<Map<String, dynamic>> items,
    DateTime? expectedDeliveryDate,
    String? notes,
  }) async {
    try {
      // Generate PO number
      final poNumber = await generatePONumber();

      // Calculate total
      double totalAmount = 0;
      for (var item in items) {
        totalAmount +=
            (item['quantity'] as int) * (item['unit_price'] as double);
      }

      // Insert PO
      final poResponse = await _supabase
          .from('purchase_order')
          .insert({
            'po_number': poNumber,
            'pr_id': prId,
            'supplier_id': supplierId,
            'order_date': DateTime.now().toIso8601String(),
            'expected_delivery_date': expectedDeliveryDate?.toIso8601String(),
            'total_amount': totalAmount,
            'status': 'pending',
            'created_by': createdBy,
            'notes': notes
          })
          .select()
          .single();

      final poId = poResponse['id'];

      // Insert PO Items
      final itemsData = items.map((item) {
        return {
          'po_id': poId,
          'item_name': item['item_name'],
          'quantity': item['quantity'],
          'unit': item['unit'] ?? 'pcs',
          'unit_price': item['unit_price'],
        };
      }).toList();

      await _supabase.from('purchase_order_item').insert(itemsData);

      // Get complete PO with items
      final po = await getPOById(poId);
      return po!;
    } catch (e) {
      throw Exception('Failed to create PO: $e');
    }
  }

  // Update PO (only pending)
  Future<PurchaseOrderModel> updatePO({
    required String id,
    required String supplierId,
    required List<Map<String, dynamic>> items,
    DateTime? expectedDeliveryDate,
    String? notes,
  }) async {
    try {
      // Calculate total
      double totalAmount = 0;
      for (var item in items) {
        totalAmount +=
            (item['quantity'] as int) * (item['unit_price'] as double);
      }

      // Update PO
      await _supabase.from('purchase_order').update({
        'supplier_id': supplierId,
        'expected_delivery_date': expectedDeliveryDate?.toIso8601String(),
        'total_amount': totalAmount,
        'notes': notes,
      }).eq('id', id);

      // Delete old items
      await _supabase.from('puchase_order_item').delete().eq('po_id', id);

      // Insert new items
      final itemsData = items.map((item) {
        return {
          'po_id': id,
          'item_name': item['item_name'],
          'quantity': item['quantity'],
          'unit': item['unit'] ?? 'pcs',
          'unit_price': item['unit_price'],
        };
      }).toList();

      await _supabase.from('purchase_order_item').insert(itemsData);

      // Get updated PO
      final po = await getPOById(id);
      return po!;
    } catch (e) {
      throw Exception('Failed to update PO: $e');
    }
  }

  // approve PO
  Future<void> approvePO(String id) async {
    try {
      await _supabase
          .from('purchase_order')
          .update({'status': 'approved'}).eq('id', id);
    } catch (e) {
      throw Exception('Failed to approve PO: $e');
    }
  }

  // Mark PO as received
  Future<void> receivePO(String id, DateTime receivedDate) async {
    try {
      // Update PO status
      await _supabase.from('purchase_order').update({
        'status': 'received',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', id);

      // Auto-create inventory from PO items
      final inventoryRepo = InventoryRepository();
      await inventoryRepo.createInventoryFromPO(id, receivedDate);
    } catch (e) {
      throw Exception('Failed to mark PO as received: $e');
    }
  }

  // cancel po
  Future<void> cancelPO(String id) async {
    try {
      await _supabase
          .from('purchase_order')
          .update({'status': 'cancelled'}).eq('id', id);
    } catch (e) {
      throw Exception('Failed to cancel PO: $e');
    }
  }

  // Delete PO (only pending)
  Future<void> deletePO(String id) async {
    try {
      await _supabase.from('purchase_order').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete PO: $e');
    }
  }

  // Get POs for supplier (untuk supplier portal)
  Future<List<PurchaseOrderModel>> getPOsBySupplier(String supplierId) async {
    try {
      final response = await _supabase
          .from('purchase_order')
          .select('''
            *,
            purchase_order_item(*),
            suppliers!purchase_order_supplier_id_fkey(name)
          ''')
          .eq('supplier_id', supplierId)
          .inFilter('status', ['approved', 'received'])
          .order('created_at', ascending: false);

      return (response as List).map((json) {
        final supplierData = json['suppliers'];
        final Map<String, dynamic> poData = Map.from(json);
        poData.remove('suppliers');

        if (supplierData != null) {
          poData['supplier_name'] = supplierData['name'];
        }

        return PurchaseOrderModel.fromJson(poData);
      }).toList();
    } catch (e) {
      throw Exception('Failed to load supplier POs: $e');
    }
  }

  Future<Map<String, dynamic>> getPOShipmentSummary(String poId) async {
    try {
      // Get PO items
      final poItemsResponse = await _supabase
          .from('purchase_order_item')
          .select()
          .eq('po_id', poId);

      // Get all shipment items for this PO
      final shipmentItemResponse = await _supabase
          .from('shipment_item')
          .select('*, shipment!inner(po_id, status)')
          .eq('shipment.po_id', poId);

      Map<String, int> totalShipped = {};
      Map<String, int> totalOrdered = {};

      for (var poItem in poItemsResponse) {
        final poItemId = poItem['id'];
        totalOrdered[poItemId] = poItem['quantity'];
        totalShipped[poItemId] = 0;
      }

      for (var shipmentItem in shipmentItemResponse) {
        final poItemId = shipmentItem['po_item_id'];
        totalShipped[poItemId] = (totalShipped[poItemId] ?? 0) +
            (shipmentItem['quantity_shipped'] as int);
      }

      int totalOrderedQty =
          totalOrdered.values.fold(0, (sum, qty) => sum + qty);
      int totalShippedQty =
          totalShipped.values.fold(0, (sum, qty) => sum + qty);

      return {
        'total_ordered': totalOrderedQty,
        'total_shipped': totalShippedQty,
        'percentage': totalOrderedQty > 0
            ? (totalShippedQty / totalOrderedQty * 100).toStringAsFixed(1)
            : '0',
        'is_fully_shipped': totalShippedQty >= totalOrderedQty,
        'items_detail': totalOrdered.keys.map((POItemId) {
          return {
            'po_item_id': POItemId,
            'ordered': totalOrdered[POItemId],
            'shipped': totalShipped[POItemId],
          };
        }).toList(),
      };
    } catch (e) {
      throw Exception('Failed to get shipment summary: $e');
    }
  }

  // Check if PO has any shipments
  Future<bool> hasShipments(String poId) async {
    try {
      final response = await _supabase
          .from('shipment')
          .select('id')
          .eq('po_id', poId)
          .limit(1);

      return (response as List).isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Get POs yang bisa dibuat shipment (approved dan belum fully shipped)
  Future<List<PurchaseOrderModel>> getShippablePOs(String supplierId) async {
    try {
      final allPOs = await getPOsBySupplier(supplierId);
      List<PurchaseOrderModel> shippablePOs = [];

      for (var po in allPOs) {
        if (po.status == 'approved') {
          final summary = await getPOShipmentSummary(po.id);
          if (!(summary['is_fully_shipped'] as bool)) {
            shippablePOs.add(po);
          }
        }
      }

      return shippablePOs;
    } catch (e) {
      throw Exception('Failed to load shippable POs: $e');
    }
  }
}
