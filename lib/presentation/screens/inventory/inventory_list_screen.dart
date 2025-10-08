import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:erp_purchasing_apps/data/models/inventory_model.dart';
import 'package:erp_purchasing_apps/data/providers/inventory_provider.dart';
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
              ref.invalidate(inventoryRepositoryProvider);
            },
          )
        ],
      ),
      body: Column(
        children: [
          // search Bar
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
            padding: const EdgeInsets.all(8),
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

                  return Row(
                    children: [
                      _buildFilterChip('all', 'All', items.length),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                          'available', 'Available', availableCount),
                      SizedBox(width: 8),
                      _buildFilterChip('reserved', 'Reserved', reservedCount),
                      const SizedBox(width: 8),
                      _buildFilterChip('damaged', 'Damaged', damagedCount),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
          ),

          // Inventory List
          Expanded(
            child: inventoryStream.when(
              data: (items) {
                var filteredItems = _filterStatus == 'all'
                    ? items
                    : items
                        .where((item) => item.status == _filterStatus)
                        .toList();

                if (_searchQuery.isNotEmpty) {
                  filteredItems = filteredItems.where((item) {
                    return item.itemName.toLowerCase().contains(_searchQuery) ||
                        (item.location?.toLowerCase().contains(_searchQuery) ??
                            false);
                  }).toList();
                }

                if (filteredItems.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No inventory items',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        )
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
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  _getStockLevelColor(item.quantity),
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
                                  const Icon(Icons.warning,
                                      color: Colors.red, size: 20),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Stock: ${item.quantity} ${item.unit}'),
                                if (item.receivedDate != null)
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
                            onTap: () => _showInventoryDetail(item),
                          ),
                        ),
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
                    )
                  ],
                ),
              ),
            ),
          )
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
            )
          ]
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterStatus = value;
        });
      },
    );
  }

  void _showInventoryDetail(InventoryModel item) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Inventory Detail',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Divider(height: 24),
                _buildInfoRow('Item Name', item.itemName),
                _buildInfoRow('Quantity', '${item.quantity} ${item.unit}'),
                _buildInfoRow('Status', item.status.toUpperCase()),
                if (item.location != null)
                  _buildInfoRow('Location', item.location!),
                if (item.receivedDate != null)
                  _buildInfoRow(
                    'Received Date',
                    DateFormat('dd MMM yyyy').format(item.receivedDate!),
                  ),
                if (item.notes != null) _buildInfoRow('Notes', item.notes!),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
