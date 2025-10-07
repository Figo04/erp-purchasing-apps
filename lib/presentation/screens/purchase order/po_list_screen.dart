import 'package:erp_purchasing_apps/data/models/purchase_order_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:erp_purchasing_apps/data/providers/po_provider.dart';
import 'package:erp_purchasing_apps/data/providers/auth_providers.dart';
import 'package:erp_purchasing_apps/presentation/screens/purchase order/po_form_screen.dart';
import 'package:intl/intl.dart';

class POListScreen extends ConsumerStatefulWidget {
  const POListScreen({super.key});

  @override
  ConsumerState<POListScreen> createState() => _POListScreenState();
}

class _POListScreenState extends ConsumerState<POListScreen> {
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
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.blue;
      case 'received':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _navigateToForm({String? poId, String? prId}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => POFormScreen(
          poId: poId,
          prId: prId,
        ),
      ),
    ).then(
      (_) {
        ref.invalidate(poStreamProvider);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final poStream = ref.watch(poStreamProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
        title: const Text('Purchase Orders'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: poStream.when(
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
              ref.invalidate(poStreamProvider);
            },
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'search PO number...',
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
              child: poStream.when(
                data: (pos) {
                  final pendingCount =
                      pos.where((po) => po.status == 'pending').length;
                  final approvedCount =
                      pos.where((po) => po.status == 'approved').length;
                  final receivedCount =
                      pos.where((po) => po.status == 'received').length;
                  final cancelledCount =
                      pos.where((po) => po.status == 'cancelled').length;

                  return Row(
                    children: [
                      _buildFilterCHip('all', 'All', pos.length),
                      const SizedBox(width: 8),
                      _buildFilterCHip('pending', 'Pending', pendingCount),
                      const SizedBox(width: 8),
                      _buildFilterCHip('approved', 'Approved', approvedCount),
                      const SizedBox(width: 8),
                      _buildFilterCHip('received', 'Received', receivedCount),
                      const SizedBox(width: 8),
                      _buildFilterCHip(
                          'cancelled', 'Cancelled', cancelledCount),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
          ),

          // PO List
          Expanded(
            child: poStream.when(
                data: (pos) {
                  var filteredPOs = _filterStatus == 'all'
                      ? pos
                      : pos.where((po) => po.status == _filterStatus).toList();

                  if (_searchQuery.isNotEmpty) {
                    filteredPOs = filteredPOs.where((po) {
                      return po.poNumber.toLowerCase().contains(_searchQuery);
                    }).toList();
                  }

                  if (filteredPOs.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_cart,
                              size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No POs found',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          )
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                      itemCount: filteredPOs.length,
                      padding: const EdgeInsets.all(16),
                      itemBuilder: (context, index) {
                        final po = filteredPOs[index];
                        final itemCount = po.items?.length ?? 0;
                        final canEdit = po.status == 'pending';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getStatusColor(po.status),
                                child: Text(
                                  po.poNumber.split('_').last.substring(0, 2),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              title: Text(
                                po.poNumber,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Items: $itemCount'),
                                  Text(
                                    'Total: Rp ${NumberFormat('#,###').format(po.totalAmount)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  Text(
                                      'Date: ${DateFormat('dd MMM yyyy').format(po.orderDate)}'),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Chip(
                                    label: Text(
                                      po.status.toUpperCase(),
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                    backgroundColor: _getStatusColor(po.status)
                                        .withOpacity(0.2),
                                  ),
                                  if (canEdit) ...[
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 20),
                                      onPressed: () =>
                                          _navigateToForm(poId: po.id),
                                    ),
                                  ],
                                ],
                              ),
                              onTap: () {
                                _showPODetail(po);
                              }),
                        );
                      });
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
                          ElevatedButton(
                            onPressed: () {
                              ref.invalidate(poStreamProvider);
                            },
                            child: const Text('Retry'),
                          )
                        ],
                      ),
                    )),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToForm(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterCHip(String value, String label, int count) {
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

  void _showPODetail(PurchaseOrderModel po) {
    showDialog(
        context: context,
        builder: (context) => Dialog(
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: 600, maxHeight: 600),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PO Detail: ${po.poNumber}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Divider(height: 24),
                      Text('Status: ${po.status.toUpperCase()}'),
                      Text(
                          'Order Date: ${DateFormat('dd MMM yyyy').format(po.orderDate)}'),
                      Text(
                          'Total: Rp ${NumberFormat('#,###').format(po.totalAmount)}'),
                      if (po.notes != null) Text('Notes: ${po.notes}'),
                      const SizedBox(height: 16),
                      const Text(
                        'Items:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: po.items?.length ?? 0,
                          itemBuilder: (context, index) {
                            final item = po.items![index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.itemName,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text('Qty: ${item.quantity} ${item.unit}'),
                                    Text(
                                      'Price: Rp ${NumberFormat('#,###').format(item.subtotal)}',
                                      style: const TextStyle(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.w600),
                                    )
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
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
            ));
  }
}
