import 'package:equatable/equatable.dart';

/// Product Model - WITH SUPPLIER & PRICE
class ProductModel extends Equatable {
  final String id;
  final String productCode;
  final String name;
  final String categoryId;
  final String? categoryName;
  final String supplierId;
  final String? supplierCode;
  final String? supplierName;
  final String? divisionId;
  final String? divisionCode;
  final String? divisionName;

  final double unitPrice;

  final String unit;
  final String? description;
  final String? specifications;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProductModel({
    required this.id,
    required this.productCode,
    required this.name,
    required this.categoryId,
    this.categoryName,
    required this.supplierId,
    this.supplierCode,
    this.supplierName,
    this.divisionId,
    this.divisionCode,
    this.divisionName,
    required this.unitPrice,
    required this.unit,
    this.description,
    this.specifications,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      productCode: json['product_code'] as String,
      name: json['name'] as String,
      categoryId: json['category_id'] as String,
      categoryName: json['category_name'] as String?,
      supplierId: json['supplier_id'] as String,
      supplierCode: json['supplier_code'] as String?,
      supplierName: json['supplier_name'] as String?,
      divisionId: json['division_id'] as String?,
      divisionCode: json['division_code'] as String?,
      divisionName: json['division_name'] as String?,
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] as String? ?? 'pcs',
      description: json['description'] as String?,
      specifications: json['specifications'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_code': productCode,
      'name': name,
      'category_id': categoryId,
      'category_name': categoryName,
      'supplier_id': supplierId,
      'supplier_code': supplierCode,
      'supplier_name': supplierName,
      'division_id': divisionId,
      'division_code': divisionCode,
      'division_name': divisionName,
      'unit_price': unitPrice,
      'unit': unit,
      'description': description,
      'specifications': specifications,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Get display name with code
  String get displayName => '[$productCode] $name';

  /// Get display name with supplier
  String get displayNameWithSupplier =>
      '[$productCode] $name - ${supplierName ?? "Unknown Supplier"}';

  /// Get product type based on category
  String get productType {
    if (categoryName != null) {
      if (categoryName!.contains('Material')) return 'Material';
      if (categoryName!.contains('Asset')) return 'Asset';
      if (categoryName!.contains('Logistik')) return 'Logistik';
    }
    return 'Unknown';
  }

  /// Format price
  String get formattedPrice => 'Rp ${unitPrice.toStringAsFixed(0)}';

  @override
  List<Object?> get props => [
        id,
        productCode,
        name,
        categoryId,
        categoryName,
        supplierId,
        supplierCode,
        supplierName,
        divisionId,
        divisionCode,
        divisionName,
        unitPrice,
        unit,
        description,
        specifications,
        isActive,
        createdAt,
        updatedAt,
      ];
}

/// Create Product Request DTO - WITH SUPPLIER & PRICE
class CreateProductRequest {
  final String productCode;
  final String name;
  final String categoryId;
  final String supplierId;
  final String? divisionId;
  final double unitPrice;
  final String unit;
  final String? description;
  final String? specifications;

  const CreateProductRequest({
    required this.productCode,
    required this.name,
    required this.categoryId,
    required this.supplierId,
    this.divisionId,
    required this.unitPrice,
    this.unit = 'pcs',
    this.description,
    this.specifications,
  });

  Map<String, dynamic> toJson() {
    return {
      'product_code': productCode,
      'name': name,
      'category_id': categoryId,
      'supplier_id': supplierId,
      'division_id': divisionId,
      'unit_price': unitPrice,
      'unit': unit,
      'description': description,
      'specifications': specifications,
    };
  }
}

/// Update Product Request DTO - WITH SUPPLIER & PRICE
class UpdateProductRequest {
  final String name;
  final String categoryId;
  final String supplierId;
  final String? divisionId;
  final double unitPrice;
  final String unit;
  final String? description;
  final String? specifications;
  final bool isActive;

  const UpdateProductRequest({
    required this.name,
    required this.categoryId,
    required this.supplierId,
    this.divisionId,
    required this.unitPrice,
    required this.unit,
    this.description,
    this.specifications,
    required this.isActive,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category_id': categoryId,
      'supplier_id': supplierId,
      'division_id': divisionId,
      'unit_price': unitPrice,
      'unit': unit,
      'description': description,
      'specifications': specifications,
      'is_active': isActive,
    };
  }
}

/// Common unit types
class ProductUnits {
  static const String pcs = 'pcs';
  static const String kg = 'kg';
  static const String liter = 'liter';
  static const String meter = 'meter';
  static const String box = 'box';
  static const String set = 'set';
  static const String unit = 'unit';
  static const String roll = 'roll';
  static const String sheet = 'sheet';
  static const String pack = 'pack';

  static List<String> get all => [
        pcs,
        kg,
        liter,
        meter,
        box,
        set,
        unit,
        roll,
        sheet,
        pack,
      ];
}
