import 'package:equatable/equatable.dart';

class PaymentModel extends Equatable {
  final String id;
  final String paymentNumber;
  final String poId;
  final String? invoiceNumber; // Invoice dari supplier
  final double amount;
  final DateTime? paymentDate;
  final DateTime? dueDate; // Jadwal pembayaran
  final String status; // pending, scheduled, paid, failed, cancelled
  final String? method; // bank_transfer, cash, e_wallet, check
  final String? referenceNumber; // Nomor transaksi bank
  final String? notes;
  final String? verifiedBy; // User ID yang verifikasi
  final DateTime? verifiedAt;
  final String? paidBy; // User ID yang bayar
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined data from PO
  final String? poNumber;
  final String? supplierName;
  final String? verifiedByName;
  final String? paidByName;

  const PaymentModel({
    required this.id,
    required this.paymentNumber,
    required this.poId,
    this.invoiceNumber,
    required this.amount,
    this.paymentDate,
    this.dueDate,
    required this.status,
    this.method,
    this.referenceNumber,
    this.notes,
    this.verifiedBy,
    this.verifiedAt,
    this.paidBy,
    required this.createdAt,
    required this.updatedAt,
    this.poNumber,
    this.supplierName,
    this.verifiedByName,
    this.paidByName,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'],
      paymentNumber: json['payment_number'],
      poId: json['po_id'],
      invoiceNumber: json['invoice_number'],
      amount: double.parse(json['amount'].toString()),
      paymentDate: json['payment_date'] != null
          ? DateTime.parse(json['payment_date'])
          : null,
      dueDate:
          json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
      status: json['status'] ?? 'pending',
      method: json['method'],
      referenceNumber: json['reference_number'],
      notes: json['notes'],
      verifiedBy: json['verified_by'],
      verifiedAt: json['verified_at'] != null
          ? DateTime.parse(json['verified_at'])
          : null,
      paidBy: json['paid_by'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      poNumber: json['po_number'],
      supplierName: json['supplier_name'],
      verifiedByName: json['verified_by_name'],
      paidByName: json['paid_by_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'payment_number': paymentNumber,
      'po_id': poId,
      'invoice_number': invoiceNumber,
      'amount': amount,
      'payment_date': paymentDate?.toIso8601String(),
      'due_date': dueDate?.toIso8601String(),
      'status': status,
      'method': method,
      'reference_number': referenceNumber,
      'notes': notes,
      'verified_by': verifiedBy,
      'verified_at': verifiedAt?.toIso8601String(),
      'paid_by': paidBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  PaymentModel copyWith({
    String? id,
    String? paymentNumber,
    String? poId,
    String? invoiceNumber,
    double? amount,
    DateTime? paymentDate,
    DateTime? dueDate,
    String? status,
    String? method,
    String? referenceNumber,
    String? notes,
    String? verifiedBy,
    DateTime? verifiedAt,
    String? paidBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? poNumber,
    String? supplierName,
    String? verifiedByName,
    String? paidByName,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      paymentNumber: paymentNumber ?? this.paymentNumber,
      poId: poId ?? this.poId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      amount: amount ?? this.amount,
      paymentDate: paymentDate ?? this.paymentDate,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      method: method ?? this.method,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      notes: notes ?? this.notes,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      paidBy: paidBy ?? this.paidBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      poNumber: poNumber ?? this.poNumber,
      supplierName: supplierName ?? this.supplierName,
      verifiedByName: verifiedByName ?? this.verifiedByName,
      paidByName: paidByName ?? this.paidByName,
    );
  }

  @override
  List<Object?> get props => [
        id,
        paymentNumber,
        poId,
        invoiceNumber,
        amount,
        paymentDate,
        dueDate,
        status,
        method,
        referenceNumber,
        notes,
        verifiedBy,
        verifiedAt,
        paidBy,
        createdAt,
        updatedAt,
        poNumber,
        supplierName,
        verifiedByName,
        paidByName,
      ];
}
