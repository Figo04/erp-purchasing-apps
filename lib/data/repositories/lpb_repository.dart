import 'package:erp_purchasing_apps/core/service/api_service.dart';
import 'package:erp_purchasing_apps/core/constants/api_constants.dart';
import 'package:erp_purchasing_apps/core/utils/date_time_helper.dart';
import 'package:erp_purchasing_apps/data/models/lpb_model.dart';

/// LPB Repository
class LPBRepository {
  final ApiService _apiService = ApiService();

  /// Get all LPBs with optional filters
  Future<List<LPBModel>> getAllLPBs({
    String? poId,
    String? supplierId,
    String? receivedBy,
    String? status,
    String? search,
    String? fromDate,
    String? toDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};

      if (poId != null) queryParams['po_id'] = poId;
      if (supplierId != null) queryParams['supplier_id'] = supplierId;
      if (receivedBy != null) queryParams['received_by'] = receivedBy;
      if (status != null) queryParams['status'] = status;
      if (search != null) queryParams['search'] = search;
      if (fromDate != null) queryParams['from_date'] = fromDate;
      if (toDate != null) queryParams['to_date'] = toDate;

      final response = await _apiService.get<List<dynamic>>(
        ApiEndpoints.lpbs,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
        fromJson: (json) => json as List<dynamic>,
      );

      if (response.data == null) return [];

      return response.data!
          .map((item) => LPBModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load LPBs: $e');
    }
  }

  /// Get LPB by ID
  Future<LPBModel> getLPBById(String id) async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiEndpoints.lpbById(id),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.data == null) {
        throw Exception('LPB not found');
      }

      return LPBModel.fromJson(response.data!);
    } catch (e) {
      throw Exception('Failed to load LPB: $e');
    }
  }

  /// Get LPBs by PO ID
  Future<List<LPBModel>> getLPBsByPO(String poId) async {
    try {
      final response = await _apiService.get<List<dynamic>>(
        ApiEndpoints.lpbsByPO(poId),
        fromJson: (json) => json as List<dynamic>,
      );

      if (response.data == null) return [];

      return response.data!
          .map((item) => LPBModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load PO LPBs: $e');
    }
  }

  /// Create LPB (manual entry)
  Future<LPBModel> createLPB({
    required String poId,
    String? shipmentId,
    DateTime? receiptDate,
    String? invoiceNumber,
    double? invoiceAmount,
    String? notes,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.lpbs,
        body: {
          'po_id': poId,
          'shipment_id': shipmentId,
          'receipt_date': receiptDate != null
              ? DateTimeHelper.formatForBackend(receiptDate)
              : null,
          'invoice_number': invoiceNumber,
          'invoice_amount': invoiceAmount,
          'notes': notes,
          'items': items,
        },
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.data == null) {
        throw Exception('Failed to create LPB');
      }

      return LPBModel.fromJson(response.data!);
    } catch (e) {
      throw Exception('Failed to create LPB: $e');
    }
  }

  /// Create LPB from Shipment (from QR scan)
  Future<LPBModel> createLPBFromShipment(String shipmentId) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.createLPBFromShipment(shipmentId),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.data == null) {
        throw Exception('Failed to create LPB from shipment');
      }

      return LPBModel.fromJson(response.data!);
    } catch (e) {
      throw Exception('Failed to create LPB from shipment: $e');
    }
  }

  /// Update LPB (only draft status)
  Future<LPBModel> updateLPB({
    required String lpbId,
    String? invoiceNumber,
    double? invoiceAmount,
    String? notes,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final response = await _apiService.put<Map<String, dynamic>>(
        ApiEndpoints.lpbById(lpbId),
        body: {
          'invoice_number': invoiceNumber,
          'invoice_amount': invoiceAmount,
          'notes': notes,
          'items': items,
        },
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.data == null) {
        throw Exception('Failed to update LPB');
      }

      return LPBModel.fromJson(response.data!);
    } catch (e) {
      throw Exception('Failed to update LPB: $e');
    }
  }

  /// Complete LPB (finalize and update inventory)
  Future<LPBModel> completeLPB(String lpbId, {String? notes}) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.completeLPB(lpbId),
        body: notes != null ? {'notes': notes} : null,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.data == null) {
        throw Exception('Failed to complete LPB');
      }

      return LPBModel.fromJson(response.data!);
    } catch (e) {
      throw Exception('Failed to complete LPB: $e');
    }
  }

  /// Delete LPB (only draft status)
  Future<void> deleteLPB(String lpbId) async {
    try {
      await _apiService.delete(
        ApiEndpoints.lpbById(lpbId),
      );
    } catch (e) {
      throw Exception('Failed to delete LPB: $e');
    }
  }
}
