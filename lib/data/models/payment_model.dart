import 'package:equatable/equatable.dart';

// ============================================
// PAYMENT MODEL (Backend-aligned)
// ============================================

class PaymentModel extends Equatable {
  final String id;
  final String paymentNumber;
  final String supplierId;
  final String? supplierName;
  final double amount;
  final DateTime? dueDate;
  final DateTime? paymentDate;
  final String status; // pending, scheduled, paid, failed, cancelled
  final String? method; // bank_transfer, cash, e_wallet, check
  final String? referenceNumber;
  final String? paidBy;
  final String? paidByName;
  final String? verifiedBy;
  final String? verifiedByName;
  final DateTime? verifiedAt;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Related LPBs
  final List<LPBPaymentInfo> lpbs;

  const PaymentModel({
    required this.id,
    required this.paymentNumber,
    required this.supplierId,
    this.supplierName,
    required this.amount,
    this.dueDate,
    this.paymentDate,
    required this.status,
    this.method,
    this.referenceNumber,
    this.paidBy,
    this.paidByName,
    this.verifiedBy,
    this.verifiedByName,
    this.verifiedAt,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.lpbs = const [],
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] ?? '',
      paymentNumber: json['payment_number'] ?? '',
      supplierId: json['supplier_id'] ?? '',
      supplierName: json['supplier_name'],
      amount: (json['amount'] ?? 0).toDouble(),
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
      paymentDate: json['payment_date'] != null ? DateTime.parse(json['payment_date']) : null,
      status: json['status'] ?? 'pending',
      method: json['method'],
      referenceNumber: json['reference_number'],
      paidBy: json['paid_by'],
      paidByName: json['paid_by_name'],
      verifiedBy: json['verified_by'],
      verifiedByName: json['verified_by_name'],
      verifiedAt: json['verified_at'] != null ? DateTime.parse(json['verified_at']) : null,
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      lpbs: (json['lpbs'] as List<dynamic>?)
              ?.map((e) => LPBPaymentInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'payment_number': paymentNumber,
      'supplier_id': supplierId,
      'amount': amount,
      'due_date': dueDate?.toIso8601String(),
      'payment_date': paymentDate?.toIso8601String(),
      'status': status,
      'method': method,
      'reference_number': referenceNumber,
      'notes': notes,
    };
  }

  @override
  List<Object?> get props => [
        id,
        paymentNumber,
        supplierId,
        amount,
        status,
        createdAt,
        updatedAt,
      ];
}

// ============================================
// LPB INFO (for payment display)
// ============================================

class LPBPaymentInfo extends Equatable {
  final String lpbId;
  final String lpbNumber;
  final String invoiceNumber;
  final double amount;

  const LPBPaymentInfo({
    required this.lpbId,
    required this.lpbNumber,
    required this.invoiceNumber,
    required this.amount,
  });

  factory LPBPaymentInfo.fromJson(Map<String, dynamic> json) {
    return LPBPaymentInfo(
      lpbId: json['lpb_id'] ?? '',
      lpbNumber: json['lpb_number'] ?? '',
      invoiceNumber: json['invoice_number'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
    );
  }

  @override
  List<Object?> get props => [lpbId, lpbNumber, amount];
}

// ============================================
// UNPAID LPB INFO (for payment creation)
// ============================================

class UnpaidLPBInfo extends Equatable {
  final String lpbId;
  final String lpbNumber;
  final String poNumber;
  final String invoiceNumber;
  final double amount;
  final DateTime? dueDate;
  final DateTime receiptDate;

  const UnpaidLPBInfo({
    required this.lpbId,
    required this.lpbNumber,
    required this.poNumber,
    required this.invoiceNumber,
    required this.amount,
    this.dueDate,
    required this.receiptDate,
  });

  factory UnpaidLPBInfo.fromJson(Map<String, dynamic> json) {
    return UnpaidLPBInfo(
      lpbId: json['lpb_id'] ?? '',
      lpbNumber: json['lpb_number'] ?? '',
      poNumber: json['po_number'] ?? '',
      invoiceNumber: json['invoice_number'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
      receiptDate: DateTime.parse(json['receipt_date']),
    );
  }

  @override
  List<Object?> get props => [lpbId, lpbNumber, amount];
}

// ============================================
// SUPPLIER PAYMENT SUMMARY (grouped unpaid LPBs)
// ============================================

class SupplierPaymentSummary extends Equatable {
  final String supplierId;
  final String supplierName;
  final double totalAmount;
  final int lpbCount;
  final List<UnpaidLPBInfo> lpbs;

  const SupplierPaymentSummary({
    required this.supplierId,
    required this.supplierName,
    required this.totalAmount,
    required this.lpbCount,
    required this.lpbs,
  });

  factory SupplierPaymentSummary.fromJson(Map<String, dynamic> json) {
    return SupplierPaymentSummary(
      supplierId: json['supplier_id'] ?? '',
      supplierName: json['supplier_name'] ?? '',
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      lpbCount: json['lpb_count'] ?? 0,
      lpbs: (json['lpbs'] as List<dynamic>?)
              ?.map((e) => UnpaidLPBInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  @override
  List<Object?> get props => [supplierId, supplierName, totalAmount, lpbCount];
}

// ============================================
// REQUEST DTOs
// ============================================

class CreatePaymentRequest {
  final String supplierId;
  final List<String> lpbIds;
  final DateTime? dueDate;
  final String? method;
  final String? referenceNumber;
  final String? notes;

  CreatePaymentRequest({
    required this.supplierId,
    required this.lpbIds,
    this.dueDate,
    this.method,
    this.referenceNumber,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'supplier_id': supplierId,
      'lpb_ids': lpbIds,
      if (dueDate != null) 'due_date': dueDate!.toIso8601String(),
      if (method != null) 'method': method,
      if (referenceNumber != null) 'reference_number': referenceNumber,
      if (notes != null) 'notes': notes,
    };
  }
}

class UpdatePaymentRequest {
  final DateTime? dueDate;
  final String? method;
  final String? referenceNumber;
  final String? notes;

  UpdatePaymentRequest({
    this.dueDate,
    this.method,
    this.referenceNumber,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      if (dueDate != null) 'due_date': dueDate!.toIso8601String(),
      if (method != null) 'method': method,
      if (referenceNumber != null) 'reference_number': referenceNumber,
      if (notes != null) 'notes': notes,
    };
  }
}

class ProcessPaymentRequest {
  final DateTime paymentDate;
  final String method;
  final String referenceNumber;
  final String? notes;

  ProcessPaymentRequest({
    required this.paymentDate,
    required this.method,
    required this.referenceNumber,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'payment_date': paymentDate.toIso8601String(),
      'method': method,
      'reference_number': referenceNumber,
      if (notes != null) 'notes': notes,
    };
  }
}