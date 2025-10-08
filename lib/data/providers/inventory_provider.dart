import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/inventory_model.dart';
import '../repositories/inventory_repository.dart';

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return InventoryRepository();
});

// Real-time Inventory Stream Provider
final inventoryStreamProvider = StreamProvider<List<InventoryModel>>((ref) {
  final supabase = Supabase.instance.client;
  
  return supabase
      .from('inventory')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false)
      .map((data) {
        return (data as List)
            .map((json) => InventoryModel.fromJson(json))
            .toList();
      });
});

// Low stock count
final lowStockCountProvider = Provider<int>((ref) {
  final inventoryStream = ref.watch(inventoryStreamProvider);
  
  return inventoryStream.when(
    data: (items) => items.where((item) => 
      item.quantity < 10 && item.status == 'available'
    ).length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});