import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/providers/po_provider.dart';
import '../../../data/providers/auth_providers.dart';
import '../../../data/models/purchase_order_model.dart';
import 'package:intl/intl.dart';

class GoodsReceivingScreen extends ConsumerStatefulWidget {
  const GoodsReceivingScreen({super.key});

  @override
  ConsumerState<GoodsReceivingScreen> createState() =>
      _GoodsReceivingScreenState();
}

class _GoodsReceivingScreenState extends ConsumerState<GoodsReceivingScreen> {
  String _filterStatus = 'approved';

  @override
  Widget build(BuildContext context) {
    final poStream = ref.watch(poStreamProvider);
    final currentUser = ref.watch(currentUserProvider);

    // Check if user has receiving permission
    final canReceive =
        currentUser?.role == 'admin' || currentUser?.role == 'warehouse';

    if (!canReceive) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Receiving'),
        ),
        body: const Center(
          child: Text('You do not have permission to receive goods'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
        title: const Text('Goods Receiving'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(poStreamProvider);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            padding: const EdgeInsets.all(8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: poStream.when(
                data: (pos) {
                  final approvedCount =
                      pos.where((po) => po.status == 'approved').length;
                  final receivedCount =
                      pos.where((po) => po.status == 'received').length;

                  return Row(
                    children: [
                      _buildFilterChip('approved', 'Approved', approvedCount),
                      const SizedBox(width: 8),
                      _buildFilterChip('received', 'Received', receivedCount),
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
                // Filter POs
                final filteredPOs =
                    pos.where((po) => po.status == _filterStatus).toList();

                if (filteredPOs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _filterStatus == 'approved'
                              ? Icons.local_shipping
                              : Icons.check_circle,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _filterStatus == 'approved'
                              ? 'No POs waiting for receiving'
                              : 'No received POs',
                          style:
                              const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
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
                    final isApproved = po.status == 'approved';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      child: InkWell(
                        onTap: () => _showPODetail(po),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    po.poNumber,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Chip(
                                    label: Text(
                                      po.status.toUpperCase(),
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                    backgroundColor: isApproved
                                        ? Colors.blue.shade100
                                        : Colors.green.shade100,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('Items: $itemCount'),
                              Text(
                                'Total: Rp ${NumberFormat('#,###').format(po.totalAmount)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue,
                                ),
                              ),
                              Text(
                                'Order Date: ${DateFormat('dd MMM yyyy').format(po.orderDate)}',
                              ),
                              if (po.expectedDeliveryDate != null)
                                Text(
                                  'Expected: ${DateFormat('dd MMM yyyy').format(po.expectedDeliveryDate!)}',
                                  style: TextStyle(
                                    color: po.expectedDeliveryDate!
                                            .isBefore(DateTime.now())
                                        ? Colors.red
                                        : Colors.grey.shade700,
                                  ),
                                ),
                              if (isApproved) ...[
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () => _showReceiveDialog(po),
                                    icon: const Icon(Icons.check_circle,
                                        size: 18),
                                    label: const Text('Mark as Received'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
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
                    ElevatedButton(
                      onPressed: () {
                        ref.invalidate(poStreamProvider);
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
        });
      },
    );
  }

  void _showPODetail(PurchaseOrderModel po) {
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
                  'PO Detail: ${po.poNumber}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Divider(height: 24),
                Text('Status: ${po.status.toUpperCase()}'),
                Text(
                    'Order Date: ${DateFormat('dd MMM yyyy').format(po.orderDate)}'),
                Text(
                    'Total: Rp ${NumberFormat('#,###').format(po.totalAmount)}'),
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
                                'Subtotal: Rp ${NumberFormat('#,###').format(item.subtotal)}',
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showReceiveDialog(PurchaseOrderModel po) {
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Receive Goods'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PO: ${po.poNumber}'),
              Text('Items: ${po.items?.length ?? 0}'),
              Text(
                'Total: Rp ${NumberFormat('#,###').format(po.totalAmount)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Received Date:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: Text(DateFormat('dd MMM yyyy').format(selectedDate)),
                trailing: IconButton(
                  icon: const Icon(Icons.edit_calendar),
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: po.orderDate,
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setDialogState(() {
                        selectedDate = date;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Confirm that all items have been received?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _receivePO(po.id, selectedDate);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: const Text('Confirm Receive'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _receivePO(String poId, DateTime receivedDate) async {
    try {
      final repo = ref.read(poRepositoryProvider);
      await repo.receivePO(poId, receivedDate);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Goods received successfully'),
            backgroundColor: Colors.green,
          ),
        );
        ref.invalidate(poStreamProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error receiving goods: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
