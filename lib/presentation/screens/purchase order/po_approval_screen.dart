import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:erp_purchasing_apps/data/providers/po_provider.dart';
import 'package:erp_purchasing_apps/data/providers/auth_providers.dart';
import 'package:erp_purchasing_apps/data/models/purchase_order_model.dart';
import 'package:intl/intl.dart';

class POApprovalScreen extends ConsumerStatefulWidget {
  const POApprovalScreen({super.key});

  @override
  ConsumerState<POApprovalScreen> createState() => _POApprovalScreenState();
}

class _POApprovalScreenState extends ConsumerState<POApprovalScreen> {
  @override
  Widget build(BuildContext context) {
    final poStream = ref.watch(poStreamProvider);
    final currentUser = ref.watch(currentUserProvider);

    // Check if user has approval permission
    final canApprove =
        currentUser?.role == 'admin' || currentUser?.role == 'purchasing';

    if (!canApprove) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('PO Approval'),
        ),
        body: const Center(
          child: Text('You do not have permission to approve POs'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
        title: const Text('PO Approval Queue'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(poStreamProvider);
            },
          )
        ],
      ),
      body: poStream.when(
        data: (pos) {
          // Filter only pending POs
          final pendingPos = pos.where((po) => po.status == 'pending').toList();

          if (pendingPos.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 64, color: Colors.green),
                  SizedBox(height: 16),
                  Text(
                    'No pending POs',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  )
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: pendingPos.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final po = pendingPos[index];
              final itemCount = po.items?.length ?? 0;

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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              po.poNumber,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Chip(
                              label: const Text(
                                'PENDING',
                                style: TextStyle(fontSize: 10),
                              ),
                              backgroundColor: Colors.orange.shade100,
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
                          ),
                        if (po.notes != null && po.notes!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Notes: ${po.notes}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => _confirmCancel(po),
                              icon: const Icon(Icons.close, size: 16),
                              label: const Text('Cancel'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: () => _confirmApprove(po),
                              icon: const Icon(Icons.check, size: 16),
                              label: const Text('Approve'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                            )
                          ],
                        )
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
                  ref.invalidate(poRepositoryProvider);
                },
                child: const Text('Retry'),
              )
            ],
          ),
        ),
      ),
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

                      // PO Info
                      _buildInfoRow('Status', po.status.toUpperCase()),
                      _buildInfoRow(
                        'Order Date',
                        DateFormat('dd MMM yyyy').format(po.orderDate),
                      ),
                      if (po.expectedDeliveryDate != null)
                        _buildInfoRow(
                          'Expected Delivery',
                          DateFormat('dd MMM yyyy')
                              .format(po.expectedDeliveryDate!),
                        ),
                      _buildInfoRow('Total Amount',
                          'Rp ${NumberFormat('#,###').format(po.totalAmount)}'),
                      if (po.notes != null && po.notes!.isNotEmpty)
                        _buildInfoRow('Notes', po.notes!),

                      const SizedBox(height: 16),
                      const Text(
                        'Items:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),

                      // Items List
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.itemName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                          'Qty: ${item.quantity} ${item.unit}'),
                                      Text(
                                        'Price: Rp ${NumberFormat('#,###').format(item.unitPrice)} * ${item.quantity}',
                                      ),
                                      Text(
                                        'Subtotal: Rp ${NumberFormat('#,###').format(item.subtotal)}',
                                        style: const TextStyle(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ]),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
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
            ));
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value),
          )
        ],
      ),
    );
  }

  void _confirmApprove(PurchaseOrderModel po) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Approve PO'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Are you sure you want to approve ${po.poNumber}?'),
                  const SizedBox(height: 8),
                  Text(
                    'Total: Rp ${NumberFormat('#,###').format(po.totalAmount)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  )
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _approvePO(po.id);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: const Text('Approve'),
                )
              ],
            ));
  }

  void _confirmCancel(PurchaseOrderModel po) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Cancel PO'),
              content: Text('Are you sure you want to cancel ${po.poNumber}'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('No'),
                ),
                ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await _cancelPO(po.id);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text('Cancel PO'))
              ],
            ));
  }

  Future<void> _approvePO(String poId) async {
    try {
      final repo = ref.read(poRepositoryProvider);
      await repo.approvePO(poId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('PO approved susccessfully'),
          backgroundColor: Colors.green,
        ));
        ref.invalidate(poStreamProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error approving PO: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Future<void> _cancelPO(String poId) async {
    try {
      final repo = ref.read(poRepositoryProvider);
      await repo.cancelPO(poId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('PO cancelled'),
          backgroundColor: Colors.orange,
        ));
        ref.invalidate(poStreamProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error cancelling PO: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }
}
