import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:erp_purchasing_apps/data/models/payment_model.dart';
import 'package:erp_purchasing_apps/data/repositories/payment_repository.dart';

// ============================================
// REPOSITORY PROVIDER
// ============================================

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository();
});

// ============================================
// PAYMENT LIST PROVIDER (with auto-refresh)
// ============================================

final paymentListProvider = FutureProvider.autoDispose
    .family<List<PaymentModel>, PaymentFilterParams>((ref, params) async {
  final repository = ref.read(paymentRepositoryProvider);

  return await repository.getAllPayments(
    supplierId: params.supplierId,
    status: params.status,
    paidBy: params.paidBy,
    search: params.search,
    fromDate: params.fromDate,
    toDate: params.toDate,
  );
});

// ============================================
// PAYMENT DETAIL PROVIDER
// ============================================

final paymentDetailProvider =
    FutureProvider.autoDispose.family<PaymentModel?, String>((ref, id) async {
  final repository = ref.read(paymentRepositoryProvider);
  return await repository.getPaymentById(id);
});

// ============================================
// UNPAID LPBs GROUPED PROVIDER
// ============================================

final unpaidLPBsGroupedProvider =
    FutureProvider.autoDispose<List<SupplierPaymentSummary>>((ref) async {
  final repository = ref.read(paymentRepositoryProvider);
  return await repository.getUnpaidLPBsGrouped();
});

// ============================================
// UNPAID LPBs BY SUPPLIER PROVIDER
// ============================================

final unpaidLPBsBySupplierProvider = FutureProvider.autoDispose
    .family<List<UnpaidLPBInfo>, String>((ref, supplierId) async {
  final repository = ref.read(paymentRepositoryProvider);
  return await repository.getUnpaidLPBsBySupplier(supplierId);
});

// ============================================
// PAYMENT COUNTS (pending, overdue)
// ============================================

final pendingPaymentsCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final payments = await ref.watch(
    paymentListProvider(PaymentFilterParams(status: 'pending')).future,
  );
  return payments.length;
});

final overduePaymentsCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final payments = await ref.watch(
    paymentListProvider(PaymentFilterParams()).future,
  );
  
  final now = DateTime.now();
  final overdueCount = payments.where((p) {
    if (p.dueDate == null) return false;
    return p.dueDate!.isBefore(now) &&
        (p.status == 'pending' || p.status == 'scheduled');
  }).length;
  
  return overdueCount;
});

// ============================================
// FILTER PARAMS CLASS
// ============================================

class PaymentFilterParams {
  final String? supplierId;
  final String? status;
  final String? paidBy;
  final String? search;
  final DateTime? fromDate;
  final DateTime? toDate;

  PaymentFilterParams({
    this.supplierId,
    this.status,
    this.paidBy,
    this.search,
    this.fromDate,
    this.toDate,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentFilterParams &&
          runtimeType == other.runtimeType &&
          supplierId == other.supplierId &&
          status == other.status &&
          paidBy == other.paidBy &&
          search == other.search &&
          fromDate == other.fromDate &&
          toDate == other.toDate;

  @override
  int get hashCode =>
      supplierId.hashCode ^
      status.hashCode ^
      paidBy.hashCode ^
      search.hashCode ^
      fromDate.hashCode ^
      toDate.hashCode;
}