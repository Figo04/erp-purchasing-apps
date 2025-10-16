import 'package:equatable/equatable.dart';

class GoodsReceiptModel extends Equatable {
  final String id;
  final String receiptNumber;
  final String poId;
  final DateTime receiptDate;
  final String receivedBy;
  final String status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<GoodsReceiptItemModel>? items;
  
  // Additional fields for display
  final String? poNumber;
  final String? receiverName;

  const GoodsReceiptModel({
    required this.id,
    required this.receiptNumber,
    required this.poId,
    required this.receiptDate,
    required this.receivedBy,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.items,
    this.poNumber,
    this.receiverName,
  });

  factory GoodsReceiptModel.fromJson(Map<String, dynamic> json) {
    return GoodsReceiptModel(
      id: json['id'],
      receiptNumber: json['receipt_number'],
      poId: json['po_id'],
      receiptDate: DateTime.parse(json['receipt_date']),
      receivedBy: json['received_by'],
      status: json['status'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      items: json['goods_receipt_item'] != null
          ? (json['goods_receipt_item'] as List)
              .map((item) => GoodsReceiptItemModel.fromJson(item))
              .toList()
          : null,
      poNumber: json['po_number'],
      receiverName: json['receiver_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'receipt_number': receiptNumber,
      'po_id': poId,
      'receipt_date': receiptDate.toIso8601String(),
      'received_by': receivedBy,
      'status': status,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        receiptNumber,
        poId,
        receiptDate,
        receivedBy,
        status,
        notes,
        createdAt,
        updatedAt,
        items,
        poNumber,
        receiverName,
      ];
}

class GoodsReceiptItemModel extends Equatable {
  final String id;
  final String receiptId;
  final String poItemId;
  final String itemName;
  final int quantityOrdered;
  final int quantityReceived;
  final String unit;
  final String? notes;
  final DateTime createdAt;

  const GoodsReceiptItemModel({
    required this.id,
    required this.receiptId,
    required this.poItemId,
    required this.itemName,
    required this.quantityOrdered,
    required this.quantityReceived,
    required this.unit,
    this.notes,
    required this.createdAt,
  });

  factory GoodsReceiptItemModel.fromJson(Map<String, dynamic> json) {
    return GoodsReceiptItemModel(
      id: json['id'],
      receiptId: json['receipt_id'],
      poItemId: json['po_item_id'],
      itemName: json['item_name'],
      quantityOrdered: json['quantity_ordered'],
      quantityReceived: json['quantity_received'],
      unit: json['unit'] ?? 'pcs',
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'receipt_id': receiptId,
      'po_item_id': poItemId,
      'item_name': itemName,
      'quantity_ordered': quantityOrdered,
      'quantity_received': quantityReceived,
      'unit': unit,
      'notes': notes,
    };
  }

  // Helper to check if fully received
  bool get isFullyReceived => quantityReceived >= quantityOrdered;
  
  // Remaining quantity
  int get remainingQuantity => quantityOrdered - quantityReceived;

  @override
  List<Object?> get props => [
        id,
        receiptId,
        poItemId,
        itemName,
        quantityOrdered,
        quantityReceived,
        unit,
        notes,
        createdAt,
      ];
}

// Helper model untuk tracking total received per PO item
class POItemReceiptSummary {
  final String poItemId;
  final String itemName;
  final int quantityOrdered;
  final int totalReceived;
  final String unit;
  
  const POItemReceiptSummary({
    required this.poItemId,
    required this.itemName,
    required this.quantityOrdered,
    required this.totalReceived,
    required this.unit,
  });
  
  int get remainingQuantity => quantityOrdered - totalReceived;
  bool get isFullyReceived => totalReceived >= quantityOrdered;
  double get receivedPercentage => (totalReceived / quantityOrdered * 100);
}