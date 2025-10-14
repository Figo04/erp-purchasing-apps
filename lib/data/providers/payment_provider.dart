import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/payment_model.dart';
import '../repositories/payment_repository.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository();
});

// Real-time Payment Stream Provider
final paymentStreamProvider = StreamProvider<List<PaymentModel>>((ref) {
  final supabase = Supabase.instance.client;

  return supabase
      .from('payment')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false)
      .asyncMap((data) async {
        final List<PaymentModel> payments = [];

        for (var json in data) {
          try {
            // Fetch PO data
            if (json['po_id'] != null) {
              final poResponse = await supabase
                  .from('purchase_order')
                  .select(
                      'po_number, supplier_id, suppliers!purchase_order_supplier_id_fkey(name)')
                  .eq('id', json['po_id'])
                  .maybeSingle();

              if (poResponse != null) {
                json['po_number'] = poResponse['po_number'];
                if (poResponse['suppliers'] != null) {
                  json['supplier_name'] = poResponse['suppliers']['name'];
                }
              }
            }

            // Fetch verified by user
            if (json['verified_by'] != null) {
              final verifiedUser = await supabase
                  .from('users')
                  .select('full_name')
                  .eq('id', json['verified_by'])
                  .maybeSingle();

              if (verifiedUser != null) {
                json['verified_by_name'] = verifiedUser['full_name'];
              }
            }

            // Fetch paid by user
            if (json['paid_by'] != null) {
              final paidUser = await supabase
                  .from('users')
                  .select('full_name')
                  .eq('id', json['paid_by'])
                  .maybeSingle();

              if (paidUser != null) {
                json['paid_by_name'] = paidUser['full_name'];
              }
            }

            payments.add(PaymentModel.fromJson(json));
          } catch (e) {
            // Skip this payment if error
            continue;
          }
        }

        return payments;
      });
});

// Pending payments count
final pendingPaymentsCountProvider = Provider<int>((ref) {
  final paymentStream = ref.watch(paymentStreamProvider);

  return paymentStream.when(
    data: (payments) => payments.where((p) => p.status == 'pending').length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

// Overdue payments count
final overduePaymentsCountProvider = Provider<int>((ref) {
  final paymentStream = ref.watch(paymentStreamProvider);

  return paymentStream.when(
    data: (payments) {
      final now = DateTime.now();
      return payments.where((p) {
        if (p.dueDate == null) return false;
        return p.dueDate!.isBefore(now) &&
            (p.status == 'pending' || p.status == 'scheduled');
      }).length;
    },
    loading: () => 0,
    error: (_, __) => 0,
  );
});

// Payments by status
final paymentsByStatusProvider = Provider.family<int, String>((ref, status) {
  final paymentStream = ref.watch(paymentStreamProvider);

  return paymentStream.when(
    data: (payments) => payments.where((p) => p.status == status).length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});
