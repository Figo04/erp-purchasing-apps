import 'package:equatable/equatable.dart';

// ============================================
// DOCUMENT TRACKING
// ============================================

class DocumentTracking extends Equatable {
  final String id;
  final String? prId;
  final String? poId;
  final String? shipmentId;
  final String? lpbId;
  final String documentType; // pr, po, shipment, lpb
  final String documentNumber;
  final String currentStatus;
  final String? previousStatus;
  final String changedBy;
  final String? changedByName;
  final DateTime changedAt;
  final String? notes;
  final DateTime createdAt;

  const DocumentTracking({
    required this.id,
    this.prId,
    this.poId,
    this.shipmentId,
    this.lpbId,
    required this.documentType,
    required this.documentNumber,
    required this.currentStatus,
    this.previousStatus,
    required this.changedBy,
    this.changedByName,
    required this.changedAt,
    this.notes,
    required this.createdAt,
  });

  factory DocumentTracking.fromJson(Map<String, dynamic> json) {
    return DocumentTracking(
      id: json['id'] ?? '',
      prId: json['pr_id'],
      poId: json['po_id'],
      shipmentId: json['shipment_id'],
      lpbId: json['lpb_id'],
      documentType: json['document_type'] ?? '',
      documentNumber: json['document_number'] ?? '',
      currentStatus: json['current_status'] ?? '',
      previousStatus: json['previous_status'],
      changedBy: json['changed_by'] ?? '',
      changedByName: json['changed_by_name'],
      changedAt: DateTime.parse(json['changed_at']),
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  @override
  List<Object?> get props => [id, documentNumber, currentStatus, changedAt];
}

// ============================================
// TRACKING TIMELINE (Helper)
// ============================================

class TrackingTimeline extends Equatable {
  final String stage;
  final String documentNumber;
  final String status;
  final DateTime changedAt;
  final String changedByName;

  const TrackingTimeline({
    required this.stage,
    required this.documentNumber,
    required this.status,
    required this.changedAt,
    required this.changedByName,
  });

  factory TrackingTimeline.fromJson(Map<String, dynamic> json) {
    return TrackingTimeline(
      stage: json['stage'] ?? '',
      documentNumber: json['document_number'] ?? '',
      status: json['status'] ?? '',
      changedAt: DateTime.parse(json['changed_at']),
      changedByName: json['changed_by_name'] ?? '',
    );
  }

  @override
  List<Object?> get props => [stage, documentNumber, changedAt];
}

// ============================================
// ACTIVITY LOG
// ============================================

class ActivityLog extends Equatable {
  final String id;
  final String userId;
  final String userEmail;
  final String userRole;
  final String action; // create, update, delete, approve, reject
  final String entityType; // pr, po, product, supplier
  final String? entityId;
  final String? entityName;
  final String? description;
  final Map<String, dynamic>? oldData;
  final Map<String, dynamic>? newData;
  final String? ipAddress;
  final String? userAgent;
  final DateTime createdAt;

  const ActivityLog({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.userRole,
    required this.action,
    required this.entityType,
    this.entityId,
    this.entityName,
    this.description,
    this.oldData,
    this.newData,
    this.ipAddress,
    this.userAgent,
    required this.createdAt,
  });

  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    return ActivityLog(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      userEmail: json['user_email'] ?? '',
      userRole: json['user_role'] ?? '',
      action: json['action'] ?? '',
      entityType: json['entity_type'] ?? '',
      entityId: json['entity_id'],
      entityName: json['entity_name'],
      description: json['description'],
      oldData: json['old_data'] != null 
          ? Map<String, dynamic>.from(json['old_data'])
          : null,
      newData: json['new_data'] != null
          ? Map<String, dynamic>.from(json['new_data'])
          : null,
      ipAddress: json['ip_address'],
      userAgent: json['user_agent'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  @override
  List<Object?> get props => [id, userId, action, entityType, createdAt];
}

// ============================================
// ITEM TRACKING
// ============================================

class ItemTracking extends Equatable {
  final String id;
  final String? prItemId;
  final String? poItemId;
  final String? shipmentItemId;
  final String? lpbItemId;
  final String? inventoryId;
  final String? assetId;
  final String? productId;
  final String? productCode;
  final String itemName;
  final String categoryId;
  final String? categoryName;
  final int? quantityRequested;
  final int? quantityOrdered;
  final int? quantityShipped;
  final int? quantityReceived;
  final int? quantityInStock;
  final String unit;
  final String currentStage; // requested, ordered, shipped, received, in_stock
  final bool isComplete;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ItemTracking({
    required this.id,
    this.prItemId,
    this.poItemId,
    this.shipmentItemId,
    this.lpbItemId,
    this.inventoryId,
    this.assetId,
    this.productId,
    this.productCode,
    required this.itemName,
    required this.categoryId,
    this.categoryName,
    this.quantityRequested,
    this.quantityOrdered,
    this.quantityShipped,
    this.quantityReceived,
    this.quantityInStock,
    required this.unit,
    required this.currentStage,
    required this.isComplete,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ItemTracking.fromJson(Map<String, dynamic> json) {
    return ItemTracking(
      id: json['id'] ?? '',
      prItemId: json['pr_item_id'],
      poItemId: json['po_item_id'],
      shipmentItemId: json['shipment_item_id'],
      lpbItemId: json['lpb_item_id'],
      inventoryId: json['inventory_id'],
      assetId: json['asset_id'],
      productId: json['product_id'],
      productCode: json['product_code'],
      itemName: json['item_name'] ?? '',
      categoryId: json['category_id'] ?? '',
      categoryName: json['category_name'],
      quantityRequested: json['quantity_requested'],
      quantityOrdered: json['quantity_ordered'],
      quantityShipped: json['quantity_shipped'],
      quantityReceived: json['quantity_received'],
      quantityInStock: json['quantity_in_stock'],
      unit: json['unit'] ?? '',
      currentStage: json['current_stage'] ?? '',
      isComplete: json['is_complete'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  @override
  List<Object?> get props => [id, itemName, currentStage, isComplete];
}

// ============================================
// PURCHASE FLOW SUMMARY
// ============================================

class PurchaseFlowSummary extends Equatable {
  final String prId;
  final String prNumber;
  final String divisionId;
  final String divisionCode;
  final String divisionName;
  final String processingType;
  final String prStatus;
  final DateTime prCreatedAt;
  final String? poId;
  final String? poNumber;
  final String? poStatus;
  final String? shipmentStatus;
  final DateTime? poCreatedAt;
  final String? shipmentId;
  final String? shipmentNumber;
  final String? shipmentStatusField;
  final DateTime? shipmentCreatedAt;
  final String? lpbId;
  final String? lpbNumber;
  final String? lpbStatus;
  final String? paymentStatus;
  final DateTime? lpbCreatedAt;
  final double? daysSincePR;
  final String overallStatus;

  const PurchaseFlowSummary({
    required this.prId,
    required this.prNumber,
    required this.divisionId,
    required this.divisionCode,
    required this.divisionName,
    required this.processingType,
    required this.prStatus,
    required this.prCreatedAt,
    this.poId,
    this.poNumber,
    this.poStatus,
    this.shipmentStatus,
    this.poCreatedAt,
    this.shipmentId,
    this.shipmentNumber,
    this.shipmentStatusField,
    this.shipmentCreatedAt,
    this.lpbId,
    this.lpbNumber,
    this.lpbStatus,
    this.paymentStatus,
    this.lpbCreatedAt,
    this.daysSincePR,
    required this.overallStatus,
  });

  factory PurchaseFlowSummary.fromJson(Map<String, dynamic> json) {
    return PurchaseFlowSummary(
      prId: json['pr_id'] ?? '',
      prNumber: json['pr_number'] ?? '',
      divisionId: json['division_id'] ?? '',
      divisionCode: json['division_code'] ?? '',
      divisionName: json['division_name'] ?? '',
      processingType: json['processing_type'] ?? '',
      prStatus: json['pr_status'] ?? '',
      prCreatedAt: DateTime.parse(json['pr_created_at']),
      poId: json['po_id'],
      poNumber: json['po_number'],
      poStatus: json['po_status'],
      shipmentStatus: json['shipment_status'],
      poCreatedAt: json['po_created_at'] != null
          ? DateTime.parse(json['po_created_at'])
          : null,
      shipmentId: json['shipment_id'],
      shipmentNumber: json['shipment_number'],
      shipmentStatusField: json['shipment_status_field'],
      shipmentCreatedAt: json['shipment_created_at'] != null
          ? DateTime.parse(json['shipment_created_at'])
          : null,
      lpbId: json['lpb_id'],
      lpbNumber: json['lpb_number'],
      lpbStatus: json['lpb_status'],
      paymentStatus: json['payment_status'],
      lpbCreatedAt: json['lpb_created_at'] != null
          ? DateTime.parse(json['lpb_created_at'])
          : null,
      daysSincePR: json['days_since_pr']?.toDouble(),
      overallStatus: json['overall_status'] ?? '',
    );
  }

  @override
  List<Object?> get props => [prId, prNumber, overallStatus];
}