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
    ownership: filter.ownership, // ✅ CHANGED
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

// ✅ UPDATED: Assets by ownership (milik_sendiri, milik_customer)
final assetsByOwnershipProvider = FutureProvider<Map<String, int>>((ref) async {
  final repository = ref.watch(assetRepositoryProvider);
  final allAssets = await repository.getAllAssets();

  return {
    'milik_sendiri': allAssets.where((a) => a.ownership == 'milik_sendiri').length,
    'milik_customer': allAssets.where((a) => a.ownership == 'milik_customer').length,
  };
});

// ASSETS BY TYPE PROVIDER - TETAP
final assetsByTypeProvider = FutureProvider<Map<String, int>>((ref) async {
  final repository = ref.watch(assetRepositoryProvider);
  final allAssets = await repository.getAllAssets();

  return {
    'mesin': allAssets.where((a) => a.assetType == 'mesin').length,
    'sparepart': allAssets.where((a) => a.assetType == 'sparepart').length,
  };
});

// ✅ UPDATED: Assets by status
final assetsByStatusProvider = FutureProvider<Map<String, int>>((ref) async {
  final repository = ref.watch(assetRepositoryProvider);
  final allAssets = await repository.getAllAssets();

  return {
    'available': allAssets.where((a) => a.status == 'available').length,
    'saleable': allAssets.where((a) => a.status == 'saleable').length,
    'loanable': allAssets.where((a) => a.status == 'loanable').length,
    'disposed': allAssets.where((a) => a.status == 'disposed').length,
    'borrowed': allAssets.where((a) => a.status == 'borrowed').length,
    'lent': allAssets.where((a) => a.status == 'lent').length,
    'sold': allAssets.where((a) => a.status == 'sold').length,
    'returned': allAssets.where((a) => a.status == 'returned').length,
  };
});

// Borrowed/Lent counts - TETAP
final borrowedAssetsCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(assetRepositoryProvider);
  final borrowedAssets = await repository.getAssetsByStatus('borrowed');
  return borrowedAssets.length;
});

final lentAssetsCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(assetRepositoryProvider);
  final lentAssets = await repository.getAssetsByStatus('lent');
  return lentAssets.length;
});

// MY ASSIGNED ASSETS PROVIDER - TETAP
final myAssignedAssetsProvider =
    FutureProvider.family<List<AssetModel>, String>((ref, userId) async {
  final repository = ref.watch(assetRepositoryProvider);
  return await repository.getMyAssignedAssets(userId);
});

// ASSET TRANSACTION PROVIDER - TETAP
final assetTransactionProvider =
    FutureProvider.family<List<AssetTransactionModel>, String>(
        (ref, assetId) async {
  final repository = ref.watch(assetRepositoryProvider);
  return await repository.getTransactionHistory(assetId);
});

// ASSET LOAN HISTORY PROVIDER - TETAP
final assetLoanHistoryProvider =
    FutureProvider.family<List<AssetLoanHistoryModel>, String>(
        (ref, assetId) async {
  final repository = ref.watch(assetRepositoryProvider);
  return await repository.getAssetLoanHistory(assetId);
});

// ALL LOAN HISTORY PROVIDER - TETAP
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

final ongoingLoansCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(assetRepositoryProvider);
  final loans = await repository.getLoanHistory(status: 'ongoing');
  return loans.length;
});

final overdueLoansCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(assetRepositoryProvider);
  final loans = await repository.getLoanHistory(status: 'overdue');
  return loans.length;
});

// ✅ UPDATED: ASSET FILTER CLASS
class AssetFilter {
  final String? productId;
  final String? categoryId;
  final String? ownership; // ✅ CHANGED dari assetCategory
  final String? assetType;
  final String? status;
  final String? sourceType;
  final String? divisionId;
  final String? assignedTo;
  final String? search;

  const AssetFilter({
    this.productId,
    this.categoryId,
    this.ownership, // ✅ CHANGED
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
        other.ownership == ownership && // ✅ CHANGED
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
        ownership, // ✅ CHANGED
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
    String? ownership, // ✅ CHANGED
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
      ownership: ownership ?? this.ownership, // ✅ CHANGED
      assetType: assetType ?? this.assetType,
      status: status ?? this.status,
      sourceType: sourceType ?? this.sourceType,
      divisionId: divisionId ?? this.divisionId,
      assignedTo: assignedTo ?? this.assignedTo,
      search: search ?? this.search,
    );
  }
}

// LOAN HISTORY FILTER CLASS - TETAP
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

// ✅ UPDATED: STATE NOTIFIER FOR FILTER MANAGEMENT
class AssetFilterNotifier extends StateNotifier<AssetFilter> {
  AssetFilterNotifier() : super(AssetFilter.empty);

  void setFilter(AssetFilter filter) => state = filter;

  void updateOwnership(String? ownership) { // ✅ CHANGED
    state = state.copyWith(ownership: ownership);
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

  void resetAssetType() {
    state = state.copyWith(assetType: null);
  }

  void resetOwnership() { // ✅ CHANGED
    state = state.copyWith(ownership: null);
  }

  void resetStatus() {
    state = state.copyWith(status: null);
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

  final effectiveFilter = AssetFilter(
    productId: filter.productId,
    categoryId: filter.categoryId,
    ownership: filter.ownership, // ✅ CHANGED
    assetType: filter.assetType,
    status: filter.status,
    sourceType: filter.sourceType,
    divisionId: filter.divisionId,
    assignedTo: filter.assignedTo,
    search: filter.search,
  );

  return await repository.getAllAssets(
    productId: effectiveFilter.productId,
    categoryId: effectiveFilter.categoryId,
    ownership: effectiveFilter.ownership, // ✅ CHANGED
    assetType: effectiveFilter.assetType,
    status: effectiveFilter.status,
    sourceType: effectiveFilter.sourceType,
    divisionId: effectiveFilter.divisionId,
    assignedTo: effectiveFilter.assignedTo,
    search: effectiveFilter.search,
  );
});

/// Beacukai Search Filter - TETAP
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

final searchAssetsByBeacukaiProvider =
    FutureProvider.family<List<AssetModel>, BeacukaiAssetFilter>(
        (ref, filter) async {
  final repository = ref.watch(assetRepositoryProvider);
  return await repository.searchByBeacukai(
    beacukaiNo: filter.beacukaiNo,
    beacukaiNoAju: filter.beacukaiNoAju,
  );
});

final assetsWithBeacukaiCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(assetRepositoryProvider);
  final allAssets = await repository.getAllAssets();
  return allAssets.where((asset) => asset.hasBeacukaiIn).length;
});