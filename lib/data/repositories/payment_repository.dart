import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:erp_purchasing_apps/data/models/payment_model.dart';

class PaymentRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get all payments with joined data
  Future<List<PaymentModel>> getAllPayments() async {
    try {
      final response = await _supabase.from('payment').select('''
            *,
            purchase_order!payment_po_id_fkey(
              po_number,
              suppliers!purchase_order_supplier_id_fkey(name)
            ),
            verified_user:users!payment_verified_by_fkey(full_name),
            paid_user:users!payment_paid_by_fkey(full_name)
          ''').order('created_at', ascending: false);

      return (response as List).map((json) {
        final poData = json['purchase_order'];
        final verifiedUser = json['verified_user'];
        final paidUser = json['paid_user'];

        final Map<String, dynamic> paymentData = Map.from(json);
        paymentData.remove('purchase_order');
        paymentData.remove('verified_user');
        paymentData.remove('paid_user');

        if (poData != null) {
          paymentData['po_number'] = poData['po_number'];
          if (poData['suppliers'] != null) {
            paymentData['supplier_name'] = poData['suppliers']['name'];
          }
        }

        if (verifiedUser != null) {
          paymentData['verified_by_name'] = verifiedUser['full_name'];
        }

        if (paidUser != null) {
          paymentData['paid_by_name'] = paidUser['full_name'];
        }

        return PaymentModel.fromJson(paymentData);
      }).toList();
    } catch (e) {
      throw Exception('Failed to load payments: $e');
    }
  }

  // Get payment by ID
  Future<PaymentModel?> getPaymentById(String id) async {
    try {
      final response = await _supabase.from('payment').select('''
            *,
            purchase_order!payment_po_id_fkey(
              po_number,
              suppliers!purchase_order_supplier_id_fkey(name)
            ),
            verified_user:users!payment_verified_by_fkey(full_name),
            paid_user:users!payment_paid_by_fkey(full_name)
          ''').eq('id', id).maybeSingle();

      if (response == null) return null;

      final poData = response['purchase_order'];
      final verifiedUser = response['verified_user'];
      final paidUser = response['paid_user'];

      final Map<String, dynamic> paymentData = Map.from(response);
      paymentData.remove('purchase_order');
      paymentData.remove('verified_user');
      paymentData.remove('paid_user');

      if (poData != null) {
        paymentData['po_number'] = poData['po_number'];
        if (poData['suppliers'] != null) {
          paymentData['supplier_name'] = poData['suppliers']['name'];
        }
      }

      if (verifiedUser != null) {
        paymentData['verified_by_name'] = verifiedUser['full_name'];
      }

      if (paidUser != null) {
        paymentData['paid_by_name'] = paidUser['full_name'];
      }

      return PaymentModel.fromJson(paymentData);
    } catch (e) {
      throw Exception('Failed to load payment: $e');
    }
  }

  // Get payments by status
  Future<List<PaymentModel>> getPaymentsByStatus(String status) async {
    try {
      final response = await _supabase.from('payment').select('''
            *,
            purchase_order!payment_po_id_fkey(
              po_number,
              suppliers!purchase_order_supplier_id_fkey(name)
            ),
            verified_user:users!payment_verified_by_fkey(full_name),
            paid_user:users!payment_paid_by_fkey(full_name)
          ''').eq('status', status).order('created_at', ascending: false);

      return (response as List).map((json) {
        final poData = json['purchase_order'];
        final verifiedUser = json['verified_user'];
        final paidUser = json['paid_user'];

        final Map<String, dynamic> paymentData = Map.from(json);
        paymentData.remove('purchase_order');
        paymentData.remove('verified_user');
        paymentData.remove('paid_user');

        if (poData != null) {
          paymentData['po_number'] = poData['po_number'];
          if (poData['suppliers'] != null) {
            paymentData['supplier_name'] = poData['suppliers']['name'];
          }
        }

        if (verifiedUser != null) {
          paymentData['verified_by_name'] = verifiedUser['full_name'];
        }

        if (paidUser != null) {
          paymentData['paid_by_name'] = paidUser['full_name'];
        }

        return PaymentModel.fromJson(paymentData);
      }).toList();
    } catch (e) {
      throw Exception('Failed to load payments by status: $e');
    }
  }

  // Get payment by PO ID
  Future<PaymentModel?> getPaymentByPOId(String poId) async {
    try {
      final response = await _supabase.from('payment').select('''
            *,
            purchase_order!payment_po_id_fkey(
              po_number,
              suppliers!purchase_order_supplier_id_fkey(name)
            ),
            verified_user:users!payment_verified_by_fkey(full_name),
            paid_user:users!payment_paid_by_fkey(full_name)
          ''').eq('po_id', poId).maybeSingle();

      if (response == null) return null;

      final poData = response['purchase_order'];
      final verifiedUser = response['verified_user'];
      final paidUser = response['paid_user'];

      final Map<String, dynamic> paymentData = Map.from(response);
      paymentData.remove('purchase_order');
      paymentData.remove('verified_user');
      paymentData.remove('paid_user');

      if (poData != null) {
        paymentData['po_number'] = poData['po_number'];
        if (poData['suppliers'] != null) {
          paymentData['supplier_name'] = poData['suppliers']['name'];
        }
      }

      if (verifiedUser != null) {
        paymentData['verified_by_name'] = verifiedUser['full_name'];
      }

      if (paidUser != null) {
        paymentData['paid_by_name'] = paidUser['full_name'];
      }

      return PaymentModel.fromJson(paymentData);
    } catch (e) {
      throw Exception('Failed to load payment by PO: $e');
    }
  }

  // Create payment from PO
  Future<PaymentModel> createPayment({
    required String poId,
    required double amount,
    String? invoiceNumber,
    DateTime? dueDate,
    String? notes,
  }) async {
    try {
      // Generate payment number
      final paymentNumber = await _generatePaymentNumber();

      final data = {
        'payment_number': paymentNumber,
        'po_id': poId,
        'invoice_number': invoiceNumber,
        'amount': amount,
        'due_date': dueDate?.toIso8601String(),
        'status': 'pending',
        'notes': notes,
      };

      final response =
          await _supabase.from('payment').insert(data).select().single();

      return PaymentModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create payment: $e');
    }
  }

  // Verify payment
  Future<PaymentModel> verifyPayment({
    required String id,
    required String userId,
  }) async {
    try {
      final data = {
        'verified_by': userId,
        'verified_at': DateTime.now().toIso8601String(),
        'status': 'scheduled',
      };

      final response = await _supabase
          .from('payment')
          .update(data)
          .eq('id', id)
          .select()
          .single();

      return PaymentModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to verify payment: $e');
    }
  }

  // Process payment (mark as paid)
  Future<PaymentModel> processPayment({
    required String id,
    required String userId,
    required DateTime paymentDate,
    required String method,
    String? referenceNumber,
  }) async {
    try {
      final data = {
        'payment_date': paymentDate.toIso8601String(),
        'method': method,
        'reference_number': referenceNumber,
        'paid_by': userId,
        'status': 'paid',
      };

      final response = await _supabase
          .from('payment')
          .update(data)
          .eq('id', id)
          .select()
          .single();

      return PaymentModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to process payment: $e');
    }
  }

  // Update payment
  Future<PaymentModel> updatePayment({
    required String id,
    String? invoiceNumber,
    double? amount,
    DateTime? dueDate,
    String? notes,
  }) async {
    try {
      final data = <String, dynamic>{};

      if (invoiceNumber != null) data['invoice_number'] = invoiceNumber;
      if (amount != null) data['amount'] = amount;
      if (dueDate != null) data['due_date'] = dueDate.toIso8601String();
      if (notes != null) data['notes'] = notes;

      final response = await _supabase
          .from('payment')
          .update(data)
          .eq('id', id)
          .select()
          .single();

      return PaymentModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update payment: $e');
    }
  }

  // Cancel payment
  Future<PaymentModel> cancelPayment({
    required String id,
    required String reason,
  }) async {
    try {
      final current = await getPaymentById(id);
      if (current == null) {
        throw Exception('Payment not found');
      }

      final notes =
          '${current.notes ?? ''}\n[CANCELLED] ${DateTime.now()}: $reason'
              .trim();

      final data = {
        'status': 'cancelled',
        'notes': notes,
      };

      final response = await _supabase
          .from('payment')
          .update(data)
          .eq('id', id)
          .select()
          .single();

      return PaymentModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to cancel payment: $e');
    }
  }

  // Delete payment
  Future<void> deletePayment(String id) async {
    try {
      await _supabase.from('payment').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete payment: $e');
    }
  }

  // Get overdue payments
  Future<List<PaymentModel>> getOverduePayments() async {
    try {
      final now = DateTime.now().toIso8601String();

      final response = await _supabase
          .from('payment')
          .select('''
            *,
            purchase_order!payment_po_id_fkey(
              po_number,
              suppliers!purchase_order_supplier_id_fkey(name)
            )
          ''')
          .lt('due_date', now)
          .inFilter('status', ['pending', 'scheduled'])
          .order('due_date', ascending: true);

      return (response as List).map((json) {
        final poData = json['purchase_order'];
        final Map<String, dynamic> paymentData = Map.from(json);
        paymentData.remove('purchase_order');

        if (poData != null) {
          paymentData['po_number'] = poData['po_number'];
          if (poData['suppliers'] != null) {
            paymentData['supplier_name'] = poData['suppliers']['name'];
          }
        }

        return PaymentModel.fromJson(paymentData);
      }).toList();
    } catch (e) {
      throw Exception('Failed to load overdue payments: $e');
    }
  }

  // Generate payment number
  Future<String> _generatePaymentNumber() async {
    try {
      final count = await _supabase.from('payment').select().count();

      final nextNumber = (count.count ?? 0) + 1;
      final yearMonth =
          DateTime.now().toString().substring(0, 7).replaceAll('-', '');
      return 'PAY-$yearMonth-${nextNumber.toString().padLeft(4, '0')}';
    } catch (e) {
      throw Exception('Failed to generate payment number: $e');
    }
  }
}
