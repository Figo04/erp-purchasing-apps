import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:erp_purchasing_apps/data/models/goods_receipt_model.dart';

class GoodsReceiptRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get all receipts
  Future<List<GoodsReceiptModel>> getAllReceipts() async {
    try {
      final response = await _supabase.from('goods_receipt').select('''
            *,
            purchase_order!goods_receipt_po_id_fkey(po_number),
            users!goods_receipt_received_by_fkey(full_name)
          ''').order('created_at', ascending: false);

      return (response as List).map((json) {
        final poData = json['purchase_order'];
        final userData = json['users'];

        final Map<String, dynamic> receiptData = Map.from(json);
        receiptData.remove('purchase_order');
        receiptData.remove('users');

        if (poData != null) {
          receiptData['po_number'] = poData['po_number'];
        }
        if (userData != null) {
          receiptData['receiver_name'] = userData['full_name'];
        }

        return GoodsReceiptModel.fromJson(receiptData);
      }).toList();
    } catch (e) {
      throw Exception('Failed to load receipts: $e');
    }
  }

  // Get receipt by id with items
  Future<GoodsReceiptModel?> getReceiptById(String id) async {
    try {
      final response = await _supabase.from('goods_receipt').select('''
            *,
            goods_receipt_item(*),
            purchase_order!goods_receipt_po_id_fkey(po_number)
          ''').eq('id', id).maybeSingle();

      if (response == null) return null;

      final poData = response['purchase_order'];
      final Map<String, dynamic> receiptData = Map.from(response);
      receiptData.remove('purchase_order');

      if (poData != null) {
        receiptData['po_number'] = poData['po_number'];
      }

      return GoodsReceiptModel.fromJson(receiptData);
    } catch (e) {
      throw Exception('Failed to load receipt: $e');
    }
  }

  // Get receipts by PO ID
  Future<List<GoodsReceiptModel>> getReceiptsByPO(String poId) async {
    try {
      final response = await _supabase
          .from('goods_receipt')
          .select('*, goods_receipt_item(*)')
          .eq('po_id', poId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => GoodsReceiptModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load PO receipts: $e');
    }
  }

  // Get receiving summary for a PO (to check what's already received)
  Future<List<POItemReceiptSummary>> getPOReceiptSummary(String poId) async {
    try {
      // Get PO Items
      final poItemsResponse = await _supabase
          .from('purchase_order_item')
          .select()
          .eq('po_id', poId);

      // Get all receipt items for this PO
      final receiptItemsResponse = await _supabase
          .from('goods_receipt_item')
          .select('*, goods_receipt!inner(po_id)')
          .eq('goods_receipt.po_id', poId);

      List<POItemReceiptSummary> summries = [];

      for (var poItem in poItemsResponse) {
        final poItemId = poItem['id'];

        // Calculate total received for this item
        int totalReceived = 0;
        for (var receiptItem in receiptItemsResponse) {
          if (receiptItem['po_item_id'] == poItemId) {
            totalReceived += receiptItem['quantity_received'] as int;
          }
        }

        summries.add(POItemReceiptSummary(
          poItemId: poItemId,
          itemName: poItem['item_name'],
          quantityOrdered: poItem['quantity'],
          totalReceived: totalReceived,
          unit: poItem['unit'] ?? 'pcs',
        ));
      }

      return summries;
    } catch (e) {
      throw Exception('Failed to get receipt summary: $e');
    }
  }

  // Generate receipt number
  Future<String> generateReceiptNumber() async {
    try {
      final response = await _supabase.rpc('generate_receipt_number');
      return response as String;
    } catch (e) {
      // Fallback pakai timestamp - pasti unique
      final now = DateTime.now();
      final timestamp = now.millisecondsSinceEpoch.toString().substring(7);
      return 'LPB-${now.year}${now.month.toString().padLeft(2, '0')}-$timestamp';
    }
  }

  // Create new receipt (LPB)
  Future<GoodsReceiptModel> createReceipt({
    required String poId,
    required String receivedBy,
    required List<Map<String, dynamic>> items,
    DateTime? receiptDate,
    String? notes,
  }) async {
    try {
      // Generate receipt number
      final receiptNumber = await generateReceiptNumber();

      // insert receipt
      final receiptResponse = await _supabase
          .from('goods_receipt')
          .insert({
            'receipt_number': receiptNumber,
            'po_id': poId,
            'receipt_date': (receiptDate ?? DateTime.now()).toIso8601String(),
            'received_by': receivedBy,
            'status': 'draft',
            'notes': notes,
          })
          .select()
          .single();

      final recieptId = receiptResponse['id'];

      // Insert receipt items
      final itemsData = items.map((item) {
        return {
          'receipt_id': recieptId,
          'po_item_id': item['po_item_id'],
          'item_name': item['item_name'],
          'quantity_ordered': item['quantity_ordered'],
          'quantity_received': item['quantity_received'],
          'unit': item['unit'] ?? 'pcs',
          'notes': item[notes],
        };
      }).toList();

      await _supabase.from('goods_receipt_item').insert(itemsData);

      // Get complete receipt with items
      final receipt = await getReceiptById(recieptId);
      return receipt!;
    } catch (e) {
      throw Exception('Failed to create receipt: $e');
    }
  }

  // Complete receipt (finalize)
  Future<void> completeReceipt(String receiptId) async {
    try {
      await _supabase.from('goods_receipt').update({
        'status': 'completed',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', receiptId);

      // TODO: Update inventory based on received items
      // This should be called here or separatly
    } catch (e) {
      throw Exception('Faiiled to complete receipt: $e');
    }
  }

  // Delete receipt (only draft)
  Future<void> deleteReceipt(String id) async {
    try {
      await _supabase.from('goods_receipt').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete receipt: $e');
    }
  }

  // Check if PO is fully received
  Future<bool> isPOFullyReceived(String poId) async {
    try {
      final summary = await getPOReceiptSummary(poId);
      return summary.every((item) => item.isFullyReceived);
    } catch (e) {
      return false;
    }
  }

  // Update PO status to 'received' if fully received
  Future<void> updatePOStatusIfFullyReceived(String poId) async {
    try {
      final isFullyReceived = await isPOFullyReceived(poId);

      if (isFullyReceived) {
        await _supabase.from('purchase_order').update({
          'status': 'received',
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', poId);
      }
    } catch (e) {
      throw Exception('Failed to update PO status: $e');
    }
  }
}
