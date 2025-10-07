import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/purchase_order_model.dart';
import '../repositories/po_repository.dart';

final poRepositoryProvider = Provider<PoRepository>((ref) {
  return PoRepository();
});

// Real-time PO Stream Provider
final poStreamProvider = StreamProvider<List<PurchaseOrderModel>>((ref) {
  final supabase = Supabase.instance.client;
  
  return supabase
      .from('purchase_order')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false)
      .asyncMap((data) async {
        final List<PurchaseOrderModel> pos = [];
        
        for (var poData in data) {
          final itemsResponse = await supabase
              .from('purchase_order_item')
              .select()
              .eq('po_id', poData['id']);
          
          poData['purchase_order_item'] = itemsResponse;
          pos.add(PurchaseOrderModel.fromJson(poData));
        }
        
        return pos;
      });
});

// Pending PO Count Provider
final pendingPOCountProvider = Provider<int>((ref) {
  final poStream = ref.watch(poStreamProvider);
  
  return poStream.when(
    data: (pos) => pos.where((po) => po.status == 'pending').length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});