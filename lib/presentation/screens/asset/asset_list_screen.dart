import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:erp_purchasing_apps/data/providers/asset_provider.dart';
import 'package:erp_purchasing_apps/data/providers/auth_providers.dart';
import 'package:erp_purchasing_apps/presentation/screens/asset/asset_detail_screen.dart';
import 'package:intl/intl.dart';

class AssetListScreen extends ConsumerStatefulWidget {
  const AssetListScreen({super.key});

  @override
  ConsumerState<AssetListScreen> createState() => _AssetListScreenState();
}

class _AssetListScreenState extends ConsumerState<AssetListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'consumable':
        return Colors.blue;
      case 'loanable':
        return Colors.purple;
      case 'saleable':
        return Colors.green;
      case 'pending':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'available':
        return Colors.green;
      case 'borrowed':
        return Colors.orange;
      case 'disposed':
        return Colors.grey;
      case 'maintenance':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'consumable':
        return Icons.inventory_2;
      case 'loanable':
        return Icons.devices;
      case 'saleable':
        return Icons.shopping_bag;
      case 'pending':
        return Icons.help_outline;
      default:
        return Icons.category;
    }
  }

  void _refreshAssets() {
    ref.invalidate(filteredAssetListProvider);
    ref.invalidate(borrowedAssetsCountProvider);
    ref.invalidate(assetsByCategoryProvider); // ✅ Refresh category counts
  }

  @override
  Widget build(BuildContext context) {
    final assetAsync = ref.watch(filteredAssetListProvider);
    final borrowedCountAsync = ref.watch(borrowedAssetsCountProvider);
    final categoryCounts =
        ref.watch(assetsByCategoryProvider); // ✅ Watch all assets count
    final currentUser = ref.watch(currentUserProvider);
    final canManage =
        currentUser?.role == 'admin' || currentUser?.role == 'warehouse';

    // ✅ Watch filter state from provider
    final filterState = ref.watch(assetFilterProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
        title: const Text('Assets Management'),
        actions: [
          borrowedCountAsync.when(
            data: (count) {
              if (count > 0) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Center(
                    child: Chip(
                      label: Text(
                        'Borrowed: $count',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.white),
                      ),
                      backgroundColor: Colors.orange,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: assetAsync.when(
                data: (_) => const Icon(Icons.cloud_done, color: Colors.green),
                loading: () => const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (_, __) =>
                    const Icon(Icons.cloud_off, color: Colors.red),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshAssets,
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _refreshAssets();
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search asset name or code...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  suffixIcon: filterState.search != null
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            ref
                                .read(assetFilterProvider.notifier)
                                .updateSearch(null);
                          },
                        )
                      : null,
                ),
                onChanged: (value) {
                  ref
                      .read(assetFilterProvider.notifier)
                      .updateSearch(value.isEmpty ? null : value);
                },
              ),
            ),

            // Category Filter (STATUS 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: categoryCounts.when(
                  data: (counts) {
                    // ✅ Calculate total from category counts
                    final total =
                        counts.values.fold<int>(0, (sum, count) => sum + count);
                    final pendingCount = counts['pending'] ?? 0;
                    final consumableCount = counts['consumable'] ?? 0;
                    final loanableCount = counts['loanable'] ?? 0;
                    final saleableCount = counts['saleable'] ?? 0;

                    return Row(
                      children: [
                        _buildCategoryChip(
                            'all', 'All', total, filterState.assetCategory),
                        const SizedBox(width: 8),
                        if (pendingCount > 0) ...[
                          _buildCategoryChip('pending', '⚠️ Pending',
                              pendingCount, filterState.assetCategory,
                              isWarning: true),
                          const SizedBox(width: 8),
                        ],
                        _buildCategoryChip('consumable', 'Consumable',
                            consumableCount, filterState.assetCategory),
                        const SizedBox(width: 8),
                        _buildCategoryChip('loanable', 'Loanable',
                            loanableCount, filterState.assetCategory),
                        const SizedBox(width: 8),
                        _buildCategoryChip('saleable', 'Saleable',
                            saleableCount, filterState.assetCategory),
                      ],
                    );
                  },
                  loading: () => const SizedBox(
                    height: 32,
                    child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Status Filter (STATUS 2)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: assetAsync.when(
                  data: (assets) {
                    // ✅ Count from filtered assets for display only
                    final displayTotal = assets.length;
                    final availableCount =
                        assets.where((a) => a.status == 'available').length;
                    final borrowedCount =
                        assets.where((a) => a.status == 'borrowed').length;
                    final maintenanceCount =
                        assets.where((a) => a.status == 'maintenance').length;
                    final disposedCount =
                        assets.where((a) => a.status == 'disposed').length;

                    return Row(
                      children: [
                        _buildStatusChip('all', 'All Status', displayTotal,
                            filterState.status),
                        const SizedBox(width: 8),
                        _buildStatusChip('available', 'Available',
                            availableCount, filterState.status),
                        const SizedBox(width: 8),
                        _buildStatusChip('borrowed', 'Borrowed', borrowedCount,
                            filterState.status),
                        const SizedBox(width: 8),
                        _buildStatusChip('maintenance', 'Maintenance',
                            maintenanceCount, filterState.status),
                        const SizedBox(width: 8),
                        _buildStatusChip('disposed', 'Disposed', disposedCount,
                            filterState.status),
                      ],
                    );
                  },
                  loading: () => const SizedBox(
                    height: 32,
                    child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Asset List
            Expanded(
              child: assetAsync.when(
                data: (assets) {
                  if (assets.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.inventory,
                              size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            _getEmptyMessage(filterState),
                            style: const TextStyle(
                                fontSize: 16, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          // ✅ Show hint about filters when active
                          if (_hasActiveFilters(filterState))
                            const Text(
                              'Try adjusting your filters to see more results',
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          const SizedBox(height: 16),
                          // ✅ ONLY show Clear Filters when filters are active AND no data
                          if (_hasActiveFilters(filterState))
                            ElevatedButton.icon(
                              onPressed: () {
                                ref.read(assetFilterProvider.notifier).reset();
                                _searchController.clear();
                              },
                              icon: const Icon(Icons.clear_all),
                              label: const Text('Clear All Filters'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                              ),
                            )
                          else
                            TextButton.icon(
                              onPressed: _refreshAssets,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Refresh'),
                            ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: assets.length,
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      final asset = assets[index];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        color: asset.isPending ? Colors.amber.shade50 : null,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                _getCategoryColor(asset.assetCategory),
                            child: Icon(
                              _getCategoryIcon(asset.assetCategory),
                              color: Colors.white,
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  asset.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              if (asset.isPending)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade700,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'NEEDS CLASSIFICATION',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Code: ${asset.assetCode}'),
                              if (asset.assetCategory == 'consumable')
                                Text('Quantity: ${asset.quantity}'),
                              if (asset.purchasePrice != null)
                                Text(
                                    'Price: Rp ${NumberFormat('#,###').format(asset.purchasePrice)}'),
                              if (asset.assignedToName != null)
                                Text(
                                  'Assigned to: ${asset.assignedToName}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.orange,
                                  ),
                                ),
                            ],
                          ),
                          trailing: Wrap(
                            direction: Axis.vertical,
                            spacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.end,
                            children: [
                              Chip(
                                label: Text(
                                  asset.categoryDisplayName.toUpperCase(),
                                  style: const TextStyle(fontSize: 9),
                                ),
                                backgroundColor:
                                    _getCategoryColor(asset.assetCategory)
                                        .withOpacity(0.2),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              Chip(
                                label: Text(
                                  asset.statusDisplayName.toUpperCase(),
                                  style: const TextStyle(fontSize: 9),
                                ),
                                backgroundColor: _getStatusColor(asset.status)
                                    .withOpacity(0.2),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    AssetDetailScreen(assetId: asset.id),
                              ),
                            ).then((_) => _refreshAssets());
                          },
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: $error'),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _refreshAssets,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  // ✅ Check if any filter is active
  bool _hasActiveFilters(AssetFilter filter) {
    return filter.search != null ||
        filter.assetCategory != null ||
        filter.status != null ||
        filter.productId != null ||
        filter.categoryId != null ||
        filter.assignedTo != null;
  }

  // ✅ Helper to show appropriate empty message
  String _getEmptyMessage(AssetFilter filter) {
    if (filter.search != null) {
      return 'No assets found matching "${filter.search}"';
    }
    if (filter.assetCategory != null && filter.status != null) {
      return 'No ${filter.status} assets in ${filter.assetCategory} category';
    }
    if (filter.assetCategory != null) {
      return 'No assets in ${filter.assetCategory} category';
    }
    if (filter.status != null) {
      return 'No ${filter.status} assets';
    }
    return 'No assets found';
  }

  // ✅ Category chip with provider state
  Widget _buildCategoryChip(
      String value, String label, int count, String? currentFilter,
      {bool isWarning = false}) {
    // ✅ FIX: "all" means no filter (null), not "all" string
    final isSelected = value == 'all'
        ? currentFilter == null // "All" selected when no category filter
        : currentFilter == value; // Others selected when filter matches

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white
                    : (isWarning ? Colors.amber.shade700 : Colors.blue),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected
                      ? (isWarning ? Colors.amber.shade700 : Colors.blue)
                      : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      selected: isSelected,
      selectedColor: isWarning ? Colors.amber.shade100 : null,
      onSelected: (selected) {
        // ✅ PERBAIKAN: Langsung update, biar provider handle clear
        ref
            .read(assetFilterProvider.notifier)
            .updateCategory(value == 'all' ? null : value);
      },
    );
  }

  // ✅ Status chip with provider state
  Widget _buildStatusChip(
      String value, String label, int count, String? currentFilter) {
    // ✅ FIX: "all" means no filter (null), not "all" string
    final isSelected = value == 'all'
        ? currentFilter == null // "All Status" selected when no status filter
        : currentFilter == value; // Others selected when filter matches

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.orange,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected ? Colors.orange : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        // ✅ PERBAIKAN: Langsung update, biar provider handle clear
        ref
            .read(assetFilterProvider.notifier)
            .updateStatus(value == 'all' ? null : value);
      },
    );
  }
}
