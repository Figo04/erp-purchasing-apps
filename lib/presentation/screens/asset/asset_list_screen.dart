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

  // ✅ UPDATED: Color for ownership
  Color _getOwnershipColor(String ownership) {
    switch (ownership) {
      case 'milik_sendiri':
        return Colors.blue;
      case 'milik_customer':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'available':
        return Colors.green;
      case 'saleable':
        return Colors.teal;
      case 'loanable':
        return Colors.indigo;
      case 'disposed':
        return Colors.grey;
      case 'borrowed':
        return Colors.orange;
      case 'lent':
        return Colors.blue;
      case 'sold':
        return Colors.purple;
      case 'returned':
        return Colors.cyan;
      default:
        return Colors.grey;
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
    ref.invalidate(assetsByOwnershipProvider);
    ref.invalidate(assetsByTypeProvider);
    ref.invalidate(assetsByStatusProvider);
  }

  @override
  Widget build(BuildContext context) {
    final assetAsync = ref.watch(filteredAssetListProvider);
    final borrowedCountAsync = ref.watch(borrowedAssetsCountProvider);
    final lentCountAsync = ref.watch(lentAssetsCountProvider);
    final ownershipCounts = ref.watch(assetsByOwnershipProvider);
    final typeCounts = ref.watch(assetsByTypeProvider);
    final statusCounts = ref.watch(assetsByStatusProvider);
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

            // ✅ NEW: Asset Type Filter (Mesin/Sparepart)
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

            // ✅ UPDATED: Ownership Filter (Milik Sendiri / Milik Customer)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ownershipCounts.when(
                  data: (counts) {
                    final total =
                        counts.values.fold<int>(0, (sum, count) => sum + count);
                    final milikSendiriCount = counts['milik_sendiri'] ?? 0;
                    final milikCustomerCount = counts['milik_customer'] ?? 0;

                    return Row(
                      children: [
                        _buildOwnershipChip(
                            'all', 'All', total, filterState.ownership),
                        const SizedBox(width: 8),
                        _buildOwnershipChip('milik_sendiri', 'Milik Sendiri',
                            milikSendiriCount, filterState.ownership),
                        const SizedBox(width: 8),
                        _buildOwnershipChip('milik_customer', 'Milik Customer',
                            milikCustomerCount, filterState.ownership),
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

            // ✅ UPDATED: Status Filter
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: statusCounts.when(
                  data: (counts) {
                    final availableCount = counts['available'] ?? 0;
                    final saleableCount = counts['saleable'] ?? 0;
                    final loanableCount = counts['loanable'] ?? 0;
                    final disposedCount = counts['disposed'] ?? 0;
                    final borrowedCount = counts['borrowed'] ?? 0;
                    final lentCount = counts['lent'] ?? 0;
                    final soldCount = counts['sold'] ?? 0;
                    final returnedCount = counts['returned'] ?? 0;

                    final displayTotal = availableCount +
                        saleableCount +
                        loanableCount +
                        disposedCount +
                        borrowedCount +
                        lentCount +
                        soldCount +
                        returnedCount;

                    return Row(
                      children: [
                        _buildStatusChip('all', 'All Status', displayTotal,
                            filterState.status),
                        const SizedBox(width: 8),
                        _buildStatusChip('available', 'Available',
                            availableCount, filterState.status),
                        const SizedBox(width: 8),
                        _buildStatusChip('saleable', 'Saleable', saleableCount,
                            filterState.status),
                        const SizedBox(width: 8),
                        _buildStatusChip('loanable', 'Loanable', loanableCount,
                            filterState.status),
                        const SizedBox(width: 8),
                        _buildStatusChip('disposed', 'Disposed', disposedCount,
                            filterState.status),
                        const SizedBox(width: 8),
                        if (borrowedCount > 0) ...[
                          _buildStatusChip('borrowed', 'Borrowed',
                              borrowedCount, filterState.status),
                          const SizedBox(width: 8),
                        ],
                        if (lentCount > 0) ...[
                          _buildStatusChip(
                              'lent', 'Lent', lentCount, filterState.status),
                          const SizedBox(width: 8),
                        ],
                        if (soldCount > 0) ...[
                          _buildStatusChip(
                              'sold', 'Sold', soldCount, filterState.status),
                          const SizedBox(width: 8),
                        ],
                        if (returnedCount > 0) ...[
                          _buildStatusChip('returned', 'Returned',
                              returnedCount, filterState.status),
                        ],
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
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                _getOwnershipColor(asset.ownership),
                            child: Icon(
                              _getTypeIcon(asset.assetType),
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
                              // ✅ Show ownership badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _getOwnershipColor(asset.ownership)
                                      .withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _getOwnershipColor(asset.ownership),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  asset.ownershipDisplayName,
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: _getOwnershipColor(asset.ownership),
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
                              // Show source
                              Row(
                                children: [
                                  Icon(
                                    asset.isFromSupplier
                                        ? Icons.local_shipping
                                        : Icons.edit,
                                    size: 14,
                                    color: asset.isFromSupplier
                                        ? Colors.teal
                                        : Colors.purple,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    asset.sourceDisplayName,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: asset.isFromSupplier
                                          ? Colors.teal
                                          : Colors.purple,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: Chip(
                            label: Text(
                              asset.statusDisplayName.toUpperCase(),
                              style: const TextStyle(fontSize: 9),
                            ),
                            backgroundColor:
                                _getStatusColor(asset.status).withOpacity(0.2),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
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
        filter.ownership != null ||
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
    if (filter.assetType != null && filter.ownership != null) {
      return 'No ${filter.assetType} assets with ownership ${filter.ownership}';
    }
    if (filter.assetType != null) {
      return 'No ${filter.assetType} assets found';
    }
    if (filter.ownership != null) {
      return 'No assets with ownership ${filter.ownership}';
    }
    if (filter.status != null) {
      return 'No ${filter.status} assets';
    }
    return 'No assets found';
  }

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
        if (value == 'all') {
          ref.read(assetFilterProvider.notifier).updateAssetType(null);
        } else {
          ref.read(assetFilterProvider.notifier).updateAssetType(value);
        }
      },
    );
  }

  // ✅ NEW: Ownership chip
  Widget _buildOwnershipChip(
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
                color: isSelected ? Colors.white : Colors.blue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected ? Colors.blue : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      selected: isSelected,
      selectedColor: Colors.blue.shade100,
      onSelected: (selected) {
        if (value == 'all') {
          ref.read(assetFilterProvider.notifier).updateOwnership(null);
        } else {
          ref.read(assetFilterProvider.notifier).updateOwnership(value);
        }
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
      selectedColor: Colors.orange.shade100,
      onSelected: (selected) {
        if (value == 'all') {
          ref.read(assetFilterProvider.notifier).updateStatus(null);
        } else {
          ref.read(assetFilterProvider.notifier).updateStatus(value);
        }
      },
    );
  }
}

