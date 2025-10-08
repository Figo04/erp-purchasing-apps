import 'package:equatable/equatable.dart';

class InventoryModel extends Equatable {
  final String id;
  final String? poItemId;
  final String itemName;
  final int quantity;
  final String unit;
  final String? location;
  final String status;
  final DateTime? receivedDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const InventoryModel({
    required this.id,
    this.poItemId,
    required this.itemName,
    required this.quantity,
    required this.unit,
    this.location,
    required this.status,
    this.receivedDate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory InventoryModel.fromJson(Map<String, dynamic> json) {
    return InventoryModel(
      id: json['id'],
      poItemId: json['po_item_id'],
      itemName: json['item_name'],
      quantity: json['quantity'],
      unit: json['unit'] ?? 'pcs',
      location: json['location'],
      status: json['status'],
      receivedDate: json['received_date'] != null
          ? DateTime.parse(json['received_date'])
          : null,
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'po_item_id': poItemId,
      'item_name': itemName,
      'quantity': quantity,
      'unit': unit,
      'location': location,
      'status': status,
      'received_date': receivedDate?.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        poItemId,
        itemName,
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
