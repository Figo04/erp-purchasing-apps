import 'dart:convert';

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

      if (verifiedUser != null) {
        paymentData['verified_by_name'] = paidUser['full_name'];
      }

      return PaymentModel.fromJson(paymentData);
    } catch (e) {
      throw Exception('Failed to load payment: $e');
    }
  }

  
}
