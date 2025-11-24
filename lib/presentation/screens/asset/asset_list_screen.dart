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
  String _filterCategory = 'all';
  String _filterStatus = 'all';
  String _searchQuery = '';
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
      default:
        return Icons.category;
    }
  }

  void _refreshAssets() {
    ref.invalidate(filteredAssetListProvider);
    ref.invalidate(borrowedAssetsCountProvider);
  }

  @override
  Widget build(BuildContext context) {
    final assetAsync = ref.watch(filteredAssetListProvider);
    final borrowedCountAsync = ref.watch(borrowedAssetsCountProvider);
    final currentUser = ref.watch(currentUserProvider);
    final canManage =
        currentUser?.role == 'admin' || currentUser?.role == 'warehouse';

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
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                            });
                            ref
                                .read(assetFilterProvider.notifier)
                                .updateSearch(null);
                          },
                        )
                      : null,
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value.toLowerCase());
                  ref
                      .read(assetFilterProvider.notifier)
                      .updateSearch(value.isEmpty ? null : value);
                },
              ),
            ),

            // Category Filter
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: assetAsync.when(
                  data: (assets) {
                    final consumableCount = assets
                        .where((a) => a.assetCategory == 'consumable')
                        .length;
                    final loanableCount = assets
                        .where((a) => a.assetCategory == 'loanable')
                        .length;
                    final saleableCount = assets
                        .where((a) => a.assetCategory == 'saleable')
                        .length;

                    return Row(
                      children: [
                        _buildCategoryChip('all', 'All', assets.length),
                        const SizedBox(width: 8),
                        _buildCategoryChip(
                            'consumable', 'Consumable', consumableCount),
                        const SizedBox(width: 8),
                        _buildCategoryChip(
                            'loanable', 'Loanable', loanableCount),
                        const SizedBox(width: 8),
                        _buildCategoryChip(
                            'saleable', 'Saleable', saleableCount),
                      ],
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Status Filter
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: assetAsync.when(
                  data: (assets) {
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
                        _buildStatusChip('all', 'All Status', assets.length),
                        const SizedBox(width: 8),
                        _buildStatusChip(
                            'available', 'Available', availableCount),
                        const SizedBox(width: 8),
                        _buildStatusChip('borrowed', 'Borrowed', borrowedCount),
                        const SizedBox(width: 8),
                        _buildStatusChip(
                            'maintenance', 'Maintenance', maintenanceCount),
                        const SizedBox(width: 8),
                        _buildStatusChip('disposed', 'Disposed', disposedCount),
                      ],
                    );
                  },
                  loading: () => const SizedBox.shrink(),
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
                          const Text(
                            'No assets found',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
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
                                _getCategoryColor(asset.assetCategory),
                            child: Icon(
                              _getCategoryIcon(asset.assetCategory),
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            asset.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
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
                                  asset.assetCategory.toUpperCase(),
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
                                  asset.status.toUpperCase(),
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

  Widget _buildCategoryChip(String value, String label, int count) {
    final isSelected = _filterCategory == value;
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
      onSelected: (selected) {
        setState(() => _filterCategory = value);
        ref
            .read(assetFilterProvider.notifier)
            .updateCategory(value == 'all' ? null : value);
      },
    );
  }

  Widget _buildStatusChip(String value, String label, int count) {
    final isSelected = _filterStatus == value;
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
        setState(() => _filterStatus = value);
        ref
            .read(assetFilterProvider.notifier)
            .updateStatus(value == 'all' ? null : value);
      },
    );
  }
}
