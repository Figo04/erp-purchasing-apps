import 'package:erp_purchasing_apps/data/models/asset_model.dart';
import 'package:erp_purchasing_apps/core/constants/api_constants.dart';
import 'package:erp_purchasing_apps/core/service/api_service.dart';

class AssetRepository {
  final ApiService _apiService = ApiService();

  // ============================================
  // ASSET CRUD (UPDATED)
  // ============================================

  /// GET ALL ASSETS
  Future<List<AssetModel>> getAllAssets({
    String? productId,
    String? categoryId,
    String? assetCategory,
    String? assetType,
    String? status,
    String? sourceType,
    String? divisionId,
    String? assignedTo,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{};

      if (productId != null) queryParams['product_id'] = productId;
      if (categoryId != null) queryParams['category_id'] = categoryId;
      if (assetCategory != null && assetCategory != 'all') {
        queryParams['asset_category'] = assetCategory;
      }
      if (assetType != null && assetType != 'all') {
        queryParams['asset_type'] = assetType;
      }
      if (status != null && status != 'all') queryParams['status'] = status;
      if (sourceType != null && sourceType != 'all') {
        queryParams['source_type'] = sourceType;
      }
      if (divisionId != null) queryParams['division_id'] = divisionId;
      if (assignedTo != null) queryParams['assigned_to'] = assignedTo;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await _apiService.get(
        ApiEndpoints.assets,
        queryParameters: queryParams,
      );

      if (response.data == null) return [];

      final List<dynamic> dataList =
          response.data is List ? response.data as List : [response.data];

      return dataList
          .map((json) => AssetModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load assets: $e');
    }
  }

  /// GET ASSET BY ID
  Future<AssetModel?> getAssetById(String id) async {
    try {
      final response = await _apiService.get(ApiEndpoints.assetById(id));
      if (response.data == null) return null;
      return AssetModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to load asset: $e');
    }
  }

  /// CREATE ASSET (UPDATED)
  Future<AssetModel> createAsset({
    required String assetCode,
    String? productId,
    required String name,
    required String assetCategory,
    required String assetType, // NEW
    required int quantity,
    String? divisionId, // NEW
    double? purchasePrice,
    String? notes,
  }) async {
    try {
      final body = {
        'asset_code': assetCode,
        if (productId != null) 'product_id': productId,
        'name': name,
        'asset_category': assetCategory,
        'asset_type': assetType,
        'quantity': quantity,
        if (divisionId != null) 'division_id': divisionId,
        if (purchasePrice != null) 'purchase_price': purchasePrice,
        if (notes != null) 'notes': notes,
      };

      final response = await _apiService.post(ApiEndpoints.assets, body: body);
      return AssetModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create asset: $e');
    }
  }

  /// UPDATE ASSET (UPDATED)
  Future<AssetModel> updateAsset({
    required String id,
    required String name,
    required String assetCategory,
    required String assetType,
    String? status,
    required int quantity,
    String? divisionId,
    double? purchasePrice,
    String? notes,
  }) async {
    try {
      final body = {
        'name': name,
        'asset_category': assetCategory,
        'asset_type': assetType,
        if (status != null) 'status': status,
        'quantity': quantity,
        if (divisionId != null) 'division_id': divisionId,
        'purchase_price': purchasePrice,
        'notes': notes,
      };

      final response =
          await _apiService.put(ApiEndpoints.assetById(id), body: body);
      return AssetModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update asset: $e');
    }
  }

  /// ASSIGN ASSET TO USER
  Future<AssetModel> assignAsset({
    required String id,
    required String assignedTo,
    String? notes,
  }) async {
    try {
      final body = {
        'assigned_to': assignedTo,
        if (notes != null) 'notes': notes,
      };

      final response = await _apiService.post(
        ApiEndpoints.assignAsset(id),
        body: body,
      );
      return AssetModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to assign asset: $e');
    }
  }

  /// UNASSIGN ASSET (Return)
  Future<AssetModel> unassignAsset({
    required String id,
    String? returnNotes,
  }) async {
    try {
      final current = await getAssetById(id);
      if (current == null) throw Exception('Asset not found');

      final body = {
        'name': current.name,
        'asset_category': current.assetCategory,
        'asset_type': current.assetType,
        'status': 'available',
        'quantity': current.quantity,
        if (current.divisionId != null) 'division_id': current.divisionId,
        'purchase_price': current.purchasePrice,
        'notes': returnNotes != null
            ? '${current.notes ?? ''}\n[RETURNED] ${DateTime.now()}: $returnNotes'
                .trim()
            : current.notes,
      };

      final response =
          await _apiService.put(ApiEndpoints.assetById(id), body: body);
      return AssetModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to return asset: $e');
    }
  }

  /// DELETE ASSET
  Future<void> deleteAsset(String id) async {
    try {
      await _apiService.delete(ApiEndpoints.assetById(id));
    } catch (e) {
      throw Exception('Failed to delete asset: $e');
    }
  }

  /// GET TRANSACTION HISTORY
  Future<List<AssetTransactionModel>> getTransactionHistory(
      String assetId) async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.assetTransactions(assetId),
      );

