import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:erp_purchasing_apps/data/providers/goods_receipt_provider.dart';
import 'package:erp_purchasing_apps/data/models/goods_receipt_model.dart';
import 'package:erp_purchasing_apps/presentation/screens/lpb/goods_receipt_form_screen.dart';

class GoodsReceiptListScreen extends ConsumerStatefulWidget {
  const GoodsReceiptListScreen({super.key});

  @override
  ConsumerState<GoodsReceiptListScreen> createState() =>
      _GoodsReceiptListScreenState();
}

class _GoodsReceiptListScreenState
    extends ConsumerState<GoodsReceiptListScreen> {
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
      case 'draft':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _navigateToForm({String? poId}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GoodsReceiptFormScreen(poId: poId),
      ),
    ).then((_) {
      ref.invalidate(goodsReceiptStreamProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final receiptsStream = ref.watch(goodsReceiptStreamProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
        title: const Text('Goods Receipt (LPB)'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: receiptsStream.when(
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
              ref.invalidate(goodsReceiptStreamProvider);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar6
          Padding(
            padding: const EdgeInsets.all(1.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search LPB number or PO number...',
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
              child: receiptsStream.when(
                data: (receipts) {
                  final draftCount =
                      receipts.where((r) => r.status == 'draft').length;
                  final completedCount =
                      receipts.where((r) => r.status == 'completed').length;

                  return Row(
                    children: [
                      _buildFilterChip('all', 'All', receipts.length),
                      const SizedBox(width: 8),
                      _buildFilterChip('draft', 'Draft', draftCount),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                          'completed', 'Completed', completedCount),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
          ),

          // Receipt List
          Expanded(
            child: receiptsStream.when(
              data: (receipts) {
                var filteredReceipts = _filterStatus == 'all'
                    ? receipts
                    : receipts.where((r) => r.status == _filterStatus).toList();

                if (_searchQuery.isNotEmpty) {
                  filteredReceipts = filteredReceipts.where((r) {
                    return r.receiptNumber
                            .toLowerCase()
                            .contains(_searchQuery) ||
                        (r.poNumber?.toLowerCase().contains(_searchQuery) ??
                            false);
                  }).toList();
                }

                if (filteredReceipts.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No receipts found',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        )
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filteredReceipts.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final receipt = filteredReceipts[index];
                    final itemCount = receipt.items?.length ?? 0;
                    final canDelete = receipt.status == 'draft';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getStatusColor(receipt.status),
                          child: const Icon(Icons.inventory_2,
                              color: Colors.white, size: 20),
                        ),
                        title: Text(
                          receipt.receiptNumber,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (receipt.poNumber != null)
                              Text('PO: ${receipt.poNumber}'),
                            Text('Items: $itemCount'),
                            Text(
                                'Date: ${DateFormat('dd MMM yyyy').format(receipt.receiptDate)}'),
                            if (receipt.receiverName != null)
                              Text('By: ${receipt.receiverName}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Chip(
                              label: Text(
                                receipt.status.toUpperCase(),
                                style: const TextStyle(fontSize: 10),
                              ),
                              backgroundColor: _getStatusColor(receipt.status)
                                  .withOpacity(0.2),
                            ),
                            if (canDelete) ...[
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.red, size: 20),
                                onPressed: () => _confirmDelete(
                                    receipt.id, receipt.receiptNumber),
                              )
                            ]
                          ],
                        ),
                        onTap: () => _showReceiptDetail(receipt),
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
                        ref.invalidate(goodsReceiptStreamProvider);
                      },
                      child: const Text('Retry'),
                    )
                  ],
                ),
              ),  
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPOSelector(),
        icon: const Icon(Icons.add),
        label: const Text('Create LPB'),
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
        });
      },
    );
  }

  void _showPOSelector() {
    // Navigate to PO selection or directly to form
    // For now, we'll navigate to form and let user select PO there
    _navigateToForm();
  }

  void _showReceiptDetail(GoodsReceiptModel receipt) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 600),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LPB Detail: ${receipt.receiptNumber}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Divider(height: 24),
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: receipt.items?.length ?? 0,
                    itemBuilder: (context, index) {
                      final item = receipt.items![index];
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
                              const SizedBox(height: 4),
                              Text(
                                  'Ordered: ${item.quantityOrdered} ${item.unit}'),
                              Text(
                                'Received: ${item.quantityReceived} ${item.unit}',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (item.notes != null && item.notes!.isNotEmpty)
                                Text(
                                  'Notes: ${item.notes}',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600),
                                )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (receipt.status == 'draft') ...[
                      ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.pop(context);
                          await _completeReceipt(receipt.id);
                        },
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Complete'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    )
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _completeReceipt(String receiptId) async {
    try {
      final repo = ref.read(goodsReceiptRepositoryProvider);
      await repo.completeReceipt(receiptId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Receipt completed successfully'),
            backgroundColor: Colors.green,
          ),
        );
        ref.invalidate(goodsReceiptStreamProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error completing receipt: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _confirmDelete(String receiptId, String receiptNumber) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete $receiptNumber?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteReceipt(receiptId);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          )
        ],
      ),
    );
  }

  Future<void> _deleteReceipt(String receiptId) async {
    try {
      final repo = ref.read(goodsReceiptRepositoryProvider);
      await repo.deleteReceipt(receiptId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Receipt deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        ref.invalidate(goodsReceiptStreamProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting receipt: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
