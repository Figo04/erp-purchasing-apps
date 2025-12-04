import 'package:equatable/equatable.dart';

class ShipmentModel extends Equatable {
  final String id;
  final String shipmentNumber;
  final String poId;
  final String? poNumber;
  final String supplierId;
  final String? supplierName;
  final String deliveryNoteNumber;
  final DateTime shipmentDate;
  final String? qrCodeData;
  final String status; // pending, received, partial
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? invoiceNumber;
  final double? invoiceAmount;

  // ✅ BEACUKAI FIELDS (NEW)
  final String? beacukaiDoc;
  final DateTime? beacukaiTgl;
  final String? beacukaiNo;
  final String? beacukaiNoAju;

  final List<ShipmentItemModel>? items;

  const ShipmentModel({
    required this.id,
    required this.shipmentNumber,
    required this.poId,
    this.poNumber,
    required this.supplierId,
    this.supplierName,
    required this.deliveryNoteNumber,
    required this.shipmentDate,
    this.qrCodeData,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.invoiceNumber,
    this.invoiceAmount,
    this.beacukaiDoc,
    this.beacukaiTgl,
    this.beacukaiNo,
    this.beacukaiNoAju,
    this.items,
  });

  factory ShipmentModel.fromJson(Map<String, dynamic> json) {
    return ShipmentModel(
      id: json['id'] as String,
      shipmentNumber: json['shipment_number'] as String,
      poId: json['po_id'] as String,
      poNumber: json['po_number'] as String?,
      supplierId: json['supplier_id'] as String,
      supplierName: json['supplier_name'] as String?,
      deliveryNoteNumber: json['delivery_note_number'] as String,
      shipmentDate: DateTime.parse(json['shipment_date'] as String),
      qrCodeData: json['qr_code_data'] as String?,
      status: json['status'] as String,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      invoiceNumber: json['invoice_number'] as String?,
      invoiceAmount: json['invoice_amount'] != null
          ? (json['invoice_amount'] as num).toDouble()
          : null,
      // ✅ BEACUKAI FIELDS
      beacukaiDoc: json['beacukai_doc'] as String?,
      beacukaiTgl: json['beacukai_tgl'] != null
          ? DateTime.parse(json['beacukai_tgl'] as String)
          : null,
      beacukaiNo: json['beacukai_no'] as String?,
      beacukaiNoAju: json['beacukai_no_aju'] as String?,
      items: json['items'] != null
          ? (json['items'] as List)
              .map((item) =>
                  ShipmentItemModel.fromJson(item as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'po_id': poId,
      'delivery_note_number': deliveryNoteNumber,
      'shipment_date': shipmentDate.toIso8601String(),
      'invoice_number': invoiceNumber,
      'invoice_amount': invoiceAmount,
      'notes': notes,
      // ✅ BEACUKAI FIELDS
      'beacukai_doc': beacukaiDoc,
      'beacukai_tgl': beacukaiTgl?.toIso8601String(),
      'beacukai_no': beacukaiNo,
      'beacukai_no_aju': beacukaiNoAju,
      'items': items?.map((item) => item.toJson()).toList(),
    };
  }

  /// Helper: Check if has beacukai
  bool get hasBeacukai => beacukaiNo != null && beacukaiNo!.isNotEmpty;

  @override
  List<Object?> get props => [
        id,
        shipmentNumber,
        poId,
        poNumber,
        supplierId,
        supplierName,
        deliveryNoteNumber,
        shipmentDate,
        qrCodeData,
        status,
        notes,
        createdAt,
        updatedAt,
        invoiceNumber,
        invoiceAmount,
        beacukaiDoc,
        beacukaiTgl,
        beacukaiNo,
        beacukaiNoAju,
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
