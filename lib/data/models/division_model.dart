import 'package:equatable/equatable.dart';

/// Division Model
class DivisionModel extends Equatable {
  final String id; // UUID
  final String divisionCode; // "100", "200", "300", etc.
  final String name;
  final String? description;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DivisionModel({
    required this.id,
    required this.divisionCode,
    required this.name,
    this.description,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DivisionModel.fromJson(Map<String, dynamic> json) {
    return DivisionModel(
      id: json['id'] as String,
      divisionCode: json['division_code'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'division_code': divisionCode,
      'name': name,
      'description': description,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Display name with code
  String get displayName => '$divisionCode - $name';

  @override
  List<Object?> get props => [
        id,
        divisionCode,
        name,
        description,
        isActive,
        createdAt,
        updatedAt,
      ];
}
