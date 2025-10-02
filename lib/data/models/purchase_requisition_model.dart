import 'package:equatable/equatable.dart';

class PurchaseRequisitionModel extends Equatable {
  final String id;
  final String prNumber;
  final String requesterId;
  final String status;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? rejectionReason;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<PRItemModel>? items;

  const PurchaseRequisitionModel({
    required this.id,
    required this.prNumber,
    required this.requesterId,
    required this.status,
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.items,
  });

  factory PurchaseRequisitionModel.fromJson(Map<String, dynamic> json) {
    return PurchaseRequisitionModel(
      id: json['id'],
      prNumber: json['pr_number'],
      requesterId: json['requester_id'],
      status: json['status'],
      approvedBy: json['approved_by'],
      approvedAt: json['approved_at'] != null
          ? DateTime.parse(json['approved_at'])
          : null,
      rejectionReason: json['rejection_reason'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      items: json['purchase_requisition_item'] != null
          ? (json['purchase_requisition_item'] as List)
              .map((item) => PRItemModel.fromJson(item))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pr_number': prNumber,
      'requester_id': requesterId,
      'status': status,
      'approved_by': approvedBy,
      'approved_at': approvedAt?.toIso8601String(),
      'rejection_reason': rejectionReason,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

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
        requesterId,
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

class PRItemModel extends Equatable {
  final String id;
  final String prId;
  final String itemName;
  final int quantity;
  final String unit;
  final double? estimatedPrice;
  final String? notes;
  final DateTime createdAt;

  const PRItemModel({
    required this.id,
    required this.prId,
    required this.itemName,
    required this.quantity,
    required this.unit,
    this.estimatedPrice,
    this.notes,
    required this.createdAt,
  });

  factory PRItemModel.fromJson(Map<String, dynamic> json) {
    return PRItemModel(
      id: json['id'],
      prId: json['pr_id'],
      itemName: json['item_name'],
      quantity: json['quantity'],
      unit: json['unit'] ?? 'pcs',
      estimatedPrice: json['estimated_price']?.toDouble(),
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pr_id': prId,
      'item_name': itemName,
      'quantity': quantity,
      'unit': unit,
      'estimated_price': estimatedPrice,
      'notes': notes,
    };
  }

  double get subtotal => (estimatedPrice ?? 0) * quantity;

  @override
  List<Object?> get props => [
        id,
        prId,
        itemName,
        quantity,
        unit,
        estimatedPrice,
        notes,
        createdAt,
      ];
}