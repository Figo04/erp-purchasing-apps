import 'package:equatable/equatable.dart';

// supplier model
class SupplierModel extends Equatable {
  final String id;
  final String supplierCode;
  final String name;
  final String? contactName;
  final String? phone;
  final String? email;
  final String? address;
  final String? authEmail;
  final bool canLogin;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SupplierModel({
    required this.id,
    required this.supplierCode,
    required this.name,
    this.contactName,
    this.phone,
    this.email,
    this.address,
    this.authEmail,
    this.canLogin = false,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SupplierModel.fromJson(Map<String, dynamic> json) {
    return SupplierModel(
      id: json['id'] as String,
      supplierCode: json['supplier_code'] as String,
      name: json['name'] as String,
      contactName: json['contact_name'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      address: json['address'] as String?,
      authEmail: json['auth_email'] as String?,
      canLogin: json['can_login'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'supplier_code': supplierCode,
      'name': name,
      'contact_name': contactName,
      'phone': phone,
      'email': email,
      'address': address,
      'auth_email': authEmail,
      'can_login': canLogin,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Get display name with code
  String get displayName => '[$supplierCode] $name';

  /// Get contact info string
  String get contactInfo {
    final parts = <String>[];
    if (contactName != null) parts.add(contactName!);
    if (phone != null) parts.add(phone!);
    if (email != null) parts.add(email!);
    return parts.join(' • ');
  }

  @override
  List<Object?> get props => [
        id,
        supplierCode,
        name,
        contactName,
        phone,
        email,
        address,
        authEmail,
        canLogin,
        isActive,
        createdAt,
        updatedAt,
      ];
}

/// Create Supplier Request DTO
class CreateSupplierRequest {
  final String supplierCode;
  final String name;
  final String? contactName;
  final String? phone;
  final String? email;
  final String? address;
  final String? authEmail;
  final bool canLogin;

  const CreateSupplierRequest({
    required this.supplierCode,
    required this.name,
    this.contactName,
    this.phone,
    this.email,
    this.address,
    this.authEmail,
    this.canLogin = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'supplier_code': supplierCode,
      'name': name,
      'contact_name': contactName,
      'phone': phone,
      'email': email,
      'address': address,
      'auth_email': authEmail,
      'can_login': canLogin,
    };
  }
}

/// Update Supplier Request DTO
class UpdateSupplierRequest {
  final String supplierCode;
  final String name;
  final String? contactName;
  final String? phone;
  final String? email;
  final String? address;
  final String? authEmail;
  final bool canLogin;
  final bool isActive;

  const UpdateSupplierRequest({
    required this.supplierCode,
    required this.name,
    this.contactName,
    this.phone,
    this.email,
    this.address,
    this.authEmail,
    required this.canLogin,
    required this.isActive,
  });

  Map<String, dynamic> toJson() {
    return {
      'supplier_code': supplierCode,
      'name': name,
      'contact_name': contactName,
      'phone': phone,
      'email': email,
      'address': address,
      'auth_email': authEmail,
      'can_login': canLogin,
      'is_active': isActive,
    };
  }
}