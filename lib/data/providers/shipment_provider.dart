import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/shipment_model.dart';
import '../repositories/shipment_repository.dart';

final shipmentRepositoryProvider = Provider<ShipmentRepository>((ref) {
  return ShipmentRepository();
});

// Real-time Shipment Stream Provider
final shipmentStreamProvider = StreamProvider<List<ShipmentModel>>((ref) {
  final supabase = Supabase.instance.client;
  
  return supabase
      .from('shipment')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false)
      .asyncMap((data) async {
        final List<ShipmentModel> shipments = [];
        
        for (var shipmentData in data) {
          // Fetch items
          final itemsResponse = await supabase
              .from('shipment_item')
              .select()
              .eq('shipment_id', shipmentData['id']);
          
          // Fetch PO info
          final poResponse = await supabase
              .from('purchase_order')
              .select('po_number')
              .eq('id', shipmentData['po_id'])
              .maybeSingle();
          
          // Fetch supplier info
          final supplierResponse = await supabase
              .from('suppliers')
              .select('name')
              .eq('id', shipmentData['supplier_id'])
              .maybeSingle();
          
          shipmentData['shipment_item'] = itemsResponse;
          if (poResponse != null) {
            shipmentData['po_number'] = poResponse['po_number'];
          }
          if (supplierResponse != null) {
            shipmentData['supplier_name'] = supplierResponse['name'];
          }
          
          shipments.add(ShipmentModel.fromJson(shipmentData));
        }
        
        return shipments;
      });
});

// Get shipments by supplier (for supplier portal)
final shipmentsBySupplierProvider = FutureProvider.family<List<ShipmentModel>, String>((ref, supplierId) async {
  final repo = ref.watch(shipmentRepositoryProvider);
  return await repo.getShipmentsBySupplier(supplierId);
});

// Get shipments by PO
final shipmentsByPOProvider = FutureProvider.family<List<ShipmentModel>, String>((ref, poId) async {
  final repo = ref.watch(shipmentRepositoryProvider);
  return await repo.getShipmentsByPO(poId);
});

// Pending shipments count
final pendingShipmentsCountProvider = Provider<int>((ref) {
  final shipmentsStream = ref.watch(shipmentStreamProvider);
  
  return shipmentsStream.when(
    data: (shipments) => shipments.where((s) => s.status == 'pending').length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

// Received shipments count
final receivedShipmentsCountProvider = Provider<int>((ref) {
  final shipmentsStream = ref.watch(shipmentStreamProvider);
  
  return shipmentsStream.when(
    data: (shipments) => shipments.where((s) => s.status == 'received').length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});