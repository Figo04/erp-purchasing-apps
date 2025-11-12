import 'package:equatable/equatable.dart';

/// Category Model
/// Supports hierarchical structure (parent-child)
/// Categories:
/// 1.x = Material (Persediaan)
/// 2.x = Asset (Fix Asset)
/// 3.x = Logistik (Seragam)
/// 4.x = Logistik (Alat Tulis & Cetakan)
class CategoryModel extends Equatable {
  final String id;
  final String? parentId;
  final String code;
  final String name;
  final String? description;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // For tree structure
  final List<CategoryModel>? children;
  final String? parentName;

  const CategoryModel({
    required this.id,
    this.parentId,
    required this.code,
    required this.name,
    this.description,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.children,
    this.parentName,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      parentId: json['parent_id'] as String?,
      code: json['code'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      children: json['children'] != null
          ? (json['children'] as List)
              .map((child) => CategoryModel.fromJson(child))
              .toList()
          : null,
      parentName: json['parent_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'parent_id': parentId,
      'code': code,
      'name': name,
      'description': description,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (children != null)
        'children': children!.map((child) => child.toJson()).toList(),
      if (parentName != null) 'parent_name': parentName,
    };
  }

  /// Check if this is a root category (no parent)
  bool get isRoot => parentId == null;

  /// Check if this category has children
  bool get hasChildren => children != null && children!.isNotEmpty;

  /// Get category type based on code
  String get categoryType {
    if (code.startsWith('1')) return 'Material';
    if (code.startsWith('2')) return 'Asset';
    if (code.startsWith('3')) return 'Logistik - Seragam';
    if (code.startsWith('4')) return 'Logistik - ATK';
    return 'Unknown';
  }

  /// Get full path (for display)
  String getFullPath({String separator = ' > '}) {
    if (parentName != null) {
      return '$parentName$separator$name';
    }
    return name;
  }

  @override
  List<Object?> get props => [
        id,
        parentId,
        code,
        name,
        description,
        isActive,
        createdAt,
        updatedAt,
      ];
}

/// Create Category Request DTO
class CreateCategoryRequest {
  final String? parentId;
  final String code;
  final String name;
  final String? description;
  final bool isActive;

  const CreateCategoryRequest({
    this.parentId,
    required this.code,
    required this.name,
    this.description,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'parent_id': parentId,
      'code': code,
      'name': name,
      'description': description,
      'is_active': isActive,
    };
  }
}

/// Update Category Request DTO
class UpdateCategoryRequest {
  final String? parentId;
  final String code;
  final String name;
  final String? description;
  final bool isActive;

  const UpdateCategoryRequest({
    this.parentId,
    required this.code,
    required this.name,
    this.description,
    required this.isActive,
  });

  Map<String, dynamic> toJson() {
    return {
      'parent_id': parentId,
      'code': code,
      'name': name,
      'description': description,
      'is_active': isActive,
    };
  }
}