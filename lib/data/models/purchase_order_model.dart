import 'package:equatable/equatable.dart';
import 'package:erp_purchasing_apps/data/models/purchase_requisition_model.dart';

class PurchaseOrderModel extends Equatable {
  final String id;
  final String poNumber;
  final String supplierId;
  final String? supplierCode;  
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
  final String? approvedByName;  
  final DateTime? approvedAt;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Relations
  final List<POItemModel>? items;
  final List<String>? prNumbers; 

  const PurchaseOrderModel({
    required this.id,
    required this.poNumber,
    required this.supplierId,
    this.supplierCode,
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
    this.approvedByName,
    this.approvedAt,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.items,
    this.prNumbers,
  });

  factory PurchaseOrderModel.fromJson(Map<String, dynamic> json) {
    return PurchaseOrderModel(
      id: json['id'] as String,
      poNumber: json['po_number'] as String,
      supplierId: json['supplier_id'] as String,
      supplierCode: json['supplier_code'] as String?,
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
      approvedByName: json['approved_by_name'] as String?,
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
      prNumbers: json['pr_numbers'] != null  
          ? (json['pr_numbers'] as List).map((e) => e.toString()).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'po_number': poNumber,
      'supplier_id': supplierId,
      'supplier_code': supplierCode,
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
      'approved_by_name': approvedByName,
      'approved_at': approvedAt?.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'items': items?.map((item) => item.toJson()).toList(),
      'pr_numbers': prNumbers,
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


class POItemModel extends Equatable {
  final String id;
  final String poId;
  final String? productId;
  final String? productCode;  
  final String itemName;
  final String? categoryId;   
  final String? categoryName; 
  final int quantity;
  final String unit;
  final double unitPrice;
  final double subtotal;
  final DateTime createdAt;

  const POItemModel({
    required this.id,
    required this.poId,
    this.productId,
    this.productCode,
    required this.itemName,
    this.categoryId,
    this.categoryName,
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
      productCode: json['product_code'] as String?,
      itemName: json['item_name'] as String,
      categoryId: json['category_id'] as String?,
      categoryName: json['category_name'] as String?,
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
      'product_code': productCode,
      'item_name': itemName,
      'category_id': categoryId,
      'category_name': categoryName,
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

/// ============================================
/// CREATE PO REQUEST DTO (NO CHANGES)
/// ============================================

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
      'expected_delivery_date': expectedDeliveryDate != null
          ? expectedDeliveryDate!.toUtc().toIso8601String()
          : null,
      'pr_ids': prIds,
      'items': items.map((item) => item.toJson()).toList(),
      'notes': notes,
    };
  }
}

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

class PRSupplierGroup {
  final String supplierId;
  final String supplierName;
  final String supplierCode;
  final int totalPRs;
  final List<PRWithItems> prs;

  const PRSupplierGroup({
    required this.supplierId,
    required this.supplierName,
    required this.supplierCode,
    required this.totalPRs,
    required this.prs,
  });

  factory PRSupplierGroup.fromJson(Map<String, dynamic> json) {
    return PRSupplierGroup(
      supplierId: json['supplier_id'] as String,
      supplierName: json['supplier_name'] as String,
      supplierCode: json['supplier_code'] as String,
      totalPRs: json['total_prs'] as int,
      prs: (json['prs'] as List<dynamic>)
          .map((e) => PRWithItems.fromJson(e))
          .toList(),
    );
  }
}

class PRWithItems {
  final PurchaseRequisitionModel pr;
  final List<PRItemModel> items;

  const PRWithItems({
    required this.pr,
    required this.items,
  });

  factory PRWithItems.fromJson(Map<String, dynamic> json) {
    return PRWithItems(
      pr: PurchaseRequisitionModel.fromJson(json['pr']),
      items: (json['items'] as List<dynamic>)
          .map((e) => PRItemModel.fromJson(e))
          .toList(),
    );
  }
}

/// ============================================
/// DEPRECATED - Keep for backward compatibility
/// ============================================

@Deprecated('Use PRSupplierGroup instead')
class PRCategoryGroup {
  final String categoryId;
  final String categoryName;
  final String categoryCode;
  final List<PRWithItems> prs;

  const PRCategoryGroup({
    required this.categoryId,
    required this.categoryName,
    required this.categoryCode,
    required this.prs,
  });

  factory PRCategoryGroup.fromJson(Map<String, dynamic> json) {
    return PRCategoryGroup(
      categoryId: json['category_id'] as String,
      categoryName: json['category_name'] as String,
      categoryCode: json['category_code'] as String,
      prs: (json['prs'] as List<dynamic>)
          .map((e) => PRWithItems.fromJson(e))
          .toList(),
    );
  }
}