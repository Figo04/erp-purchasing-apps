import 'package:erp_purchasing_apps/presentation/screens/asset/AssetTransactionTypeDialog.dart';
import 'package:erp_purchasing_apps/presentation/screens/asset/asset_transaction_form_screen.dart';
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
      case 'loanable':
        return Colors.purple;
      case 'saleable':
        return Colors.green;
      case 'disposed': // TAMBAH
        return Colors.grey;
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
      case 'lent':
        return Colors.blue;
      case 'sold':
        return Colors.purple;
      case 'disposed':
        return Colors.grey;
      case 'returned':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'loanable':
        return Icons.devices;
      case 'saleable':
        return Icons.shopping_bag;
      case 'disposed':
        return Icons.delete_forever;
      case 'pending':
        return Icons.help_outline;
      default:
        return Icons.category;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'mesin':
        return Icons.precision_manufacturing;
      case 'sparepart':
        return Icons.build_circle;
      default:
        return Icons.category;
    }
  }

  void _refreshAssets() {
    ref.invalidate(filteredAssetListProvider);
    ref.invalidate(borrowedAssetsCountProvider);
    ref.invalidate(lentAssetsCountProvider);
    ref.invalidate(assetsByCategoryProvider);
    ref.invalidate(assetsByTypeProvider);
  }

  @override
  Widget build(BuildContext context) {
    final assetAsync = ref.watch(filteredAssetListProvider);
    final borrowedCountAsync = ref.watch(borrowedAssetsCountProvider);
    final lentCountAsync = ref.watch(lentAssetsCountProvider);
    final categoryCounts = ref.watch(assetsByCategoryProvider);
    final typeCounts = ref.watch(assetsByTypeProvider);
    final currentUser = ref.watch(currentUserProvider);
    final canManage =
        currentUser?.role == 'admin' || currentUser?.role == 'warehouse';

    final filterState = ref.watch(assetFilterProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
        title: const Text('Assets Management'),
        actions: [
          // Borrowed Count Badge
          borrowedCountAsync.when(
            data: (count) {
              if (count > 0) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Center(
                    child: Chip(
                      label: Text(
                        'Borrowed: $count',
                        style:
                            const TextStyle(fontSize: 11, color: Colors.white),
                      ),
                      backgroundColor: Colors.orange,
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          // Lent Count Badge (NEW)
          lentCountAsync.when(
            data: (count) {
              if (count > 0) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Center(
                    child: Chip(
                      label: Text(
                        'Lent: $count',
                        style:
                            const TextStyle(fontSize: 11, color: Colors.white),
                      ),
                      backgroundColor: Colors.blue,
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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

            // Asset Type Filter (NEW) - Mesin/Sparepart
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: typeCounts.when(
                  data: (counts) {
                    final total =
                        counts.values.fold<int>(0, (sum, count) => sum + count);
                    final mesinCount = counts['mesin'] ?? 0;
                    final sparepartCount = counts['sparepart'] ?? 0;

                    return Row(
                      children: [
                        _buildTypeChip(
                            'all', 'All Types', total, filterState.assetType),
                        const SizedBox(width: 8),
                        _buildTypeChip('mesin', '🔧 Mesin', mesinCount,
                            filterState.assetType),
                        const SizedBox(width: 8),
                        _buildTypeChip('sparepart', '⚙️ Sparepart',
                            sparepartCount, filterState.assetType),
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

            // Category Filter (Consumable/Loanable/Saleable)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: categoryCounts.when(
                  data: (counts) {
                    final total =
                        counts.values.fold<int>(0, (sum, count) => sum + count);
                    final pendingCount = counts['pending'] ?? 0;
                    final disposedCount = counts['disposed'] ?? 0;
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
                        _buildCategoryChip('disposed', 'Disposed',
                            disposedCount, filterState.assetCategory),
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

            // Status Filter (Available/Borrowed/Lent/etc)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: assetAsync.when(
                  data: (assets) {
                    final displayTotal = assets.length;
                    final availableCount =
                        assets.where((a) => a.status == 'available').length;
                    final borrowedCount =
                        assets.where((a) => a.status == 'borrowed').length;
                    final lentCount =
                        assets.where((a) => a.status == 'lent').length;
                    final returnedCount =
                        assets.where((a) => a.status == 'returned').length;

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
                        _buildStatusChip(
                            'lent', 'Lent', lentCount, filterState.status),
                        const SizedBox(width: 8),
                        _buildStatusChip('returned', 'Returned', returnedCount,
                            filterState.status),
                        const SizedBox(width: 8),
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
                          if (_hasActiveFilters(filterState))
                            const Text(
                              'Try adjusting your filters to see more results',
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          const SizedBox(height: 16),
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
                              // Show Type & Division
                              Row(
                                children: [
                                  Icon(_getTypeIcon(asset.assetType),
                                      size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                    asset.assetTypeDisplayName,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  if (asset.divisionName != null) ...[
                                    const SizedBox(width: 12),
                                    const Icon(Icons.business,
                                        size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      asset.divisionName!,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ],
                                  if (asset.isDisposed)
                                    Container(
                                      margin: const EdgeInsets.only(top: 4),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade700,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'DISPOSED',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
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
                              // NEW: Show source (external/supplier)
                              if (asset.isFromExternal)
                                Row(
                                  children: [
                                    const Icon(Icons.business_center,
                                        size: 14, color: Colors.purple),
                                    const SizedBox(width: 4),
                                    Text(
                                      'From: ${asset.sourceDisplayName}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.purple,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
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
                              if (!asset.isDisposed)
                                Chip(
                                  label: Text(
                                    asset.statusDisplayName.toUpperCase(),
                                    style: const TextStyle(fontSize: 9),
                                  ),
                                  backgroundColor:
                                      _getStatusColor(asset.status ?? '')
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
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () {
                showAssetTransactionTypeDialog(
                  context: context,
                  onTypeSelected: (transactionType) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AssetTransactionFormScreen(
                          transactionType: transactionType,
                        ),
                      ),
                    ).then((_) => _refreshAssets());
                  },
                );
              },
              icon: const Icon(Icons.swap_horiz),
              label: const Text('Asset Transaction'),
              backgroundColor: Colors.purple,
            )
          : null,
    );
  }

  bool _hasActiveFilters(AssetFilter filter) {
    return filter.search != null ||
        filter.assetCategory != null ||
        filter.assetType != null ||
        filter.status != null ||
        filter.sourceType != null ||
        filter.divisionId != null ||
        filter.productId != null ||
        filter.categoryId != null ||
        filter.assignedTo != null;
  }

  String _getEmptyMessage(AssetFilter filter) {
    if (filter.search != null) {
      return 'No assets found matching "${filter.search}"';
    }
    if (filter.assetType != null && filter.assetCategory != null) {
      return 'No ${filter.assetType} assets in ${filter.assetCategory} category';
    }
    if (filter.assetType != null) {
      return 'No ${filter.assetType} assets found';
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

  // Type chip (NEW)
  Widget _buildTypeChip(
      String value, String label, int count, String? currentFilter) {
    final isSelected =
        value == 'all' ? currentFilter == null : currentFilter == value;

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
                color: isSelected ? Colors.white : Colors.deepPurple,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected ? Colors.deepPurple : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      selected: isSelected,
      selectedColor: Colors.deepPurple.shade100,
      onSelected: (selected) {
        ref
            .read(assetFilterProvider.notifier)
            .updateAssetType(value == 'all' ? null : value);
      },
    );
  }

  Widget _buildCategoryChip(
      String value, String label, int count, String? currentFilter,
      {bool isWarning = false}) {
    final isSelected =
        value == 'all' ? currentFilter == null : currentFilter == value;

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
        ref
            .read(assetFilterProvider.notifier)
            .updateCategory(value == 'all' ? null : value);
      },
    );
  }

  Widget _buildStatusChip(
      String value, String label, int count, String? currentFilter) {
    final isSelected =
        value == 'all' ? currentFilter == null : currentFilter == value;

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
        ref
            .read(assetFilterProvider.notifier)
            .updateStatus(value == 'all' ? null : value);
      },
    );
  }
}
