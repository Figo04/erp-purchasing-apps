/// Supplier Assessment Model
/// Represents supplier assessment request for approval before creating master supplier
class SupplierAssessmentModel {
  final String id;
  final String supplierName;
  final String? contactName;
  final String? phone;
  final String? email;
  final String? address;
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

  SupplierAssessmentModel({
    required this.id,
    required this.supplierName,
    this.contactName,
    this.phone,
    this.email,
    this.address,
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

  factory SupplierAssessmentModel.fromJson(Map<String, dynamic> json) {
    return SupplierAssessmentModel(
      id: json['id'] as String,
      supplierName: json['supplier_name'] as String,
      contactName: json['contact_name'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      address: json['address'] as String?,
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
      'supplier_name': supplierName,
      'contact_name': contactName,
      'phone': phone,
      'email': email,
      'address': address,
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

  SupplierAssessmentModel copyWith({
    String? id,
    String? supplierName,
    String? contactName,
    String? phone,
    String? email,
    String? address,
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
    return SupplierAssessmentModel(
      id: id ?? this.id,
      supplierName: supplierName ?? this.supplierName,
      contactName: contactName ?? this.contactName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
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

/// Create Supplier Assessment Request
class CreateSupplierAssessmentRequest {
  final String supplierName;
  final String? contactName;
  final String? phone;
  final String? email;
  final String? address;
  final String? notes;

  CreateSupplierAssessmentRequest({
    required this.supplierName,
    this.contactName,
    this.phone,
    this.email,
    this.address,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'supplier_name': supplierName,
      if (contactName != null) 'contact_name': contactName,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (address != null) 'address': address,
      if (notes != null) 'notes': notes,
    };
  }
}

/// Update Supplier Assessment Request
class UpdateSupplierAssessmentRequest {
  final String supplierName;
  final String? contactName;
  final String? phone;
  final String? email;
  final String? address;
  final String? notes;

  UpdateSupplierAssessmentRequest({
    required this.supplierName,
    this.contactName,
    this.phone,
    this.email,
    this.address,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'supplier_name': supplierName,
      if (contactName != null) 'contact_name': contactName,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (address != null) 'address': address,
      if (notes != null) 'notes': notes,
    };
  }
}

/// Assessment Action Request (for verify/reject)
class SupplierAssessmentActionRequest {
  final String? notes;
  final String? rejectionReason;

  SupplierAssessmentActionRequest({
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