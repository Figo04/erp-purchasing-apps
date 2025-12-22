import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/asset_model.dart';
import '../repositories/asset_repository.dart';

// REPOSITORY PROVIDER
final assetRepositoryProvider = Provider<AssetRepository>((ref) {
  return AssetRepository();
});

// ASSET LIST PROVIDER
final assetListProvider =
    FutureProvider.family<List<AssetModel>, AssetFilter>((ref, filter) async {
  final repository = ref.watch(assetRepositoryProvider);
  return await repository.getAllAssets(
    productId: filter.productId,
    categoryId: filter.categoryId,
    assetCategory: filter.assetCategory,
    assetType: filter.assetType,
    status: filter.status,
    sourceType: filter.sourceType,
    divisionId: filter.divisionId,
    assignedTo: filter.assignedTo,
    search: filter.search,
  );
});

// ASSET DETAIL PROVIDER
final assetDetailProvider =
    FutureProvider.family<AssetModel?, String>((ref, id) async {
  final repository = ref.watch(assetRepositoryProvider);
  return await repository.getAssetById(id);
});

// BORROWED ASSETS COUNT PROVIDER
final borrowedAssetsCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(assetRepositoryProvider);
  final borrowedAssets = await repository.getAssetsByStatus('borrowed');
  return borrowedAssets.length;
});

// LENT ASSETS COUNT PROVIDER (NEW)
final lentAssetsCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(assetRepositoryProvider);
  final lentAssets = await repository.getAssetsByStatus('lent');
  return lentAssets.length;
});

// ASSETS BY CATEGORY PROVIDER
final assetsByCategoryProvider = FutureProvider<Map<String, int>>((ref) async {
  final repository = ref.watch(assetRepositoryProvider);
  final allAssets = await repository.getAllAssets();

  return {
    'loanable': allAssets.where((a) => a.assetCategory == 'loanable').length,
    'saleable': allAssets.where((a) => a.assetCategory == 'saleable').length,
    'pending': allAssets.where((a) => a.assetCategory == 'pending').length,
    'disposed': allAssets.where((a) => a.assetCategory == 'disposed').length,
  };
});

// ASSETS BY TYPE PROVIDER (NEW)
final assetsByTypeProvider = FutureProvider<Map<String, int>>((ref) async {
  final repository = ref.watch(assetRepositoryProvider);
  final allAssets = await repository.getAllAssets();

  return {
    'mesin': allAssets.where((a) => a.assetType == 'mesin').length,
    'sparepart': allAssets.where((a) => a.assetType == 'sparepart').length,
  };
});

// MY ASSIGNED ASSETS PROVIDER
final myAssignedAssetsProvider =
    FutureProvider.family<List<AssetModel>, String>((ref, userId) async {
  final repository = ref.watch(assetRepositoryProvider);
  return await repository.getMyAssignedAssets(userId);
});

// ASSET TRANSACTION PROVIDER
final assetTransactionProvider =
    FutureProvider.family<List<AssetTransactionModel>, String>(
        (ref, assetId) async {
  final repository = ref.watch(assetRepositoryProvider);
  return await repository.getTransactionHistory(assetId);
});

// ASSET LOAN HISTORY PROVIDER (NEW)
final assetLoanHistoryProvider =
    FutureProvider.family<List<AssetLoanHistoryModel>, String>(
        (ref, assetId) async {
  final repository = ref.watch(assetRepositoryProvider);
  return await repository.getAssetLoanHistory(assetId);
});

// ALL LOAN HISTORY PROVIDER (NEW)
final allLoanHistoryProvider =
    FutureProvider.family<List<AssetLoanHistoryModel>, LoanHistoryFilter>(
        (ref, filter) async {
  final repository = ref.watch(assetRepositoryProvider);
  return await repository.getLoanHistory(
    assetId: filter.assetId,
    loanType: filter.loanType,
    status: filter.status,
    fromDivisionId: filter.fromDivisionId,
    toDivisionId: filter.toDivisionId,
  );
});

// ONGOING LOANS COUNT PROVIDER (NEW)
final ongoingLoansCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(assetRepositoryProvider);
  final loans = await repository.getLoanHistory(status: 'ongoing');
  return loans.length;
});

// OVERDUE LOANS COUNT PROVIDER (NEW)
final overdueLoansCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(assetRepositoryProvider);
  final loans = await repository.getLoanHistory(status: 'overdue');
  return loans.length;
});

// ASSET FILTER CLASS (UPDATED)
class AssetFilter {
  final String? productId;
  final String? categoryId;
  final String? assetCategory;
  final String? assetType; // NEW
  final String? status;
  final String? sourceType; // NEW
  final String? divisionId; // NEW
  final String? assignedTo;
  final String? search;

  const AssetFilter({
    this.productId,
    this.categoryId,
    this.assetCategory,
    this.assetType,
    this.status,
    this.sourceType,
    this.divisionId,
    this.assignedTo,
    this.search,
  });

