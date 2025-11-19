import 'package:equatable/equatable.dart';

/// LPB (Laporan Penerimaan Barang) Model
class LPBModel extends Equatable {
  final String id;
  final String lpbNumber;
  final String poId;
  final String? shipmentId;
  final DateTime receiptDate;
  final String receivedBy;
  final String status; // draft, completed
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? invoiceNumber;
  final double? invoiceAmount;
  final String paymentStatus; // unpaid, pending, paid, partial
  final String? paymentId;

  // Related data (populated by backend)
  final String? poNumber;
  final String? shipmentNumber;
  final String? supplierId;
  final String? supplierName;
  final String? receivedByName;
  final List<LPBItemModel>? items;

  const LPBModel({
    required this.id,
    required this.lpbNumber,
    required this.poId,
    this.shipmentId,
    required this.receiptDate,
    required this.receivedBy,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.invoiceNumber,
    this.invoiceAmount,
    required this.paymentStatus,
    this.paymentId,
    this.poNumber,
    this.shipmentNumber,
    this.supplierId,
    this.supplierName,
    this.receivedByName,
    this.items,
  });

  /// From JSON (Backend Response)
  factory LPBModel.fromJson(Map<String, dynamic> json) {
    return LPBModel(
      id: json['id'] as String,
      lpbNumber: json['lpb_number'] as String,
      poId: json['po_id'] as String,
      shipmentId: json['shipment_id'] as String?,
      receiptDate: DateTime.parse(json['receipt_date'] as String),
      receivedBy: json['received_by'] as String,
      status: json['status'] as String,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      invoiceNumber: json['invoice_number'] as String?,
      invoiceAmount: json['invoice_amount'] != null
          ? (json['invoice_amount'] as num).toDouble()
          : null,
      paymentStatus: json['payment_status'] as String? ?? 'unpaid',
      paymentId: json['payment_id'] as String?,
      poNumber: json['po_number'] as String?,
      shipmentNumber: json['shipment_number'] as String?,
      supplierId: json['supplier_id'] as String?,
      supplierName: json['supplier_name'] as String?,
      receivedByName: json['received_by_name'] as String?,
      items: json['items'] != null
          ? (json['items'] as List)
              .map((item) => LPBItemModel.fromJson(item as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  /// To JSON 
  Map<String, dynamic> toJson() {
    return {
      'po_id': poId,
      'shipment_id': shipmentId,
      'receipt_date': receiptDate.toIso8601String(),
      'invoice_number': invoiceNumber,
      'invoice_amount': invoiceAmount,
      'notes': notes,
      'items': items?.map((item) => item.toJson()).toList(),
    };
  }

  /// Copy with
  LPBModel copyWith({
    String? id,
    String? lpbNumber,
    String? poId,
    String? shipmentId,
    DateTime? receiptDate,
    String? receivedBy,
    String? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? invoiceNumber,
    double? invoiceAmount,
    String? paymentStatus,
    String? paymentId,
    String? poNumber,
    String? shipmentNumber,
    String? supplierId,
    String? supplierName,
    String? receivedByName,
    List<LPBItemModel>? items,
  }) {
    return LPBModel(
      id: id ?? this.id,
      lpbNumber: lpbNumber ?? this.lpbNumber,
      poId: poId ?? this.poId,
      shipmentId: shipmentId ?? this.shipmentId,
      receiptDate: receiptDate ?? this.receiptDate,
      receivedBy: receivedBy ?? this.receivedBy,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      invoiceAmount: invoiceAmount ?? this.invoiceAmount,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentId: paymentId ?? this.paymentId,
      poNumber: poNumber ?? this.poNumber,
      shipmentNumber: shipmentNumber ?? this.shipmentNumber,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      receivedByName: receivedByName ?? this.receivedByName,
      items: items ?? this.items,
    );
  }

  @override
  List<Object?> get props => [
        id,
        lpbNumber,
        poId,
        shipmentId,
        receiptDate,
        receivedBy,
        status,
        notes,
        createdAt,
        updatedAt,
        invoiceNumber,
        invoiceAmount,
        paymentStatus,
        paymentId,
        poNumber,
        shipmentNumber,
        supplierId,
        supplierName,
        receivedByName,
        items,
      ];
}

/// LPB Item Model
class LPBItemModel extends Equatable {
  final String id;
  final String lpbId;
  final String poItemId;
  final String itemName;
  final int quantityOrdered;
  final int quantityReceived;
  final String unit;
  final String? notes;
  final DateTime createdAt;

  // Additional fields from backend (JOIN)
  final String? productId;
  final String? productCode;
  final String? categoryId;
  final String? categoryName;

  const LPBItemModel({
    required this.id,
    required this.lpbId,
    required this.poItemId,
    required this.itemName,
    required this.quantityOrdered,
    required this.quantityReceived,
    required this.unit,
    this.notes,
    required this.createdAt,
    this.productId,
    this.productCode,
    this.categoryId,
    this.categoryName,
  });

  /// From JSON
  factory LPBItemModel.fromJson(Map<String, dynamic> json) {
    return LPBItemModel(
      id: json['id'] as String,
      lpbId: json['lpb_id'] as String,
      poItemId: json['po_item_id'] as String,
      itemName: json['item_name'] as String,
      quantityOrdered: json['quantity_ordered'] as int,
      quantityReceived: json['quantity_received'] as int,
      unit: json['unit'] as String? ?? 'pcs',
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      productId: json['product_id'] as String?,
      productCode: json['product_code'] as String?,
      categoryId: json['category_id'] as String?,
      categoryName: json['category_name'] as String?,
    );
  }

  /// To JSON (untuk request body)
  Map<String, dynamic> toJson() {
    return {
      'po_item_id': poItemId,
      'quantity_received': quantityReceived,
      'notes': notes,
    };
  }

  /// Helper to check if fully received
  bool get isFullyReceived => quantityReceived >= quantityOrdered;

  /// Remaining quantity
  int get remainingQuantity => quantityOrdered - quantityReceived;

  /// Has discrepancy
  bool get hasDiscrepancy => quantityReceived != quantityOrdered;

  @override
  List<Object?> get props => [
        id,
        lpbId,
        poItemId,
        itemName,
        quantityOrdered,
        quantityReceived,
        unit,
        notes,
        createdAt,
        productId,
        productCode,
        categoryId,
        categoryName,
      ];
}