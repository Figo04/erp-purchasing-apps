// supplier_model.dart
import 'package:equatable/equatable.dart';

class SupplierModel extends Equatable {
  final String id;
  final String name;
  final String? contactName;
  final String? phone;
  final String? email;
  final String? address;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? authEmail;    
  final bool canLogin;        

  const SupplierModel({
    required this.id,
    required this.name,
    this.contactName,
    this.phone,
    this.email,
    this.address,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.authEmail,
    this.canLogin = false,
  });

  factory SupplierModel.fromJson(Map<String, dynamic> json) {
    return SupplierModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      address: json['address'],
      contactName: json['contact_name'],
      phone: json['phone'],
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      authEmail: json['auth_email'],        
      canLogin: json['can_login'] ?? false, 
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'address': address,
      'contact_name': contactName,
      'phone': phone,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'auth_email': authEmail,      
      'can_login': canLogin,         
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        address,
        contactName,
        phone,
        isActive,
        createdAt,
        updatedAt,
        authEmail,    
        canLogin,     
      ];
}