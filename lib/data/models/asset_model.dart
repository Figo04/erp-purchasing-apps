import 'package:equatable/equatable.dart';

class AssetModel extends Equatable {
  final String id;
  final String assetCode;
  final String? productId;
  final String? productCode;
  final String name;
  final String categoryId;
  final String? categoryName;
  final String assetCategory; // consumable, loanable, saleable
  final String status; // available, borrowed, disposed, maintenance
  final int quantity;
  final double? purchasePrice;
  final String? assignedTo;
  final String? assignedToName;
  final DateTime? assignedDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AssetModel({
    required this.id,
    required this.assetCode,
    this.productId,
    this.productCode,
    required this.name,
    required this.categoryId,
    this.categoryName,
    required this.assetCategory,
    required this.status,
    required this.quantity,
    this.purchasePrice,
    this.assignedTo,
    this.assignedToName,
    this.assignedDate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// From JSON (Backend Response)
  factory AssetModel.fromJson(Map<String, dynamic> json) {
    return AssetModel(
      id: json['id'] as String,
      assetCode: json['asset_code'] as String,
      productId: json['product_id'] as String?,
      productCode: json['product_code'] as String?,
      name: json['name'] as String,
      categoryId: json['category_id'] as String,
      categoryName: json['category_name'] as String?,
      assetCategory: json['asset_category'] as String? ?? 'loanable',
      status: json['status'] as String? ?? 'available',
      quantity: json['quantity'] as int? ?? 1,
      purchasePrice: json['purchase_price'] != null
          ? double.parse(json['purchase_price'].toString())
          : null,
      assignedTo: json['assigned_to'] as String?,
      assignedToName: json['assigned_to_name'] as String?,
      assignedDate: json['assigned_date'] != null
          ? DateTime.parse(json['assigned_date'] as String)
          : null,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// To JSON (untuk request body)
  Map<String, dynamic> toJson() {
    return {
      'asset_code': assetCode,
      'product_id': productId,
      'name': name,
      'asset_category': assetCategory,
      'quantity': quantity,
      'purchase_price': purchasePrice,
      'notes': notes,
    };
  }

  /// Copy with
  AssetModel copyWith({
    String? id,
    String? assetCode,
    String? productId,
    String? productCode,
    String? name,
    String? categoryId,
    String? categoryName,
    String? assetCategory,
    String? status,
    int? quantity,
    double? purchasePrice,
    String? assignedTo,
    String? assignedToName,
    DateTime? assignedDate,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AssetModel(
      id: id ?? this.id,
      assetCode: assetCode ?? this.assetCode,
      productId: productId ?? this.productId,
      productCode: productCode ?? this.productCode,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      assetCategory: assetCategory ?? this.assetCategory,
      status: status ?? this.status,
      quantity: quantity ?? this.quantity,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedToName: assignedToName ?? this.assignedToName,
      assignedDate: assignedDate ?? this.assignedDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Helper: Check if asset is borrowed
  bool get isBorrowed => status == 'borrowed';

  /// Helper: Check if asset is available
  bool get isAvailable => status == 'available';

  /// Helper: Category display name
  String get categoryDisplayName {
    switch (assetCategory) {
      case 'consumable':
        return 'Consumable';
      case 'loanable':
        return 'Loanable';
      case 'saleable':
        return 'Saleable';
      default:
        return assetCategory;
    }
  }

  /// Helper: Status display name
  String get statusDisplayName {
    switch (status) {
      case 'available':
        return 'Available';
      case 'borrowed':
        return 'Borrowed';
      case 'disposed':
        return 'Disposed';
      case 'maintenance':
        return 'Maintenance';
      default:
        return status;
    }
  }

  @override
  List<Object?> get props => [
        id,
        assetCode,
        productId,
        productCode,
        name,
        categoryId,
        categoryName,
        assetCategory,
        status,
        quantity,
        purchasePrice,
        assignedTo,
        assignedToName,
        assignedDate,
        notes,
        createdAt,
        updatedAt,
      ];
}

/// Asset Transaction Model
/// For transaction history (shared with Inventory)
class AssetTransactionModel extends Equatable {
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

  const AssetTransactionModel({
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

  factory AssetTransactionModel.fromJson(Map<String, dynamic> json) {
    return AssetTransactionModel(
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