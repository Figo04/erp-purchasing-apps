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
    status: filter.status,
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

// ASSETS BY CATEGORY PROVIDER
final assetsByCategoryProvider =
    FutureProvider<Map<String, int>>((ref) async {
  final repository = ref.watch(assetRepositoryProvider);
  final allAssets = await repository.getAllAssets();

  return {
    'consumable':
        allAssets.where((a) => a.assetCategory == 'consumable').length,
    'loanable': allAssets.where((a) => a.assetCategory == 'loanable').length,
    'saleable': allAssets.where((a) => a.assetCategory == 'saleable').length,
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

// ASSET FILTER CLASS
class AssetFilter {
  final String? productId;
  final String? categoryId;
  final String? assetCategory;
  final String? status;
  final String? assignedTo;
  final String? search;

  const AssetFilter({
    this.productId,
    this.categoryId,
    this.assetCategory,
    this.status,
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
        other.status == status &&
        other.assignedTo == assignedTo &&
        other.search == search;
  }

  @override
  int get hashCode => Object.hash(
        productId,
        categoryId,
        assetCategory,
        status,
        assignedTo,
        search,
      );

  AssetFilter copyWith({
    String? productId,
    String? categoryId,
    String? assetCategory,
    String? status,
    String? assignedTo,
    String? search,
  }) {
    return AssetFilter(
      productId: productId ?? this.productId,
      categoryId: categoryId ?? this.categoryId,
      assetCategory: assetCategory ?? this.assetCategory,
      status: status ?? this.status,
      assignedTo: assignedTo ?? this.assignedTo,
      search: search ?? this.search,
    );
  }
}

// STATE NOTIFIER FOR FILTER MANAGEMENT
class AssetFilterNotifier extends StateNotifier<AssetFilter> {
  AssetFilterNotifier() : super(AssetFilter.empty);

  void setFilter(AssetFilter filter) => state = filter;
  void updateCategory(String? category) =>
      state = state.copyWith(assetCategory: category);
  void updateStatus(String? status) => state = state.copyWith(status: status);
  void updateSearch(String? search) => state = state.copyWith(search: search);
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
    status: filter.status,
    assignedTo: filter.assignedTo,
    search: filter.search,
  );
});