      if (response.data == null) return [];

      final List<dynamic> dataList =
          response.data is List ? response.data as List : [response.data];

      return dataList
          .map((json) =>
              AssetTransactionModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load transaction history: $e');
    }
  }

  // ============================================
  // LOAN MANAGEMENT (NEW)
  // ============================================

  /// LOAN ASSET (Internal or External)
  Future<AssetLoanHistoryModel> loanAsset({
    required String assetId,
    required String loanType, // 'internal' or 'external'
    required int quantity,
    // For internal loan
    String? toDivisionId,
    String? borrowedBy,
    // For external loan
    String? externalCompanyName,
    String? externalCompanyAddress,
    // Common
    DateTime? expectedReturnDate,
    String? loanDocumentUrl,
    String? notes,
  }) async {
    try {
      final body = {
        'loan_type': loanType,
        'quantity': quantity,
        if (toDivisionId != null) 'to_division_id': toDivisionId,
        if (borrowedBy != null) 'borrowed_by': borrowedBy,
        if (externalCompanyName != null)
          'external_company_name': externalCompanyName,
        if (externalCompanyAddress != null)
          'external_company_address': externalCompanyAddress,
        if (expectedReturnDate != null)
          'expected_return_date': expectedReturnDate.toIso8601String(),
        if (loanDocumentUrl != null) 'loan_document_url': loanDocumentUrl,
        if (notes != null) 'notes': notes,
      };

      final response = await _apiService.post(
        ApiEndpoints.loanAsset(assetId),
        body: body,
      );

      return AssetLoanHistoryModel.fromJson(
          response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to loan asset: $e');
    }
  }

  /// RETURN ASSET
  Future<AssetLoanHistoryModel> returnAsset({
    required String loanHistoryId,
    DateTime? actualReturnDate,
    String? returnDocumentUrl,
    String? notes,
  }) async {
    try {
      final body = {
        'loan_history_id': loanHistoryId,
        if (actualReturnDate != null)
          'actual_return_date': actualReturnDate.toIso8601String(),
        if (returnDocumentUrl != null) 'return_document_url': returnDocumentUrl,
        if (notes != null) 'notes': notes,
      };

      final response = await _apiService.post(
        ApiEndpoints.returnAsset,
        body: body,
      );

      return AssetLoanHistoryModel.fromJson(
          response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to return asset: $e');
    }
  }

  /// GET ASSET LOAN HISTORY
  Future<List<AssetLoanHistoryModel>> getAssetLoanHistory(
      String assetId) async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.assetLoanHistory(assetId),
      );

      if (response.data == null) return [];

      final List<dynamic> dataList =
          response.data is List ? response.data as List : [response.data];

      return dataList
          .map((json) =>
              AssetLoanHistoryModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load loan history: $e');
    }
  }

  /// GET ALL LOAN HISTORY (with filters)
  Future<List<AssetLoanHistoryModel>> getLoanHistory({
    String? assetId,
    String? loanType,
    String? status,
    String? fromDivisionId,
    String? toDivisionId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};

      if (assetId != null) queryParams['asset_id'] = assetId;
      if (loanType != null) queryParams['loan_type'] = loanType;
      if (status != null) queryParams['status'] = status;
      if (fromDivisionId != null) {
        queryParams['from_division_id'] = fromDivisionId;
      }
      if (toDivisionId != null) queryParams['to_division_id'] = toDivisionId;

      final response = await _apiService.get(
        ApiEndpoints.loanHistory,
        queryParameters: queryParams,
      );

      if (response.data == null) return [];

      final List<dynamic> dataList =
          response.data is List ? response.data as List : [response.data];

      return dataList
          .map((json) =>
              AssetLoanHistoryModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load loan history: $e');
    }
  }

  // ============================================
  // EXTERNAL SOURCE METHODS (TAMBAHKAN BAGIAN INI)
  // ============================================

  /// CREATE EXTERNAL SOURCE
  Future<Map<String, dynamic>> createExternalSource(
      Map<String, dynamic> body) async {
    try {
      final response = await _apiService.post(
        ApiEndpoints.externalSources,
        body: body,
      );

      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to create external source: $e');
    }
  }

  /// GET ALL EXTERNAL SOURCES
  Future<List<dynamic>> getAllExternalSources({
    String? sourceType,
    String? divisionId,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (sourceType != null) queryParams['source_type'] = sourceType;
      if (divisionId != null) queryParams['division_id'] = divisionId;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await _apiService.get(
        ApiEndpoints.externalSources,
        queryParameters: queryParams,
      );

      if (response.data == null) return [];
      return response.data is List ? response.data as List : [response.data];
    } catch (e) {
      throw Exception('Failed to load external sources: $e');
    }
  }

  /// GET EXTERNAL SOURCE BY ID
  Future<dynamic> getExternalSourceById(String id) async {
    try {
      final response =
          await _apiService.get(ApiEndpoints.externalSourceById(id));
      if (response.data == null) return null;
      return response.data;
    } catch (e) {
      throw Exception('Failed to load external source: $e');
    }
  }

  /// GET EXTERNAL SOURCE ITEMS
  Future<List<dynamic>> getExternalSourceItems(String sourceId) async {
    try {
      final response =
          await _apiService.get(ApiEndpoints.externalSourceItems(sourceId));
      if (response.data == null) return [];
      return response.data is List ? response.data as List : [response.data];
    } catch (e) {
      throw Exception('Failed to load external source items: $e');
    }
  }

  // ============================================
  // HELPER METHODS
  // ============================================

  /// GET BY CATEGORY
  Future<List<AssetModel>> getAssetsByCategory(String category) async {
    return await getAllAssets(assetCategory: category);
  }

  /// GET BY TYPE (NEW)
  Future<List<AssetModel>> getAssetsByType(String type) async {
    return await getAllAssets(assetType: type);
  }

  /// GET BY STATUS
  Future<List<AssetModel>> getAssetsByStatus(String status) async {
    return await getAllAssets(status: status);
  }

  /// GET BY DIVISION (NEW)
  Future<List<AssetModel>> getAssetsByDivision(String divisionId) async {
    return await getAllAssets(divisionId: divisionId);
  }

  /// GET BY SOURCE TYPE (NEW)
  Future<List<AssetModel>> getAssetsBySource(String sourceType) async {
    return await getAllAssets(sourceType: sourceType);
  }

  /// GET MY ASSIGNED ASSETS
  Future<List<AssetModel>> getMyAssignedAssets(String userId) async {
    return await getAllAssets(assignedTo: userId);
  }

  /// SEARCH ASSETS
  Future<List<AssetModel>> searchAssets(String query) async {
    return await getAllAssets(search: query);
  }

  /// SEARCH BY BEACUKAI
  Future<List<AssetModel>> searchByBeacukai({
    String? beacukaiNo,
    String? beacukaiNoAju,
  }) async {
    try {
      final queryParams = <String, dynamic>{};

      if (beacukaiNo != null) queryParams['beacukai_no'] = beacukaiNo;
      if (beacukaiNoAju != null) queryParams['beacukai_no_aju'] = beacukaiNoAju;

      final response = await _apiService.get(
        ApiEndpoints.assets,
        queryParameters: queryParams,
      );

      if (response.data == null) return [];

      final List<dynamic> dataList =
          response.data is List ? response.data as List : [response.data];

      return dataList
          .map((json) => AssetModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to search assets by beacukai: $e');
    }
  }

  /// UPDATE STATUS ONLY
  Future<AssetModel> updateStatus({
    required String id,
    required String status,
    String? reason,
  }) async {
    try {
      final current = await getAssetById(id);
      if (current == null) throw Exception('Asset not found');

      final notes = reason != null
          ? '${current.notes ?? ''}\n[STATUS CHANGE] ${current.status} → $status: $reason'
              .trim()
          : current.notes;

      return await updateAsset(
        id: id,
        name: current.name,
        assetCategory: current.assetCategory,
        assetType: current.assetType,
        status: status,
        quantity: current.quantity,
        divisionId: current.divisionId,
        purchasePrice: current.purchasePrice,
        notes: notes,
      );
    } catch (e) {
      throw Exception('Failed to update status: $e');
    }
  }

  // ============================================
// ASSET TRANSACTION METHODS (NEW)
// ============================================

  /// CREATE TRANSACTION IN (Purchase / Loan In)
  Future<Map<String, dynamic>> createTransactionIn(
      Map<String, dynamic> body) async {
    try {
      final response = await _apiService.post(
        ApiEndpoints.transactionIn,
        body: body,
      );

      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to create transaction IN: $e');
    }
  }

  /// CREATE TRANSACTION OUT (Sale / Loan Out)
  Future<Map<String, dynamic>> createTransactionOut(
      Map<String, dynamic> body) async {
    try {
      final response = await _apiService.post(
        ApiEndpoints.transactionOut,
        body: body,
      );

      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to create transaction OUT: $e');
    }
  }

  /// CREATE TRANSACTION DISPOSED
  Future<Map<String, dynamic>> createTransactionDisposed(
      Map<String, dynamic> body) async {
    try {
      final response = await _apiService.post(
        ApiEndpoints.transactionDisposed,
        body: body,
      );

      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to dispose asset: $e');
    }
  }

  /// GET TRANSACTION HISTORY FOR ASSET (using new endpoint)
  Future<List<dynamic>> getAssetTransactionHistory(String assetId) async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.assetTransactionHistory(assetId),
      );

      if (response.data == null) return [];
      return response.data is List ? response.data as List : [response.data];
    } catch (e) {
      throw Exception('Failed to load asset transaction history: $e');
    }
  }

  /// GET ALL ASSET TRANSACTIONS (with filters)
  Future<List<dynamic>> getAllAssetTransactions({
    String? assetId,
    String? transactionType,
    String? transactionSubtype,
    String? performedBy,
    String? status,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};

      if (assetId != null) queryParams['asset_id'] = assetId;
      if (transactionType != null)
        queryParams['transaction_type'] = transactionType;
      if (transactionSubtype != null)
        queryParams['transaction_subtype'] = transactionSubtype;
      if (performedBy != null) queryParams['performed_by'] = performedBy;
      if (status != null) queryParams['status'] = status;
      if (fromDate != null)
        queryParams['from_date'] = fromDate.toIso8601String();
      if (toDate != null) queryParams['to_date'] = toDate.toIso8601String();

      final response = await _apiService.get(
        '/asset-transactions',
        queryParameters: queryParams,
      );

      if (response.data == null) return [];
      return response.data is List ? response.data as List : [response.data];
    } catch (e) {
      throw Exception('Failed to load asset transactions: $e');
    }
  }

  /// GET AVAILABLE ASSETS FOR OUT TRANSACTION
  Future<List<AssetModel>> getAvailableAssetsForOut({
    String? transactionSubtype,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (transactionSubtype != null) {
        queryParams['transaction_subtype'] = transactionSubtype;
      }

      final response = await _apiService.get(
        ApiEndpoints.availableAssetsForOut,
        queryParameters: queryParams,
      );

      if (response.data == null) return [];

      final List<dynamic> dataList =
          response.data is List ? response.data as List : [response.data];

      return dataList
          .map((json) => AssetModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load available assets: $e');
    }
  }
}
