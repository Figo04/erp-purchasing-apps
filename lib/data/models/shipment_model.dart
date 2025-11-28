import 'package:equatable/equatable.dart';

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

  // Additional fields for display
  final String? poNumber;
  final String? supplierName;
  final List<ShipmentItemModel>? items;

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

  // ✅ FIXED: Changed from 'shipment_item' to 'items'
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
      poNumber: json['po_number'],
      supplierName: json['supplier_name'],
      // ✅ FIXED: Changed from 'shipment_item' to 'items'
      items: json['items'] != null
          ? (json['items'] as List)
              .map((item) => ShipmentItemModel.fromJson(item))
              .toList()
          : null,
    );
  }

  // To JSON (untuk request body)
  Map<String, dynamic> toJson() {
    return {
      'po_id': poId,
      'delivery_note_number': deliveryNoteNumber,
      'notes': notes,
      'items': items?.map((item) => item.toJson()).toList(),
    };
  }

  // Copy with
  ShipmentModel copyWith({
    String? id,
    String? shipmentNumber,
    String? poId,
    String? supplierId,
    String? deliveryNoteNumber,
    DateTime? shipmentDate,
    String? notes,
    String? qrCodeData,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? poNumber,
    String? supplierName,
    List<ShipmentItemModel>? items,
  }) {
    return ShipmentModel(
      id: id ?? this.id,
      shipmentNumber: shipmentNumber ?? this.shipmentNumber,
      poId: poId ?? this.poId,
      supplierId: supplierId ?? this.supplierId,
      deliveryNoteNumber: deliveryNoteNumber ?? this.deliveryNoteNumber,
      shipmentDate: shipmentDate ?? this.shipmentDate,
      notes: notes ?? this.notes,
      qrCodeData: qrCodeData ?? this.qrCodeData,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      poNumber: poNumber ?? this.poNumber,
      supplierName: supplierName ?? this.supplierName,
      items: items ?? this.items,
    );
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
        poNumber,
        supplierName,
        items,
      ];
}

class ShipmentItemModel extends Equatable {
  final String id;
  final String shipmentId;
  final String poItemId;
  final String itemName;
  final int quantityOrdered;
  final int quantityShipped;
  final String unit;
  final String? notes;
  final DateTime createdAt;

  // Additional fields from backend (JOIN)
  final String? productId;
  final String? productCode;
  final String? categoryId;
  final String? categoryName;

  const ShipmentItemModel({
    required this.id,
    required this.shipmentId,
    required this.poItemId,
    required this.itemName,
    required this.quantityOrdered,
    required this.quantityShipped,
    required this.unit,
    this.notes,
    required this.createdAt,
    this.productId,
    this.productCode,
    this.categoryId,
    this.categoryName,
  });

  factory ShipmentItemModel.fromJson(Map<String, dynamic> json) {
    return ShipmentItemModel(
      id: json['id'] as String,
      shipmentId: json['shipment_id'] as String,
      poItemId: json['po_item_id'] as String,
      itemName: json['item_name'] as String,
      quantityOrdered: json['quantity_ordered'] as int,
      quantityShipped: json['quantity_shipped'] as int,
      unit: json['unit'] as String? ?? 'pcs',
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      productId: json['product_id'] as String?,
      productCode: json['product_code'] as String?,
      categoryId: json['category_id'] as String?,
      categoryName: json['category_name'] as String?,
    );
  }

  /// To JSON (untuk request body)
  Map<String, dynamic> toJson() {
    return {
      'po_item_id': poItemId,
      'quantity_shipped': quantityShipped,
      'notes': notes,
    };
  }

  @override
  List<Object?> get props => [
        id,
        shipmentId,
        poItemId,
        itemName,
        quantityOrdered,
        quantityShipped,
        unit,
        notes,
        createdAt,
        productId,
        productCode,
        categoryId,
        categoryName,
      ];
}

/// QR Code Scan Result (dari backend scan-qr endpoint)
class QRScanResult {
  final ShipmentModel? shipment;
  final bool valid;
  final String message;

  QRScanResult({
    this.shipment,
    required this.valid,
    required this.message,
  });

  factory QRScanResult.fromJson(Map<String, dynamic> json) {
    return QRScanResult(
      shipment: json['shipment'] != null
          ? ShipmentModel.fromJson(json['shipment'] as Map<String, dynamic>)
          : null,
      valid: json['valid'] as bool,
      message: json['message'] as String,
    );
  }
}
