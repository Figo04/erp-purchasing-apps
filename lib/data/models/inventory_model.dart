import 'package:equatable/equatable.dart';

/// Inventory Model
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
  });

  /// From JSON (Backend Response)
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
      status: json['status'] as String,
      receivedDate: json['received_date'] != null
          ? DateTime.parse(json['received_date'] as String)
          : null,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// To JSON (untuk request body)
  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'quantity': quantity,
      'location': location,
      'received_date': receivedDate?.toIso8601String(),
      'notes': notes,
    };
  }

  /// Copy with
  InventoryModel copyWith({
    String? id,
    String? productId,
    String? productCode,
    String? itemName,
    String? productName,
    String? categoryId,
    String? categoryName,
    String? poItemId,
    String? lpbItemId,
    int? quantity,
    String? unit,
    String? location,
    String? status,
    DateTime? receivedDate,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InventoryModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productCode: productCode ?? this.productCode,
      itemName: itemName ?? this.itemName,
      productName: productName ?? this.productName,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      poItemId: poItemId ?? this.poItemId,
      lpbItemId: lpbItemId ?? this.lpbItemId,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      location: location ?? this.location,
      status: status ?? this.status,
      receivedDate: receivedDate ?? this.receivedDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Helper: Check if low stock
  bool get isLowStock => quantity < 10 && status == 'available';

  /// Helper: Stock level color indicator
  String get stockLevel {
    if (quantity == 0) return 'critical';
    if (quantity < 10) return 'low';
    if (quantity < 50) return 'medium';
    return 'good';
  }

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
      ];
}

/// Inventory Transaction Model
/// For transaction history
class InventoryTransactionModel extends Equatable {
  final String id;
  final String? inventoryId;
  final String? assetId;
  final String transactionType; // in, out, transfer, adjustment
  final int quantity;
  final String? fromLocation;
  final String? toLocation;
  final String? referenceType; // lpb, po, adjustment, manual
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