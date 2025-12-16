import 'package:equatable/equatable.dart';

/// Purchase Requisition Model
class PurchaseRequisitionModel extends Equatable {
  final String id;
  final String prNumber;
  final String divisionId;
  final String? divisionName;
  final String? divisionCode;
  final String processingType; // material, aset, logistik
  final String requesterId;
  final String? requesterName;
  final int year;
  final String status; // draft, pending, approved, rejected, closed
  final String? approvedBy;
  final String? approvedByName;
  final DateTime? approvedAt;
  final String? rejectionReason;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<PRItemModel>? items;

  const PurchaseRequisitionModel({
    required this.id,
    required this.prNumber,
    required this.divisionId,
    this.divisionCode,
    this.divisionName,
    required this.processingType,
    required this.requesterId,
    this.requesterName,
    required this.year,
    required this.status,
    this.approvedBy,
    this.approvedByName,
    this.approvedAt,
    this.rejectionReason,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.items,
  });

  factory PurchaseRequisitionModel.fromJson(Map<String, dynamic> json) {
    return PurchaseRequisitionModel(
      id: json['id'] as String,
      prNumber: json['pr_number'] as String,
      divisionId: json['division_id'] as String,
      divisionCode: json['division_code'] as String?,
      divisionName: json['division_name'] as String?,
      processingType: json['processing_type'] as String,
      requesterId: json['requester_id'] as String,
      requesterName: json['requester_name'] as String?,
      year: json['year'] as int,
      status: json['status'] as String,
      approvedBy: json['approved_by'] as String?,
      approvedByName: json['approved_by_name'] as String?,
      approvedAt: json['approved_at'] != null
          ? DateTime.parse(json['approved_at'] as String)
          : null,
      rejectionReason: json['rejection_reason'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      items: json['items'] != null
          ? (json['items'] as List)
              .map((item) => PRItemModel.fromJson(item))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pr_number': prNumber,
      'division_id': divisionId,
      'division_name': divisionName,
      'processing_type': processingType,
      'requester_id': requesterId,
      'requester_name': requesterName,
      'year': year,
      'status': status,
      'approved_by': approvedBy,
      'approved_by_name': approvedByName,
      'approved_at': approvedAt?.toIso8601String(),
      'rejection_reason': rejectionReason,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'items': items?.map((item) => item.toJson()).toList(),
    };
  }

  /// Calculate total from unit_price
  double get totalEstimated {
    if (items == null || items!.isEmpty) return 0;
    return items!.fold(0, (sum, item) => sum + item.subtotal);
  }

  @override
  List<Object?> get props => [
        id,
        prNumber,
        divisionId,
        divisionCode,
        processingType,
        requesterId,
        year,
        status,
        approvedBy,
        approvedAt,
        rejectionReason,
        notes,
        createdAt,
        updatedAt,
        items,
      ];
}

/// PR Item Model with supplier info & unit_price
class PRItemModel extends Equatable {
  final String id;
  final String prId;
  final String productId; 
  final String productCode;
  final String itemName;
  final String categoryId;
  final String categoryName;
  final String supplierId; 
  final String supplierName; 
  final int quantity;
  final String unit;
  final double unitPrice; 
  final double subtotal;
  final String? notes;
  final DateTime createdAt;

  const PRItemModel({
    required this.id,
    required this.prId,
    required this.productId,
    required this.productCode,
    required this.itemName,
    required this.categoryId,
    required this.categoryName,
    required this.supplierId,
    required this.supplierName,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    required this.subtotal,
    this.notes,
    required this.createdAt,
  });

  factory PRItemModel.fromJson(Map<String, dynamic> json) {
    return PRItemModel(
      id: json['id'] as String,
      prId: json['pr_id'] as String,
      productId: json['product_id'] as String,
      productCode: json['product_code'] as String? ?? '',
      itemName: json['item_name'] as String,
      categoryId: json['category_id'] as String,
      categoryName: json['category_name'] as String? ?? '',
      supplierId: json['supplier_id'] as String,
      supplierName: json['supplier_name'] as String? ?? '',
      quantity: json['quantity'] as int,
      unit: json['unit'] as String? ?? 'pcs',
      unitPrice: (json['unit_price'] as num).toDouble(),
      subtotal: (json['subtotal'] as num).toDouble(),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pr_id': prId,
      'product_id': productId,
      'product_code': productCode,
      'item_name': itemName,
      'category_id': categoryId,
      'category_name': categoryName,
      'supplier_id': supplierId,
      'supplier_name': supplierName,
      'quantity': quantity,
      'unit': unit,
      'unit_price': unitPrice,
      'subtotal': subtotal,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        prId,
        productId,
        productCode,
        itemName,
        categoryId,
        supplierId,
        quantity,
        unit,
        unitPrice,
        subtotal,
        notes,
        createdAt,
      ];
}

/// ✅ UPDATED: Create PR Request DTO (Simplified)
class CreatePRRequest {
  final String divisionId;
  final List<CreatePRItemRequest> items;
  final String? notes;

  const CreatePRRequest({
    required this.divisionId,
    required this.items,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'division_id': divisionId,
      'items': items.map((item) => item.toJson()).toList(),
      'notes': notes,
    };
  }
}

class CreatePRItemRequest {
  final String productId; 
  final int quantity; 
  final String? notes;

  const CreatePRItemRequest({
    required this.productId,
    required this.quantity,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'quantity': quantity,
      'notes': notes,
    };
  }
}

class UpdatePRRequest {
  final List<UpdatePRItemRequest> items;
  final String? notes;

  const UpdatePRRequest({
    required this.items,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((item) => item.toJson()).toList(),
      'notes': notes,
    };
  }
}

class UpdatePRItemRequest {
  final String productId; 
  final int quantity; 
  final String? notes;

  const UpdatePRItemRequest({
    required this.productId,
    required this.quantity,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'quantity': quantity,
      'notes': notes,
    };
  }
}
