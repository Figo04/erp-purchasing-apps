import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:erp_purchasing_apps/data/models/shipment_model.dart';

class ShipmentRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get all shipments
  Future<List<ShipmentModel>> getAllShipments() async {
    try {
      final response = await _supabase.from('shipment').select('''
            *,
            purchase_order!shipment_po_id_fkey(po_number),
            suppliers!shipment_supplier_id_fkey(name)
          ''').order('created_at', ascending: false);

      return (response as List).map((json) {
        final poData = json['purchase_order'];
        final SupplierData = json['suppliers'];

        final Map<String, dynamic> shipmentData = Map.from(json);
        shipmentData.remove('purchase_order');
        shipmentData.remove('suppliers');

        if (poData != null) {
          shipmentData['po_number'] = poData['po_number'];
        }
        if (SupplierData != null) {
          shipmentData['supplier_name'] = SupplierData['name'];
        }

        return ShipmentModel.fromJson(shipmentData);
      }).toList();
    } catch (e) {
      throw Exception('Failed to load shipments: $e');
    }
  }

  // Get shipments by supplier (for supplier portal)
  Future<List<ShipmentModel>> getShipmentsBySupplier(String supplierId) async {
    try {
      final response = await _supabase
          .from('shipment')
          .select('''
            *,
            shipment_item(*),
            purchase_order!shipment_po_id_fkey(po_number)
          ''')
          .eq('supplier_id', supplierId)
          .order('created_at', ascending: false);

      return (response as List).map((json) {
        final poData = json['purchase_order'];
        final Map<String, dynamic> shipmentData = Map.from(json);
        shipmentData.remove('purchase_order');

        if (poData != null) {
          shipmentData['po_number'] = poData['po_number'];
        }

        return ShipmentModel.fromJson(shipmentData);
      }).toList();
    } catch (e) {
      throw Exception('Failed to load supplier shipments: $e');
    }
  }

  // Get shipment by ID
  Future<ShipmentModel?> getShipmentById(String id) async {
    try {
      final response = await _supabase.from('shipment').select('''
            *,
            shipment_item(*),
            purchase_order!shipment_po_id_fkey(po_number)
          ''').eq('id', id).maybeSingle();

      if (response == null) return null;

      final poData = response['purchase_order'];
      final Map<String, dynamic> shipmentData = Map.from(response);
      shipmentData.remove('purchase_order');

      if (poData != null) {
        shipmentData['po_number'] = poData['po_number'];
      }

      return ShipmentModel.fromJson(shipmentData);
    } catch (e) {
      throw Exception('Failed to load shipment: $e');
    }
  }

  // Get shipments by PO
  Future<List<ShipmentModel>> getShipmentsByPO(String poId) async {
    try {
      final response = await _supabase
          .from('shipment')
          .select('*, shipment_item(*)')
          .eq('po_id', poId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => ShipmentModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load PO shipments: $e');
    }
  }

  // Generate shipment number
  Future<String> generateShipmentNumber() async {
    try {
      final response = await _supabase.rpc('generate_shipment_number');
      return response as String;
    } catch (e) {
      // Fallback
      final now = DateTime.now();
      final res = await _supabase
          .from('shipment')
          .select('id')
          .count(CountOption.exact);

      final count = res.count;
      return 'SPH-${now.year}${now.month.toString().padLeft(2, '0')}-${(count + 1).toString().padLeft(4, '0')}';
    }
  }

  // Create shipment (dari supplier portal)
  Future<ShipmentModel> createShipment({
    required String poId,
    required String supplierId,
    required String deliveryNoteNumber,
    required List<Map<String, dynamic>> items,
    DateTime? shipmentDate,
    String? notes,
  }) async {
    try {
      // Generate shipment number
      final shipmentNumber = await generateShipmentNumber();

      // Generate QR code data
      final qrData = await _generateQRData(
        poId: poId,
        shipmentNumber: shipmentNumber,
        deliveryNoteNumber: deliveryNoteNumber,
        items: items,
      );

      // Insert shipment
      final shipmentResponse = await _supabase
          .from('shipment')
          .insert({
            'shipment_number': shipmentNumber,
            'po_id': poId,
            'supplier_id': supplierId,
            'delivery_note_number': deliveryNoteNumber,
            'shipment_date': (shipmentDate ?? DateTime.now()).toIso8601String(),
            'notes': notes,
            'qr_code_data': qrData,
            'status': 'pending',
          })
          .select()
          .single();

      final shipmentId = shipmentResponse['id'];

      // Insert shipment items
      final itemsData = items.map((item) {
        return {
          'shipment_id': shipmentId,
          'po_item_id': item['po_item_id'],
          'item_name': item['item_name'],
          'quantity_shipped': item['quantity_shipped'],
          'unit': item['unit'] ?? 'pcs',
          'notes': item['notes'],
        };
      }).toList();

      await _supabase.from('shipment_item').insert(itemsData);

      // Get complet shipment
      final shipment = await getShipmentById(shipmentId);
      return shipment!;
    } catch (e) {
      throw Exception('Failed to create shipment: $e');
    }
  }

  // Generate QR code data
  Future<String> _generateQRData({
    required String poId,
    required String shipmentNumber,
    required String deliveryNoteNumber,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      // Get PO number
      final poResponse = await _supabase
          .from('purchase_order')
          .select('po_number')
          .eq('id', poId)
          .single();

      final qrData = ShipmentQRData(
        shipmentId: '',
        shipmentNumber: shipmentNumber,
        poId: poId,
        poNumber: poResponse['po_number'],
        deliveryNoteNumber: deliveryNoteNumber,
        items: items.map((item) {
          return ShipmentQRItem(
            poItemId: item['po_item_id'],
            name: item['item_name'],
            qty: item['quantity_shipped'],
            unit: item['unit'] ?? 'pcs',
          );
        }).toList(),
      );

      return jsonEncode(qrData.toJson());
    } catch (e) {
      throw Exception('Failed to generate QR data: $e');
    }
  }

  // Decode QR data
  ShipmentQRData decodeQRData(String qrString) {
    try {
      final decoded = jsonDecode(qrString);
      return ShipmentQRData.fromJson(decoded);
    } catch (e) {
      throw Exception('Invalid QR code $e');
    }
  }

  // Update shipment status (dari warehouse setelah scan)
  Future<void> updateShipmentStatus(String shipmentId, String status) async {
    try {
      await _supabase.from('shipment').update({
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', shipmentId);
    } catch (e) {
      throw Exception('Failed to update shipment status: $e');
    }
  }

  // Get shipment by deivery note number (untuk validasi)
  Future<ShipmentModel?> getShipmentByDeliveryNote(
      String deliveryNoteNumber) async {
    try {
      final response = await _supabase
          .from('shipment')
          .select('*, shipment_item(*)')
          .eq('delivery_note_number', deliveryNoteNumber)
          .maybeSingle();

      if (response == null) return null;
      return ShipmentModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to find shipment: $e');
    }
  }
}
