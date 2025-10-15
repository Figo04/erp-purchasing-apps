import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
// import 'package:erp_purchasing_apps/data/models/inventory_model.dart';
import 'package:erp_purchasing_apps/data/providers/inventory_provider.dart';
import 'package:erp_purchasing_apps/presentation/screens/inventory/inventory_detail_screen.dart';
import 'package:intl/intl.dart';

class InventoryListScreen extends ConsumerStatefulWidget {
  const InventoryListScreen({super.key});

  @override
  ConsumerState<InventoryListScreen> createState() =>
      _InventoryListScreenState();
}

class _InventoryListScreenState extends ConsumerState<InventoryListScreen> {
  String _filterStatus = 'all';
  String _searchQuery = '';
  final _searchController = TextEditingController();
  bool _showLowStockOnly = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'available':
        return Colors.green;
      case 'reserved':
        return Colors.orange;
      case 'damaged':
        return Colors.red;
      case 'disposed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Color _getStockLevelColor(int quantity) {
    if (quantity == 0) return Colors.red;
    if (quantity < 10) return Colors.orange;
    if (quantity < 50) return Colors.blue;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final inventoryStream = ref.watch(inventoryStreamProvider);
    final lowStockCount = ref.watch(lowStockCountProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
        title: const Text('Inventory'),
        actions: [
          if (lowStockCount > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: Chip(
                  label: Text(
                    'Low Stock: $lowStockCount',
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  ),
                  backgroundColor: Colors.red,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: inventoryStream.when(
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
            onPressed: () {
              ref.invalidate(inventoryStreamProvider);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Low Stock Alert Banner
          if (lowStockCount > 0)
            Container(
              width: double.infinity,
              color: Colors.red.shade50,
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$lowStockCount item${lowStockCount > 1 ? 's' : ''} running low on stock!',
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _showLowStockOnly = !_showLowStockOnly;
                        _filterStatus = 'available';
                      });
                    },
                    child: Text(_showLowStockOnly ? 'Show All' : 'View'),
                  ),
                ],
              ),
            ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search item name or location...',
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
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),

          // Filter Tabs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: inventoryStream.when(
                data: (items) {
                  final availableCount =
                      items.where((i) => i.status == 'available').length;
                  final reservedCount =
                      items.where((i) => i.status == 'reserved').length;
                  final damagedCount =
                      items.where((i) => i.status == 'damaged').length;
                  final disposedCount =
                      items.where((i) => i.status == 'disposed').length;

                  return Row(
                    children: [
                      _buildFilterChip('all', 'All', items.length),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                          'available', 'Available', availableCount),
                      const SizedBox(width: 8),
                      _buildFilterChip('reserved', 'Reserved', reservedCount),
                      const SizedBox(width: 8),
                      _buildFilterChip('damaged', 'Damaged', damagedCount),
                      const SizedBox(width: 8),
                      _buildFilterChip('disposed', 'Disposed', disposedCount),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Inventory List
          Expanded(
            child: inventoryStream.when(
              data: (items) {
                var filteredItems = items;

                // Filter by status
                if (_filterStatus != 'all') {
                  filteredItems = filteredItems
                      .where((item) => item.status == _filterStatus)
                      .toList();
                }

                // Filter low stock only
                if (_showLowStockOnly) {
                  filteredItems = filteredItems
                      .where((item) =>
                          item.quantity < 10 && item.status == 'available')
                      .toList();
                }

                // Filter by search query
                if (_searchQuery.isNotEmpty) {
                  filteredItems = filteredItems.where((item) {
                    return item.itemName.toLowerCase().contains(_searchQuery) ||
                        (item.location?.toLowerCase().contains(_searchQuery) ??
                            false);
                  }).toList();
                }

                if (filteredItems.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _showLowStockOnly
                              ? Icons.check_circle
                              : Icons.inventory,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _showLowStockOnly
                              ? 'No low stock items'
                              : 'No inventory items',
                          style:
                              const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filteredItems.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    final isLowStock =
                        item.quantity < 10 && item.status == 'available';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getStockLevelColor(item.quantity),
                          child: Text(
                            item.quantity.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.itemName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (isLowStock)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.warning,
                                        color: Colors.white, size: 14),
                                    SizedBox(width: 4),
                                    Text(
                                      'LOW',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Stock: ${item.quantity} ${item.unit}',
                              style: TextStyle(
                                color: _getStockLevelColor(item.quantity),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (item.location != null)
                              Text('Location: ${item.location}'),
                            if (item.receivedDate != null)
                              Text(
                                'Received: ${DateFormat('dd MMM yyyy').format(item.receivedDate!)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                          ],
                        ),
                        trailing: Chip(
                          label: Text(
                            item.status.toUpperCase(),
                            style: const TextStyle(fontSize: 10),
                          ),
                          backgroundColor:
                              _getStatusColor(item.status).withOpacity(0.2),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => InventoryDetailScreen(
                                inventoryId: item.id,
                              ),
                            ),
                          ).then((_) {
                            ref.invalidate(inventoryStreamProvider);
                          });
                        },
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        ref.invalidate(inventoryStreamProvider);
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, int count) {
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
        setState(() {
          _filterStatus = value;
          _showLowStockOnly = false;
        });
      },
    );
  }
}
