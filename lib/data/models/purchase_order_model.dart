import 'package:equatable/equatable.dart';

/// Purchase Order Model
class PurchaseOrderModel extends Equatable {
  final String id;
  final String poNumber;
  final String supplierId;
  final String? supplierName;
  final DateTime orderDate;
  final DateTime? expectedDeliveryDate;
  final double totalAmount;
  final String status; // pending, approved, received, cancelled
  final String shipmentStatus; // not_shipped, partial_shipped, fully_shipped
  final int totalShipped;
  final String createdBy;
  final String? createdByName;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Relations
  final List<POItemModel>? items;
  final List<String>? prIds; // Related PR IDs

  const PurchaseOrderModel({
    required this.id,
    required this.poNumber,
    required this.supplierId,
    this.supplierName,
    required this.orderDate,
    this.expectedDeliveryDate,
    required this.totalAmount,
    required this.status,
    required this.shipmentStatus,
    required this.totalShipped,
    required this.createdBy,
    this.createdByName,
    this.approvedBy,
    this.approvedAt,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.items,
    this.prIds,
  });

  factory PurchaseOrderModel.fromJson(Map<String, dynamic> json) {
    return PurchaseOrderModel(
      id: json['id'] as String,
      poNumber: json['po_number'] as String,
      supplierId: json['supplier_id'] as String,
      supplierName: json['supplier_name'] as String?,
      orderDate: DateTime.parse(json['order_date'] as String),
      expectedDeliveryDate: json['expected_delivery_date'] != null
          ? DateTime.parse(json['expected_delivery_date'] as String)
          : null,
      totalAmount: (json['total_amount'] as num).toDouble(),
      status: json['status'] as String,
      shipmentStatus: json['shipment_status'] as String,
      totalShipped: json['total_shipped'] as int? ?? 0,
      createdBy: json['created_by'] as String,
      createdByName: json['created_by_name'] as String?,
      approvedBy: json['approved_by'] as String?,
      approvedAt: json['approved_at'] != null
          ? DateTime.parse(json['approved_at'] as String)
          : null,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      items: json['items'] != null
          ? (json['items'] as List)
              .map((item) => POItemModel.fromJson(item))
              .toList()
          : null,
      prIds: json['pr_ids'] != null
          ? (json['pr_ids'] as List).map((e) => e.toString()).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'po_number': poNumber,
      'supplier_id': supplierId,
      'supplier_name': supplierName,
      'order_date': orderDate.toIso8601String(),
      'expected_delivery_date': expectedDeliveryDate?.toIso8601String(),
      'total_amount': totalAmount,
      'status': status,
      'shipment_status': shipmentStatus,
      'total_shipped': totalShipped,
      'created_by': createdBy,
      'created_by_name': createdByName,
      'approved_by': approvedBy,
      'approved_at': approvedAt?.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'items': items?.map((item) => item.toJson()).toList(),
      'pr_ids': prIds,
    };
  }

  @override
  List<Object?> get props => [
        id,
        poNumber,
        supplierId,
        orderDate,
        totalAmount,
        status,
        shipmentStatus,
      ];
}

/// PO Item Model
class POItemModel extends Equatable {
  final String id;
  final String poId;
  final String? productId;
  final String itemName;
  final int quantity;
  final String unit;
  final double unitPrice;
  final double subtotal;
  final DateTime createdAt;

  const POItemModel({
    required this.id,
    required this.poId,
    this.productId,
    required this.itemName,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    required this.subtotal,
    required this.createdAt,
  });

  factory POItemModel.fromJson(Map<String, dynamic> json) {
    return POItemModel(
      id: json['id'] as String,
      poId: json['po_id'] as String,
      productId: json['product_id'] as String?,
      itemName: json['item_name'] as String,
      quantity: json['quantity'] as int,
      unit: json['unit'] as String,
      unitPrice: (json['unit_price'] as num).toDouble(),
      subtotal: (json['subtotal'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'po_id': poId,
      'product_id': productId,
      'item_name': itemName,
      'quantity': quantity,
      'unit': unit,
      'unit_price': unitPrice,
      'subtotal': subtotal,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, poId, itemName, quantity, unitPrice];
}

/// Create PO Request DTO
class CreatePORequest {
  final String supplierId;
  final DateTime? expectedDeliveryDate;
  final List<String> prIds; // PR IDs to be included
  final List<CreatePOItemRequest> items;
  final String? notes;

  const CreatePORequest({
    required this.supplierId,
    this.expectedDeliveryDate,
    required this.prIds,
    required this.items,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'supplier_id': supplierId,
      'expected_delivery_date': expectedDeliveryDate?.toIso8601String(),
      'pr_ids': prIds,
      'items': items.map((item) => item.toJson()).toList(),
      'notes': notes,
    };
  }
}

/// Create PO Item Request DTO
class CreatePOItemRequest {
  final String? productId;
  final String itemName;
  final int quantity;
  final String unit;
  final double unitPrice;

  const CreatePOItemRequest({
    this.productId,
    required this.itemName,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
  });

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'item_name': itemName,
      'quantity': quantity,
      'unit': unit,
      'unit_price': unitPrice,
    };
  }
}

/// Update PO Request DTO
class UpdatePORequest {
  final DateTime? expectedDeliveryDate;
  final List<UpdatePOItemRequest> items;
  final String? notes;

  const UpdatePORequest({
    this.expectedDeliveryDate,
    required this.items,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'expected_delivery_date': expectedDeliveryDate?.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
      'notes': notes,
    };
  }
}

/// Update PO Item Request DTO
class UpdatePOItemRequest {
  final String? productId;
  final String itemName;
  final int quantity;
  final String unit;
  final double unitPrice;

  const UpdatePOItemRequest({
    this.productId,
    required this.itemName,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
  });

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'item_name': itemName,
      'quantity': quantity,
      'unit': unit,
      'unit_price': unitPrice,
    };
  }
}

/// PR Grouping Helper (from backend)
class PRGrouping {
  final String supplierId;
  final String supplierName;
  final List<String> prIds;
  final List<PRGroupingItem> items;

  const PRGrouping({
    required this.supplierId,
    required this.supplierName,
    required this.prIds,
    required this.items,
  });

  factory PRGrouping.fromJson(Map<String, dynamic> json) {
    return PRGrouping(
      supplierId: json['supplier_id'] as String,
      supplierName: json['supplier_name'] as String,
      prIds: (json['pr_ids'] as List).map((e) => e.toString()).toList(),
      items: (json['items'] as List)
          .map((item) => PRGroupingItem.fromJson(item))
          .toList(),
    );
  }
}

class PRGroupingItem {
  final String? productId;
  final String itemName;
  final int totalQuantity;
  final String unit;
  final double? estimatedPrice;

  const PRGroupingItem({
    this.productId,
    required this.itemName,
    required this.totalQuantity,
    required this.unit,
    this.estimatedPrice,
  });

  factory PRGroupingItem.fromJson(Map<String, dynamic> json) {
    return PRGroupingItem(
      productId: json['product_id'] as String?,
      itemName: json['item_name'] as String,
      totalQuantity: json['total_quantity'] as int,
      unit: json['unit'] as String,
      estimatedPrice: json['estimated_price'] != null
          ? (json['estimated_price'] as num).toDouble()
          : null,
    );
  }
}