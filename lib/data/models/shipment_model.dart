import 'package:equatable/equatable.dart';
import 'dart:convert';

class ShipmentModel extends Equatable {
  final String id;
  final String shipmentNumber;
  final String poId;
  final String supplierId;
  final String deliveryNoteNumber;
  final DateTime shipmentDate;
  final String? notes;
  final String? qrCodeData;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ShipmentItemModel>? items;

  // Additional fields for display
  final String? poNumber;
  final String? supplierName;

  const ShipmentModel({
    required this.id,
    required this.shipmentNumber,
    required this.poId,
    required this.supplierId,
    required this.deliveryNoteNumber,
    required this.shipmentDate,
    this.notes,
    this.qrCodeData,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.items,
    this.poNumber,
    this.supplierName,
  });

  factory ShipmentModel.fromJson(Map<String, dynamic> json) {
    return ShipmentModel(
      id: json['id'],
      shipmentNumber: json['shipment_number'],
      poId: json['po_id'],
      supplierId: json['supplier_id'],
      deliveryNoteNumber: json['delivery_note_number'],
      shipmentDate: DateTime.parse(json['shipment_date']),
      notes: json['notes'],
      qrCodeData: json['qr_code_data'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      items: json['shipment_item'] != null
          ? (json['shipment_item'] as List)
              .map((item) => ShipmentItemModel.fromJson(item))
              .toList()
          : null,
      poNumber: json['po_number'],
      supplierName: json['supplier_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shipment_number': shipmentNumber,
      'po_id': poId,
      'supplier_id': supplierId,
      'delivery_note_number': deliveryNoteNumber,
      'shipment_date': shipmentDate.toIso8601String(),
      'notes': notes,
      'qr_code_data': qrCodeData,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        shipmentNumber,
        poId,
        supplierId,
        deliveryNoteNumber,
        shipmentDate,
        notes,
        qrCodeData,
        status,
        createdAt,
        updatedAt,
        items,
        poNumber,
        supplierName,
      ];
}

class ShipmentItemModel extends Equatable {
  final String id;
  final String shipmentId;
  final String poItemId;
  final String itemName;
  final int quantityShipped;
  final String unit;
  final String? notes;
  final DateTime createdAt;

  const ShipmentItemModel({
    required this.id,
    required this.shipmentId,
    required this.poItemId,
    required this.itemName,
    required this.quantityShipped,
    required this.unit,
    this.notes,
    required this.createdAt,
  });

  factory ShipmentItemModel.fromJson(Map<String, dynamic> json) {
    return ShipmentItemModel(
      id: json['id'],
      shipmentId: json['shipment_id'],
      poItemId: json['po_item_id'],
      itemName: json['item_name'],
      quantityShipped: json['quantity_shipped'],
      unit: json['unit'] ?? 'pcs',
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'shipment_id': shipmentId,
      'po_item_id': poItemId,
      'item_name': itemName,
      'quantity_shipped': quantityShipped,
      'unit': unit,
      'notes': notes,
    };
  }

  @override
  List<Object?> get props => [
        id,
        shipmentId,
        poItemId,
        itemName,
        quantityShipped,
        unit,
        notes,
        createdAt,
      ];
}

// QR Code Data Model (yang di-encode ke QR)
class ShipmentQRData {
  final String shipmentId;
  final String shipmentNumber;
  final String poId;
  final String poNumber;
  final String deliveryNoteNumber;
  final List<ShipmentQRItem> items;

  ShipmentQRData({
    required this.shipmentId,
    required this.shipmentNumber,
    required this.poId,
    required this.poNumber,
    required this.deliveryNoteNumber,
    required this.items,
  });

  // To JSON untuk QR
  Map<String, dynamic> toJson() {
    return {
      'sid': shipmentId,
      'sn': shipmentNumber,
      'pid': poId,
      'pn': poNumber,
      'dn': deliveryNoteNumber,
      'items': items.map((i) => i.toJson()).toList(),
    };
  }

  // From JSON dari scan QR
  factory ShipmentQRData.fromJson(Map<String, dynamic> json) {
    return ShipmentQRData(
      shipmentId: json['sid'] ?? '',
      shipmentNumber: json['sn'] ?? '',
      poId: json['pid'] ?? '',
      poNumber: json['pn'] ?? '',
      deliveryNoteNumber: json['dn'] ?? '',
      items: (json['items'] as List? ?? [])
          .map((i) => ShipmentQRItem.fromJson(i))
          .toList(),
    );
  }

  // Encode ke string untuk QR
  String toQRString() {
    // ✅ ubah Map jadi JSON valid
    final jsonString = jsonEncode(toJson());

    // ✅ encode agar aman dipakai di QR (URL-safe)
    return Uri.encodeComponent(jsonString);
  }
}

class ShipmentQRItem {
  final String poItemId;
  final String name;
  final int qty;
  final String unit;

  ShipmentQRItem({
    required this.poItemId,
    required this.name,
    required this.qty,
    required this.unit,
  });

  Map<String, dynamic> toJson() => {
        'id': poItemId,
        'n': name,
        'q': qty,
        'u': unit,
      };

  factory ShipmentQRItem.fromJson(Map<String, dynamic> json) {
    return ShipmentQRItem(
      poItemId: json['id'],
      name: json['n'],
      qty: json['q'],
      unit: json['u'],
    );
  }
}
