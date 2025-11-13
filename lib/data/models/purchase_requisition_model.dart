import 'package:equatable/equatable.dart';

/// Purchase Requisition Model 
class PurchaseRequisitionModel extends Equatable {
  final String id;
  final String prNumber;
  final String divisionId;
  final String? divisionName;
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

  /// Calculate total estimated cost
  double get totalEstimated {
    if (items == null || items!.isEmpty) return 0;
    return items!.fold(0, (sum, item) {
      return sum + ((item.estimatedPrice ?? 0) * item.quantity);
    });
  }

  @override
  List<Object?> get props => [
        id,
        prNumber,
        divisionId,
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

/// PR Item Model
class PRItemModel extends Equatable {
  final String id;
  final String prId;
  final String? productId;
  final String itemName;
  final int quantity;
  final String unit;
  final double? estimatedPrice;
  final String? notes;
  final DateTime createdAt;

  const PRItemModel({
    required this.id,
    required this.prId,
    this.productId,
    required this.itemName,
    required this.quantity,
    required this.unit,
    this.estimatedPrice,
    this.notes,
    required this.createdAt,
  });

  factory PRItemModel.fromJson(Map<String, dynamic> json) {
    return PRItemModel(
      id: json['id'] as String,
      prId: json['pr_id'] as String,
      productId: json['product_id'] as String?,
      itemName: json['item_name'] as String,
      quantity: json['quantity'] as int,
      unit: json['unit'] as String? ?? 'pcs',
      estimatedPrice: json['estimated_price'] != null
          ? (json['estimated_price'] as num).toDouble()
          : null,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pr_id': prId,
      'product_id': productId,
      'item_name': itemName,
      'quantity': quantity,
      'unit': unit,
      'estimated_price': estimatedPrice,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  double get subtotal => (estimatedPrice ?? 0) * quantity;

  @override
  List<Object?> get props => [
        id,
        prId,
        productId,
        itemName,
        quantity,
        unit,
        estimatedPrice,
        notes,
        createdAt,
      ];
}

/// Create PR Request DTO
class CreatePRRequest {
  final String divisionId;
  final String processingType;
  final List<CreatePRItemRequest> items;
  final String? notes;

  const CreatePRRequest({
    required this.divisionId,
    required this.processingType,
    required this.items,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'division_id': divisionId,
      'processing_type': processingType,
      'items': items.map((item) => item.toJson()).toList(),
      'notes': notes,
    };
  }
}

/// Create PR Item Request DTO
class CreatePRItemRequest {
  final String? productId;
  final String itemName;
  final int quantity;
  final String unit;
  final double? estimatedPrice;
  final String? notes;

  const CreatePRItemRequest({
    this.productId,
    required this.itemName,
    required this.quantity,
    required this.unit,
    this.estimatedPrice,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'item_name': itemName,
      'quantity': quantity,
      'unit': unit,
      'estimated_price': estimatedPrice,
      'notes': notes,
    };
  }
}

/// Update PR Request DTO
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

/// Update PR Item Request DTO
class UpdatePRItemRequest {
  final String? productId;
  final String itemName;
  final int quantity;
  final String unit;
  final double? estimatedPrice;
  final String? notes;

  const UpdatePRItemRequest({
    this.productId,
    required this.itemName,
    required this.quantity,
    required this.unit,
    this.estimatedPrice,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'item_name': itemName,
      'quantity': quantity,
      'unit': unit,
      'estimated_price': estimatedPrice,
      'notes': notes,
    };
  }
}