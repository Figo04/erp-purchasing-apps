import 'package:erp_purchasing_apps/data/models/division_model.dart';
import 'package:erp_purchasing_apps/core/service/api_service.dart';
import 'package:erp_purchasing_apps/core/constants/api_constants.dart';

/// Division Repository
class DivisionRepository {
  final ApiService _apiService;

  DivisionRepository({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  /// Get all divisions
  Future<List<DivisionModel>> getAllDivisions({
    bool? isActive,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (isActive != null) {
        queryParams['is_active'] = isActive.toString();
      }

      final response = await _apiService.get(
        ApiEndpoints.divisions,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
        fromJson: (json) {
          if (json is List) {
            return json
                .map((item) => DivisionModel.fromJson(item))
                .toList();
          }
          return <DivisionModel>[];
        },
      );

      if (!response.isSuccess || response.data == null) {
        throw Exception(response.errorMessage);
      }

      return response.data as List<DivisionModel>;
    } catch (e) {
      throw Exception('Failed to load divisions: $e');
    }
  }

  /// Get division by ID
  Future<DivisionModel> getDivisionById(String id) async {
    try {
      final response = await _apiService.get<DivisionModel>(
        ApiEndpoints.divisionById(id),
        fromJson: (json) => DivisionModel.fromJson(json),
      );

      if (!response.isSuccess || response.data == null) {
        throw Exception(response.errorMessage);
      }

      return response.data!;
    } catch (e) {
      throw Exception('Failed to load division: $e');
    }
  }

  /// Get division by code (helper method)
  Future<DivisionModel?> getDivisionByCode(String code) async {
    try {
      final divisions = await getAllDivisions();
      return divisions.firstWhere(
        (div) => div.divisionCode == code,
        orElse: () => throw Exception('Division not found'),
      );
    } catch (e) {
      return null;
    }
  }
}