  static const empty = AssetFilter();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AssetFilter &&
        other.productId == productId &&
        other.categoryId == categoryId &&
        other.assetCategory == assetCategory &&
        other.assetType == assetType &&
        other.status == status &&
        other.sourceType == sourceType &&
        other.divisionId == divisionId &&
        other.assignedTo == assignedTo &&
        other.search == search;
  }

  @override
  int get hashCode => Object.hash(
        productId,
        categoryId,
        assetCategory,
        assetType,
        status,
        sourceType,
        divisionId,
        assignedTo,
        search,
      );

  AssetFilter copyWith({
    String? productId,
    String? categoryId,
    String? assetCategory,
    String? assetType,
    String? status,
    String? sourceType,
    String? divisionId,
    String? assignedTo,
    String? search,
  }) {
    return AssetFilter(
      productId: productId ?? this.productId,
      categoryId: categoryId ?? this.categoryId,
      assetCategory: assetCategory ?? this.assetCategory,
      assetType: assetType ?? this.assetType,
      status: status ?? this.status,
      sourceType: sourceType ?? this.sourceType,
      divisionId: divisionId ?? this.divisionId,
      assignedTo: assignedTo ?? this.assignedTo,
      search: search ?? this.search,
    );
  }
}

// LOAN HISTORY FILTER CLASS (NEW)
class LoanHistoryFilter {
  final String? assetId;
  final String? loanType;
  final String? status;
  final String? fromDivisionId;
  final String? toDivisionId;

  const LoanHistoryFilter({
    this.assetId,
    this.loanType,
    this.status,
    this.fromDivisionId,
    this.toDivisionId,
  });

  static const empty = LoanHistoryFilter();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LoanHistoryFilter &&
        other.assetId == assetId &&
        other.loanType == loanType &&
        other.status == status &&
        other.fromDivisionId == fromDivisionId &&
        other.toDivisionId == toDivisionId;
  }

  @override
  int get hashCode => Object.hash(
        assetId,
        loanType,
        status,
        fromDivisionId,
        toDivisionId,
      );
}

// STATE NOTIFIER FOR FILTER MANAGEMENT (UPDATED)
class AssetFilterNotifier extends StateNotifier<AssetFilter> {
  AssetFilterNotifier() : super(AssetFilter.empty);

  void setFilter(AssetFilter filter) => state = filter;

  void updateCategory(String? category) {
    state = state.copyWith(assetCategory: category);
  }

  void updateAssetType(String? type) {
    state = state.copyWith(assetType: type);
  }

  void updateStatus(String? status) {
    state = state.copyWith(status: status);
  }

  void updateSourceType(String? sourceType) {
    state = state.copyWith(sourceType: sourceType);
  }

  void updateDivision(String? divisionId) {
    state = state.copyWith(divisionId: divisionId);
  }

  void updateSearch(String? search) {
    state = state.copyWith(search: search);
  }

  void reset() => state = AssetFilter.empty;
}

final assetFilterProvider =
    StateNotifierProvider<AssetFilterNotifier, AssetFilter>(
  (ref) => AssetFilterNotifier(),
);

// FILTERED ASSET LIST PROVIDER
final filteredAssetListProvider = FutureProvider<List<AssetModel>>((ref) async {
  final filter = ref.watch(assetFilterProvider);
  final repository = ref.watch(assetRepositoryProvider);

  return await repository.getAllAssets(
    productId: filter.productId,
    categoryId: filter.categoryId,
    assetCategory: filter.assetCategory,
    assetType: filter.assetType,
    status: filter.status,
    sourceType: filter.sourceType,
    divisionId: filter.divisionId,
    assignedTo: filter.assignedTo,
    search: filter.search,
  );
});

/// Beacukai Search Filter for Assets
class BeacukaiAssetFilter {
  final String? beacukaiNo;
  final String? beacukaiNoAju;

  const BeacukaiAssetFilter({
    this.beacukaiNo,
    this.beacukaiNoAju,
  });

  static const empty = BeacukaiAssetFilter();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BeacukaiAssetFilter &&
        other.beacukaiNo == beacukaiNo &&
        other.beacukaiNoAju == beacukaiNoAju;
  }

  @override
  int get hashCode => Object.hash(beacukaiNo, beacukaiNoAju);
}

/// Search Assets by Beacukai Provider
final searchAssetsByBeacukaiProvider =
    FutureProvider.family<List<AssetModel>, BeacukaiAssetFilter>(
        (ref, filter) async {
  final repository = ref.watch(assetRepositoryProvider);
  return await repository.searchByBeacukai(
    beacukaiNo: filter.beacukaiNo,
    beacukaiNoAju: filter.beacukaiNoAju,
  );
});

/// Count assets with beacukai
final assetsWithBeacukaiCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(assetRepositoryProvider);
  final allAssets = await repository.getAllAssets();
  return allAssets.where((asset) => asset.hasBeacukai).length;
});
