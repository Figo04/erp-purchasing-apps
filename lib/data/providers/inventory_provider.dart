import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/inventory_model.dart';
import '../repositories/inventory_repository.dart';

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return InventoryRepository();
});

final inventoryListProvider = FutureProvider.family<List<InventoryModel>, InventoryFilter>(
  (ref, filter) async {
    final repository = ref.watch(inventoryRepositoryProvider);
    return await repository.getAllInventory(
      productId: filter.productId,
      categoryId: filter.categoryId,
      status: filter.status,
      location: filter.location,
      search: filter.search,
    );
  },
);

final inventoryDetailProvider = FutureProvider.family<InventoryModel?, String>(
  (ref, id) async {
    final repository = ref.watch(inventoryRepositoryProvider);
    return await repository.getInventoryById(id);
  },
);

final lowStockCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(inventoryRepositoryProvider);
  final lowStockItems = await repository.getLowStockItems();
  return lowStockItems.length;
});

final lowStockItemsProvider = FutureProvider<List<InventoryModel>>((ref) async {
  final repository = ref.watch(inventoryRepositoryProvider);
  return await repository.getLowStockItems();
});

final inventoryTransactionProvider = FutureProvider.family<List<InventoryTransactionModel>, String>(
  (ref, inventoryId) async {
    final repository = ref.watch(inventoryRepositoryProvider);
    return await repository.getTransactionHistory(inventoryId);
  },
);

class InventoryFilter {
  final String? productId;
  final String? categoryId;
  final String? status;
  final String? location;
  final String? search;

  const InventoryFilter({
    this.productId,
    this.categoryId,
    this.status,
    this.location,
    this.search,
  });

  static const empty = InventoryFilter();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InventoryFilter &&
        other.productId == productId &&
        other.categoryId == categoryId &&
        other.status == status &&
        other.location == location &&
        other.search == search;
  }

  @override
  int get hashCode => Object.hash(productId, categoryId, status, location, search);

  InventoryFilter copyWith({
    String? productId,
    String? categoryId,
    String? status,
    String? location,
    String? search,
  }) {
    return InventoryFilter(
      productId: productId ?? this.productId,
      categoryId: categoryId ?? this.categoryId,
      status: status ?? this.status,
      location: location ?? this.location,
      search: search ?? this.search,
    );
  }
}

class InventoryFilterNotifier extends StateNotifier<InventoryFilter> {
  InventoryFilterNotifier() : super(InventoryFilter.empty);

  void setFilter(InventoryFilter filter) => state = filter;
  void updateStatus(String? status) => state = state.copyWith(status: status);
  void updateSearch(String? search) => state = state.copyWith(search: search);
  void updateLocation(String? location) => state = state.copyWith(location: location);
  void reset() => state = InventoryFilter.empty;
}

final inventoryFilterProvider = StateNotifierProvider<InventoryFilterNotifier, InventoryFilter>(
  (ref) => InventoryFilterNotifier(),
);

final filteredInventoryListProvider = FutureProvider<List<InventoryModel>>((ref) async {
  final filter = ref.watch(inventoryFilterProvider);
  final repository = ref.watch(inventoryRepositoryProvider);
  
  return await repository.getAllInventory(
    productId: filter.productId,
    categoryId: filter.categoryId,
    status: filter.status,
    location: filter.location,
    search: filter.search,
  );
});