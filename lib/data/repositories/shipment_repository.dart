import 'dart:convert';
import 'package:erp_purchasing_apps/core/api/api_response.dart';
import 'package:erp_purchasing_apps/core/service/api_service.dart';
import 'package:erp_purchasing_apps/core/constants/api_constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:erp_purchasing_apps/data/models/shipment_model.dart';

class ShipmentRepository {
  final ApiService _apiService = ApiService();

  // Get all shipments
  Future<List<ShipmentModel>> getAllShipments({
    String? poId,
    String? supplierId,
    String? status,
    String? search,
    String? fromDate,
    String? toDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};

      if (poId != null) queryParams['po_id'] = poId;
      if (supplierId != null) queryParams['supplier_id'] = supplierId;
      if (status != null) queryParams['status'] = status;
      if (search != null) queryParams['search'] = search;
      if (fromDate != null) queryParams['from_date'] = fromDate;
      if (toDate != null) queryParams['to_date'] = toDate;

      final response = await _apiService.get<List<dynamic>>(
        ApiEndpoints.shipments,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
        fromJson: (json) => json as List<dynamic>,
      );

      if (response.data == null) return [];

      return response.data!
          .map((item) => ShipmentModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load shipments: $e');
    }
  }

  // // Get shipments by supplier (for supplier portal)
  // Future<List<ShipmentModel>> getShipmentsBySupplier(String supplierId) async {
  //   try {
  //     final response = await _supabase
  //         .from('shipment')
  //         .select('''
  //           *,
  //           shipment_item(*),
  //           purchase_order!shipment_po_id_fkey(po_number)
  //         ''')
  //         .eq('supplier_id', supplierId)
  //         .order('created_at', ascending: false);

  //     return (response as List).map((json) {
  //       final poData = json['purchase_order'];
  //       final Map<String, dynamic> shipmentData = Map.from(json);
  //       shipmentData.remove('purchase_order');

  //       if (poData != null) {
  //         shipmentData['po_number'] = poData['po_number'];
  //       }

  //       return ShipmentModel.fromJson(shipmentData);
  //     }).toList();
  //   } catch (e) {
  //     throw Exception('Failed to load supplier shipments: $e');
  //   }
  // }

  // Get shipment by ID
  Future<ShipmentModel> getShipmentById(String id) async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiEndpoints.shipmentById(id),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.data == null) {
        throw Exception('Shipment not found');
      }

      return ShipmentModel.fromJson(response.data!);
    } catch (e) {
      throw Exception('Failed to load shipment: $e');
    }
  }

  // Get shipments by PO
  Future<List<ShipmentModel>> getShipmentsByPO(String poId) async {
    try {
      final response = await _apiService.get<List<dynamic>>(
        ApiEndpoints.shipmentsByPO(poId),
        fromJson: (json) => json as List<dynamic>,
      );

      if (response.data == null) return [];

      return response.data!
          .map((item) => ShipmentModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load PO shipments: $e');
    }
  }

  /// Scan QR Code (untuk warehouse)
  /// Backend akan validate QR code integrity dan return shipment data
  Future<ShipmentModel> scanQRCode(String qrCodeData) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.scanQR,
        body: {
          'qr_code_data': qrCodeData,
        },
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.data == null) {
        throw Exception('Invalid QR code');
      }

      return ShipmentModel.fromJson(response.data!);
    } catch (e) {
      throw Exception('Failed to scan QR code: $e');
    }
  }

  // Regenerate QR Code (untuk admin/purchasing)
  Future<ShipmentModel> regenerateQRCode(String shipmentId) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.regenerateQR(shipmentId),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.data == null) {
        throw Exception('Failed to regenerate QR code');
      }

      return ShipmentModel.fromJson(response.data!);
    } catch (e) {
      throw Exception('Failed to regenerate QR code: $e');
    }
  }

  /// Create shipment (untuk supplier via web portal)
  /// Note: Ini dipanggil dari web portal, bukan dari desktop app
  Future<ShipmentModel> createShipment({
    required String poId,
    required String deliveryNoteNumber,
    required List<Map<String, dynamic>> items,
    String? notes,
  }) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.shipments,
        body: {
          'po_id': poId,
          'delivery_note_number': deliveryNoteNumber,
          'items': items,
          'notes': notes,
        },
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.data == null) {
        throw Exception('Failed to create shipment');
      }

      return ShipmentModel.fromJson(response.data!);
    } catch (e) {
      throw Exception('Failed to create shipment: $e');
    }
  }

  // Update shipment (untuk supplier)
  Future<ShipmentModel> updateShipment({
    required String shipmentId,
    required String deliveryNoteNumber,
    required List<Map<String, dynamic>> items,
    String? notes,
  }) async {
    try {
      final response = await _apiService.put<Map<String, dynamic>>(
        ApiEndpoints.shipmentById(shipmentId),
        body: {
          'delivery_note_number': deliveryNoteNumber,
          'items': items,
          'notes': notes,
        },
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.data == null) {
        throw Exception('Failed to update shipment');
      }

      return ShipmentModel.fromJson(response.data!);
    } catch (e) {
      throw Exception('Failed to update shipment: $e');
    }
  }

  // Delete shipment (untuk supplier, only pending status)
  Future<void> deleteShipment(String shipmentId) async {
    try {
      await _apiService.delete(
        ApiEndpoints.shipmentById(shipmentId),
      );
    } catch (e) {
      throw Exception('Failed to delete shipment: $e');
    }
  }

  /// Search shipments by Beacukai
  Future<List<ShipmentModel>> searchByBeacukai({
    String? beacukaiNo,
    String? beacukaiNoAju,
  }) async {
    try {
      final queryParams = <String, dynamic>{};

      if (beacukaiNo != null) queryParams['beacukai_no'] = beacukaiNo;
      if (beacukaiNoAju != null) queryParams['beacukai_no_aju'] = beacukaiNoAju;

      final response = await _apiService.get<List<dynamic>>(
        ApiEndpoints.shipments,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
        fromJson: (json) => json as List<dynamic>,
      );

      if (response.data == null) return [];

      return response.data!
          .map((item) => ShipmentModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to search shipments by beacukai: $e');
    }
  }
}
