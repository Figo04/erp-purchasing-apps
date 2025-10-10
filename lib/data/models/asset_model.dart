import 'package:equatable/equatable.dart';

class AssetModel extends Equatable {
  final String id;
  final String assetCode;
  final String name;
  final String category; // consumable, loanable, saleable
  final String status; // available, borrowed, disposed, maintenance
  final int quantity;
  final double? purchasePrice;
  final String? assignedTo; // user_id
  final String? assignedToName; // user full_name (dari join)
  final DateTime? assignedDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AssetModel({
    required this.id,
    required this.assetCode,
    required this.name,
    required this.category,
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

  factory AssetModel.fromJson(Map<String, dynamic> json) {
    return AssetModel(
      id: json['id'],
      assetCode: json['asset_code'],
      name: json['name'],
      category: json['category'] ?? 'consumable',
      status: json['status'] ?? 'available',
      quantity: json['quantity'] ?? 1,
      purchasePrice: json['purchase_price'] != null
          ? double.parse(json['purchase_price'].toString())
          : null,
      assignedTo: json['assigned_to'],
      assignedToName: json['assigned_to_name'], // dari join query
      assignedDate: json['assigned_date'] != null
          ? DateTime.parse(json['assigned_date'])
          : null,
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'asset_code': assetCode,
      'name': name,
      'category': category,
      'status': status,
      'quantity': quantity,
      'purchase_price': purchasePrice,
      'assigned_to': assignedTo,
      'assigned_date': assignedDate?.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  AssetModel copyWith({
    String? id,
    String? assetCode,
    String? name,
    String? category,
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
      name: name ?? this.name,
      category: category ?? this.category,
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

  @override
  List<Object?> get props => [
        id,
        assetCode,
        name,
        category,
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