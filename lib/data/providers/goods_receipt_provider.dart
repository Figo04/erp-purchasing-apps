import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/goods_receipt_model.dart';
import '../repositories/goods_receipt_repository.dart';

final goodsReceiptRepositoryProvider = Provider<GoodsReceiptRepository>((ref) {
  return GoodsReceiptRepository();
});

// Real-time LPB Stream Provider
final goodsReceiptStreamProvider = StreamProvider<List<GoodsReceiptModel>>((ref) {
  final supabase = Supabase.instance.client;
  
  return supabase
      .from('goods_receipt')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false)
      .asyncMap((data) async {
        final List<GoodsReceiptModel> receipts = [];
        
        for (var receiptData in data) {
          // Fetch items for each receipt
          final itemsResponse = await supabase
              .from('goods_receipt_item')
              .select()
              .eq('receipt_id', receiptData['id']);
          
          // Fetch PO info
          final poResponse = await supabase
              .from('purchase_order')
              .select('po_number')
              .eq('id', receiptData['po_id'])
              .maybeSingle();
          
          // Fetch user info
          final userResponse = await supabase
              .from('users')
              .select('full_name')
              .eq('id', receiptData['received_by'])
              .maybeSingle();
          
          receiptData['goods_receipt_item'] = itemsResponse;
          if (poResponse != null) {
            receiptData['po_number'] = poResponse['po_number'];
          }
          if (userResponse != null) {
            receiptData['receiver_name'] = userResponse['full_name'];
          }
          
          receipts.add(GoodsReceiptModel.fromJson(receiptData));
        }
        
        return receipts;
      });
});

// Get receipts by PO ID
final receiptsByPOProvider = FutureProvider.family<List<GoodsReceiptModel>, String>((ref, poId) async {
  final repo = ref.watch(goodsReceiptRepositoryProvider);
  return await repo.getReceiptsByPO(poId);
});

// Get PO receipt summary (for partial receiving tracking)
final poReceiptSummaryProvider = FutureProvider.family<List<POItemReceiptSummary>, String>((ref, poId) async {
  final repo = ref.watch(goodsReceiptRepositoryProvider);
  return await repo.getPOReceiptSummary(poId);
});

// Check if PO is fully received
final isPOFullyReceivedProvider = FutureProvider.family<bool, String>((ref, poId) async {
  final repo = ref.watch(goodsReceiptRepositoryProvider);
  return await repo.isPOFullyReceived(poId);
});

// Draft receipts count
final draftReceiptsCountProvider = Provider<int>((ref) {
  final receiptsStream = ref.watch(goodsReceiptStreamProvider);
  
  return receiptsStream.when(
    data: (receipts) => receipts.where((r) => r.status == 'draft').length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

// Completed receipts count
final completedReceiptsCountProvider = Provider<int>((ref) {
  final receiptsStream = ref.watch(goodsReceiptStreamProvider);
  
  return receiptsStream.when(
    data: (receipts) => receipts.where((r) => r.status == 'completed').length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});