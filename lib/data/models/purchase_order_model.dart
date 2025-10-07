import 'package:equatable/equatable.dart';

class PurchaseOrderModel extends Equatable {
  final String id;
  final String poNumber;
  final String? prId;
  final String supplierId;
  final DateTime orderDate;
  final DateTime? expectedDeliveryDate;
  final double totalAmount;
  final String status;
  final String createdBy;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<POItemModel>? items;

  const PurchaseOrderModel({
    required this.id,
    required this.poNumber,
    this.prId,
    required this.supplierId,
    required this.orderDate,
    this.expectedDeliveryDate,
    required this.totalAmount,
    required this.status,
    required this.createdBy,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.items,
  });

  factory PurchaseOrderModel.fromJson(Map<String, dynamic> json) {
    return PurchaseOrderModel(
      id: json['id'],
      poNumber: json['po_number'],
      prId: json['pr_id'],
      supplierId: json['supplier_id'],
      orderDate: DateTime.parse(json['order_date']),
      expectedDeliveryDate: json['expected_delivery_date'] != null
          ? DateTime.parse(json['expected_delivery_date'])
          : null,
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      status: json['status'],
      createdBy: json['created_by'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      items: json['purchase_order_item'] != null
          ? (json['purchase_order_item'] as List)
              .map((item) => POItemModel.fromJson(item))
              .toList()
          : null,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'po_number': poNumber,
      'pr_id': prId,
      'supplier_id': supplierId,
      'order_date': orderDate.toIso8601String(),
      'expected_delivery_date': expectedDeliveryDate?.toIso8601String(),
      'total_amount': totalAmount,
      'status': status,
      'created_by': createdBy,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        poNumber,
        prId,
        supplierId,
        orderDate,
        expectedDeliveryDate,
        totalAmount,
        status,
        createdBy,
        notes,
        createdAt,
        updatedAt,
        items
      ];
}

class POItemModel extends Equatable {
  final String id;
  final String poId;
  final String itemName;
  final int quantity;
  final String unit;
  final double unitPrice;
  final double subtotal;
  final DateTime createdAt;

  const POItemModel({
    required this.id,
    required this.poId,
    required this.itemName,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    required this.subtotal,
    required this.createdAt,
  });

  factory POItemModel.fromJson(Map<String, dynamic> json) {
    return POItemModel(
      id: json['id'],
      poId: json['po_id'],
      itemName: json['item_name'],
      quantity: json['quantity'],
      unit: json['unit'] ?? 'pcs',
      unitPrice: (json['unit_price'] ?? 0).toDouble(),
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'po_id': poId,
      'item_name': itemName,
      'quantity': quantity,
      'unit': unit,
      'unit_price': unitPrice,
    };
  }

  @override
  List<Object?> get props => [
        id,
        poId,
        itemName,
        quantity,
        unit,
        unitPrice,
        subtotal,
        createdAt,
      ];
}
