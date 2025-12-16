class ProductAssessmentModel {
  final String id;
  final String productName;
  final String categoryId;
  final String? categoryName;
  final String unit;
  final String? description;
  final String? specifications;
  final String supplierId;
  final String? supplierName;
  final double unitPrice;
  final String requesterId;
  final String? requesterName;
  final String status; // pending, verified, approved, rejected
  final String? verifiedBy;
  final String? verifiedByName;
  final DateTime? verifiedAt;
  final String? approvedBy;
  final String? approvedByName;
  final DateTime? approvedAt;
  final String? rejectionReason;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProductAssessmentModel({
    required this.id,
    required this.productName,
    required this.categoryId,
    this.categoryName,
    required this.unit,
    this.description,
    this.specifications,
    required this.supplierId,
    this.supplierName,
    required this.unitPrice,
    required this.requesterId,
    this.requesterName,
    required this.status,
    this.verifiedBy,
    this.verifiedByName,
    this.verifiedAt,
    this.approvedBy,
    this.approvedByName,
    this.approvedAt,
    this.rejectionReason,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProductAssessmentModel.fromJson(Map<String, dynamic> json) {
    return ProductAssessmentModel(
      id: json['id'] as String,
      productName: json['product_name'] as String,
      categoryId: json['category_id'] as String,
      categoryName: json['category_name'] as String?,
      unit: json['unit'] as String? ?? 'pcs',
      description: json['description'] as String?,
      specifications: json['specifications'] as String?,
      supplierId: json['supplier_id'] as String,
      supplierName: json['supplier_name'] as String?,
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0.0,
      requesterId: json['requester_id'] as String,
      requesterName: json['requester_name'] as String?,
      status: json['status'] as String? ?? 'pending',
      verifiedBy: json['verified_by'] as String?,
      verifiedByName: json['verified_by_name'] as String?,
      verifiedAt: json['verified_at'] != null
          ? DateTime.parse(json['verified_at'] as String)
          : null,
      approvedBy: json['approved_by'] as String?,
      approvedByName: json['approved_by_name'] as String?,
      approvedAt: json['approved_at'] != null
          ? DateTime.parse(json['approved_at'] as String)
          : null,
      rejectionReason: json['rejection_reason'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_name': productName,
      'category_id': categoryId,
      'category_name': categoryName,
      'unit': unit,
      'description': description,
      'specifications': specifications,
      'supplier_id': supplierId,
      'supplier_name': supplierName,
      'unit_price': unitPrice,
      'requester_id': requesterId,
      'requester_name': requesterName,
      'status': status,
      'verified_by': verifiedBy,
      'verified_by_name': verifiedByName,
      'verified_at': verifiedAt?.toIso8601String(),
      'approved_by': approvedBy,
      'approved_by_name': approvedByName,
      'approved_at': approvedAt?.toIso8601String(),
      'rejection_reason': rejectionReason,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Status helpers
  bool get isPending => status == 'pending';
  bool get isVerified => status == 'verified';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  String get formattedPrice => 'Rp ${unitPrice.toStringAsFixed(0)}';

  ProductAssessmentModel copyWith({
    String? id,
    String? productName,
    String? categoryId,
    String? categoryName,
    String? unit,
    String? description,
    String? specifications,
    String? supplierId,        
    String? supplierName,      
    double? unitPrice,
    String? requesterId,
    String? requesterName,
    String? status,
    String? verifiedBy,
    String? verifiedByName,
    DateTime? verifiedAt,
    String? approvedBy,
    String? approvedByName,
    DateTime? approvedAt,
    String? rejectionReason,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductAssessmentModel(
      id: id ?? this.id,
      productName: productName ?? this.productName,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      unit: unit ?? this.unit,
      description: description ?? this.description,
      specifications: specifications ?? this.specifications,
      supplierId: supplierId ?? this.supplierId,           
      supplierName: supplierName ?? this.supplierName,     
      unitPrice: unitPrice ?? this.unitPrice,              
      requesterId: requesterId ?? this.requesterId,
      requesterName: requesterName ?? this.requesterName,
      status: status ?? this.status,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      verifiedByName: verifiedByName ?? this.verifiedByName,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedByName: approvedByName ?? this.approvedByName,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Create Product Assessment Request
class CreateProductAssessmentRequest {
  final String productName;
  final String categoryId;
  final String supplierId;    
  final double unitPrice;     
  final String unit;
  final String? description;
  final String? specifications;
  final String? notes;

  CreateProductAssessmentRequest({
    required this.productName,
    required this.categoryId,
    required this.supplierId,      
    required this.unitPrice,       
    this.unit = 'pcs',
    this.description,
    this.specifications,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'product_name': productName,
      'category_id': categoryId,
      'supplier_id': supplierId,    
      'unit_price': unitPrice,      
      'unit': unit,
      if (description != null) 'description': description,
      if (specifications != null) 'specifications': specifications,
      if (notes != null) 'notes': notes,
    };
  }
}


/// Update Product Assessment Request
class UpdateProductAssessmentRequest {
  final String productName;
  final String categoryId;
  final String unit;
  final String? description;
  final String? specifications;
  final String? notes;

  UpdateProductAssessmentRequest({
    required this.productName,
    required this.categoryId,
    required this.unit,
    this.description,
    this.specifications,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'product_name': productName,
      'category_id': categoryId,
      'unit': unit,
      if (description != null) 'description': description,
      if (specifications != null) 'specifications': specifications,
      if (notes != null) 'notes': notes,
    };
  }
}

/// Verify/Reject Request 
class AssessmentActionRequest {
  final String? notes;
  final String? rejectionReason;

  AssessmentActionRequest({
    this.notes,
    this.rejectionReason,
  });

  Map<String, dynamic> toJson() {
    return {
      if (notes != null) 'notes': notes,
      if (rejectionReason != null) 'rejection_reason': rejectionReason,
    };
  }
}
