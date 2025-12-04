import 'package:equatable/equatable.dart';

class InventoryModel extends Equatable {
  final String id;
  final String productId;
  final String? productCode;
  final String itemName;
  final String? productName;
  final String categoryId;
  final String? categoryName;
  final String? poItemId;
  final String? lpbItemId;
  final int quantity;
  final String unit;
  final String? location;
  final String status; // available, reserved, damaged, disposed
  final DateTime? receivedDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // ✅ BEACUKAI FIELDS (NEW)
  final String? beacukaiDoc;
  final DateTime? beacukaiTgl;
  final String? beacukaiNo;
  final String? beacukaiNoAju;
  final String? lpbId;

  const InventoryModel({
    required this.id,
    required this.productId,
    this.productCode,
    required this.itemName,
    this.productName,
    required this.categoryId,
    this.categoryName,
    this.poItemId,
    this.lpbItemId,
    required this.quantity,
    required this.unit,
    this.location,
    required this.status,
    this.receivedDate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.beacukaiDoc,
    this.beacukaiTgl,
    this.beacukaiNo,
    this.beacukaiNoAju,
    this.lpbId,
  });

  factory InventoryModel.fromJson(Map<String, dynamic> json) {
    return InventoryModel(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      productCode: json['product_code'] as String?,
      itemName: json['item_name'] as String,
      productName: json['product_name'] as String?,
      categoryId: json['category_id'] as String,
      categoryName: json['category_name'] as String?,
      poItemId: json['po_item_id'] as String?,
      lpbItemId: json['lpb_item_id'] as String?,
      quantity: json['quantity'] as int,
      unit: json['unit'] as String? ?? 'pcs',
      location: json['location'] as String?,
      status: json['status'] as String? ?? 'available',
      receivedDate: json['received_date'] != null
          ? DateTime.parse(json['received_date'] as String)
          : null,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      // ✅ BEACUKAI FIELDS
      beacukaiDoc: json['beacukai_doc'] as String?,
      beacukaiTgl: json['beacukai_tgl'] != null
          ? DateTime.parse(json['beacukai_tgl'] as String)
          : null,
      beacukaiNo: json['beacukai_no'] as String?,
      beacukaiNoAju: json['beacukai_no_aju'] as String?,
      lpbId: json['lpb_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'quantity': quantity,
      'location': location,
      'received_date': receivedDate?.toIso8601String(),
      'notes': notes,
    };
  }

  /// Helper: Check if has beacukai
  bool get hasBeacukai => beacukaiNo != null && beacukaiNo!.isNotEmpty;

  @override
  List<Object?> get props => [
        id,
        productId,
        productCode,
        itemName,
        productName,
        categoryId,
        categoryName,
        poItemId,
        lpbItemId,
        quantity,
        unit,
        location,
        status,
        receivedDate,
        notes,
        createdAt,
        updatedAt,
        beacukaiDoc,
        beacukaiTgl,
        beacukaiNo,
        beacukaiNoAju,
        lpbId,
      ];
}

class InventoryTransactionModel extends Equatable {
  final String id;
  final String? inventoryId;
  final String? assetId;
  final String transactionType; // in, out, transfer, adjustment
  final int quantity;
  final String? fromLocation;
  final String? toLocation;
  final String? referenceType;
  final String? referenceId;
  final String performedBy;
  final String? performedByName;
  final String? notes;
  final DateTime createdAt;

  const InventoryTransactionModel({
    required this.id,
    this.inventoryId,
    this.assetId,
    required this.transactionType,
    required this.quantity,
    this.fromLocation,
    this.toLocation,
    this.referenceType,
    this.referenceId,
    required this.performedBy,
    this.performedByName,
    this.notes,
    required this.createdAt,
  });

  factory InventoryTransactionModel.fromJson(Map<String, dynamic> json) {
    return InventoryTransactionModel(
      id: json['id'] as String,
      inventoryId: json['inventory_id'] as String?,
      assetId: json['asset_id'] as String?,
      transactionType: json['transaction_type'] as String,
      quantity: json['quantity'] as int,
      fromLocation: json['from_location'] as String?,
      toLocation: json['to_location'] as String?,
      referenceType: json['reference_type'] as String?,
      referenceId: json['reference_id'] as String?,
      performedBy: json['performed_by'] as String,
      performedByName: json['performed_by_name'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  @override
  List<Object?> get props => [
        id,
        inventoryId,
        assetId,
        transactionType,
        quantity,
        fromLocation,
        toLocation,
        referenceType,
        referenceId,
        performedBy,
        performedByName,
        notes,
        createdAt,
      ];
}