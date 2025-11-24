import 'package:erp_purchasing_apps/core/service/api_service.dart';
import 'package:erp_purchasing_apps/core/constants/api_constants.dart';
import 'package:erp_purchasing_apps/data/models/payment_model.dart';

class PaymentRepository {
  final ApiService _apiService = ApiService();

  // ============================================
  // GET ALL PAYMENTS (with filters)
  // ============================================
  Future<List<PaymentModel>> getAllPayments({
    String? supplierId,
    String? status,
    String? paidBy,
    String? search,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};

      if (supplierId != null) queryParams['supplier_id'] = supplierId;
      if (status != null) queryParams['status'] = status;
      if (paidBy != null) queryParams['paid_by'] = paidBy;
      if (search != null) queryParams['search'] = search;
      if (fromDate != null) queryParams['from_date'] = fromDate.toIso8601String().split('T')[0];
      if (toDate != null) queryParams['to_date'] = toDate.toIso8601String().split('T')[0];

      final response = await _apiService.get(
        ApiEndpoints.payments,
        queryParameters: queryParams,
      );

      if (response.success && response.data != null) {
        final List<dynamic> dataList = response.data as List<dynamic>;
        return dataList.map((json) => PaymentModel.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      throw Exception('Failed to get payments: $e');
    }
  }

  // ============================================
  // GET PAYMENT BY ID
  // ============================================
  Future<PaymentModel?> getPaymentById(String id) async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.paymentById(id),
      );

      if (response.success && response.data != null) {
        return PaymentModel.fromJson(response.data);
      }

      return null;
    } catch (e) {
      throw Exception('Failed to get payment: $e');
    }
  }

  // ============================================
  // GET UNPAID LPBs GROUPED BY SUPPLIER
  // ============================================
  Future<List<SupplierPaymentSummary>> getUnpaidLPBsGrouped() async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.unpaidLPBsGrouped,
      );

      if (response.success && response.data != null) {
        final List<dynamic> dataList = response.data as List<dynamic>;
        return dataList.map((json) => SupplierPaymentSummary.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      throw Exception('Failed to get unpaid LPBs: $e');
    }
  }

  // ============================================
  // GET UNPAID LPBs BY SUPPLIER
  // ============================================
  Future<List<UnpaidLPBInfo>> getUnpaidLPBsBySupplier(String supplierId) async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.unpaidLPBsBySupplier(supplierId),
      );

      if (response.success && response.data != null) {
        final List<dynamic> dataList = response.data as List<dynamic>;
        return dataList.map((json) => UnpaidLPBInfo.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      throw Exception('Failed to get unpaid LPBs by supplier: $e');
    }
  }

  // ============================================
  // CREATE PAYMENT
  // ============================================
  Future<PaymentModel> createPayment(CreatePaymentRequest request) async {
    try {
      final response = await _apiService.post(
        ApiEndpoints.payments,
        body: request.toJson(),
      );

      if (response.success && response.data != null) {
        return PaymentModel.fromJson(response.data);
      }

      throw Exception(response.message);
    } catch (e) {
      throw Exception('Failed to create payment: $e');
    }
  }

  // ============================================
  // UPDATE PAYMENT
  // ============================================
  Future<PaymentModel> updatePayment(
    String id,
    UpdatePaymentRequest request,
  ) async {
    try {
      final response = await _apiService.put(
        ApiEndpoints.paymentById(id),
        body: request.toJson(),
      );

      if (response.success && response.data != null) {
        return PaymentModel.fromJson(response.data);
      }

      throw Exception(response.message);
    } catch (e) {
      throw Exception('Failed to update payment: $e');
    }
  }

  // ============================================
  // PROCESS PAYMENT
  // ============================================
  Future<PaymentModel> processPayment(
    String id,
    ProcessPaymentRequest request,
  ) async {
    try {
      final response = await _apiService.post(
        ApiEndpoints.processPayment(id),
        body: request.toJson(),
      );

      if (response.success && response.data != null) {
        return PaymentModel.fromJson(response.data);
      }

      throw Exception(response.message);
    } catch (e) {
      throw Exception('Failed to process payment: $e');
    }
  }

  // ============================================
  // VERIFY PAYMENT
  // ============================================
  Future<PaymentModel> verifyPayment(String id, {String? notes}) async {
    try {
      final response = await _apiService.post(
        ApiEndpoints.verifyPayment(id),
        body: notes != null ? {'notes': notes} : {},
      );

      if (response.success && response.data != null) {
        return PaymentModel.fromJson(response.data);
      }

      throw Exception(response.message);
    } catch (e) {
      throw Exception('Failed to verify payment: $e');
    }
  }

  // ============================================
  // CANCEL PAYMENT
  // ============================================
  Future<PaymentModel> cancelPayment(String id, String reason) async {
    try {
      final response = await _apiService.post(
        ApiEndpoints.cancelPayment(id),
        body: {'reason': reason},
      );

      if (response.success && response.data != null) {
        return PaymentModel.fromJson(response.data);
      }

      throw Exception(response.message);
    } catch (e) {
      throw Exception('Failed to cancel payment: $e');
    }
  }

  // ============================================
  // DELETE PAYMENT
  // ============================================
  Future<void> deletePayment(String id) async {
    try {
      final response = await _apiService.delete(
        ApiEndpoints.paymentById(id),
      );

      if (!response.success) {
        throw Exception(response.message);
      }
    } catch (e) {
      throw Exception('Failed to delete payment: $e');
    }
  }
}