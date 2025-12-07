import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:erp_purchasing_apps/data/providers/po_provider.dart';
import 'package:erp_purchasing_apps/data/providers/auth_providers.dart';
import 'package:erp_purchasing_apps/data/models/purchase_order_model.dart';
import 'package:erp_purchasing_apps/presentation/screens/purchase order/po_form_screen.dart';

class POListScreen extends ConsumerStatefulWidget {
  const POListScreen({super.key});

  @override
  ConsumerState<POListScreen> createState() => _POListScreenState();
}

class _POListScreenState extends ConsumerState<POListScreen> {
  String? _selectedStatusFilter;
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

  Color _getShipmentStatusColor(String shipmentStatus) {
    switch (shipmentStatus) {
      case 'not_shipped':
        return Colors.grey;
      case 'partial_shipped':
        return Colors.orange;
      case 'fully_shipped':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _showDetailDialog(PurchaseOrderModel po) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.shopping_cart,
                          size: 32, color: Color(0xFF1ABC9C)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              po.poNumber,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              po.supplierName ?? 'Unknown Supplier',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(po.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          po.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(po.status),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),

                  _buildDetailRow('Order Date',
                      DateFormat('dd MMM yyyy').format(po.orderDate)),
                  if (po.expectedDeliveryDate != null)
                    _buildDetailRow(
                        'Expected Delivery',
                        DateFormat('dd MMM yyyy')
                            .format(po.expectedDeliveryDate!)),
                  _buildDetailRow('Total Amount',
                      'Rp ${NumberFormat('#,###').format(po.totalAmount)}'),
                  _buildDetailRow('Shipment Status',
                      po.shipmentStatus.replaceAll('_', ' ').toUpperCase()),
                  if (po.prNumbers != null && po.prNumbers!.isNotEmpty)
                    _buildDetailRow('Related PRs', po.prNumbers!.join(', ')),
                  if (po.notes != null && po.notes!.isNotEmpty)
                    _buildDetailRow('Notes', po.notes!),

                  const Divider(height: 24),

                  const Text(
                    'Items',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (po.items != null && po.items!.isNotEmpty)
                    ...po.items!.map((item) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.itemName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      '${item.quantity} ${item.unit} * Rp ${NumberFormat('#,###').format(item.unitPrice)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                'Rp ${NumberFormat('#,###').format(item.subtotal)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            ],
                          ),
                        )),

                  const SizedBox(height: 24),

                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (po.status == 'pending') ...[
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _cancelPO(po);
                          },
                          style:
                              TextButton.styleFrom(foregroundColor: Colors.red),
                          child: const Text('Cancel PO'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _approvePO(po);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          child: const Text('Approve'),
                        ),
                      ] else
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
      ),
    );
  }

  Future<void> _approvePO(PurchaseOrderModel po) async {
    try {
      await ref.read(poNotifierProvider.notifier).approvePO(po.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PO ${po.poNumber} approved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to approve: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cancelPO(PurchaseOrderModel po) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel PO'),
        content: Text('Are you sure you want to cancel ${po.poNumber}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref.read(poNotifierProvider.notifier).cancelPO(po.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('PO ${po.poNumber} cancelled'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to cancel: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _navigateToForm({String? poId, String? prId}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => POFormScreen(),
      ),
    ).then(
      (_) {
        ref.read(poNotifierProvider.notifier);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final posState = ref.watch(poNotifierProvider);
    final currentUser = ref.watch(currentUserProvider);
    final canApprove =
        currentUser?.role == 'admin' || currentUser?.role == 'kadiv';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.go('/dashboard'),
        ),
        title: const Text(
          'Purchase Orders',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
            onPressed: () {
              ref.read(poNotifierProvider.notifier).refresh();
            },
          ),
        ],
      ),
      body: Column(children: [
        // Filter Section
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Search & Create Button
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search PO...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: () {
                                  _searchController.clear();
                                  ref
                                      .read(poSearchQueryProvider.notifier)
                                      .state = '';
                                },
                              )
                            : null,
                      ),
                      onChanged: (value) {
                        ref.read(poSearchQueryProvider.notifier).state = value;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () => _navigateToForm(),
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text('Create PO'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1ABC9C),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadiusGeometry.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Status Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('All'),
                      selected: _selectedStatusFilter == null,
                      onSelected: (selected) {
                        setState(() {
                          _selectedStatusFilter = null;
                          ref.read(poStatusFilterProvider.notifier).state =
                              null;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Pending'),
                      selected: _selectedStatusFilter == 'pending',
                      onSelected: (selected) {
                        setState(() {
                          _selectedStatusFilter = selected ? 'pending' : null;
                          ref.read(poStatusFilterProvider.notifier).state =
                              selected ? 'pending' : null;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Approved'),
                      selected: _selectedStatusFilter == 'Approved',
                      onSelected: (selected) {
                        setState(() {
                          _selectedStatusFilter = selected ? 'approved' : null;
                          ref.read(poStatusFilterProvider.notifier).state =
                              selected ? 'approved' : null;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Received'),
                      selected: _selectedStatusFilter == 'received',
                      onSelected: (selected) {
                        setState(() {
                          _selectedStatusFilter = selected ? 'received' : null;
                          ref.read(poStatusFilterProvider.notifier).state =
                              selected ? 'received' : null;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Cancelled'),
                      selected: _selectedStatusFilter == 'cancelled',
                      onSelected: (selected) {
                        setState(() {
                          _selectedStatusFilter = selected ? 'cancelled' : null;
                          ref.read(poStatusFilterProvider.notifier).state =
                              selected ? 'cancelled' : null;
                        });
                      },
                    )
                  ],
                ),
              )
            ],
          ),
        ),

        const Divider(height: 1),

        // PO Table
        Expanded(
          child: posState.when(
            data: (pos) {
              // Apply filters
              var filteredPOs = pos;

              if (_selectedStatusFilter != null) {
                filteredPOs = filteredPOs
                    .where((po) => po.status == _selectedStatusFilter)
                    .toList();
              }

              if (filteredPOs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shopping_cart_checkout_outlined,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No purchase orders found',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      )
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  await ref.read(poNotifierProvider.notifier).refresh();
                },
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ]),
                    child: DataTable(
                      headingRowHeight: 56,
                      dataRowHeight: 72,
                      columnSpacing: 24,
                      horizontalMargin: 24,
                      headingRowColor: MaterialStateProperty.all(
                        const Color(0xFFF8F9FA),
                      ),
                      columns: const [
                        DataColumn(
                            label: Text(
                          'PO NUMBER',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13),
                        )),
                        DataColumn(
                            label: Text(
                          'SUPPLIER',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13),
                        )),
                        DataColumn(
                            label: Text(
                          'ORDER DATE',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13),
                        )),
                        DataColumn(
                            label: Text(
                          'TOTAL AMOUNT',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13),
                        )),
                        DataColumn(
                            label: Text(
                          'STATUS',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13),
                        )),
                        DataColumn(
                            label: Text(
                          'SHIPMENT',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13),
                        )),
                        DataColumn(
                          label: Text(
                            'ACTIONS',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ],
                      rows: filteredPOs.map((po) {
                        return DataRow(
                          cells: [
                            DataCell(
                              InkWell(
                                onTap: () => _showDetailDialog(po),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1ABC9C)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    po.poNumber,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                      color: Color(0xFF1ABC9C),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                po.supplierName ?? 'Unknown',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                DateFormat('dd MMM yyyy').format(po.orderDate),
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            DataCell(
                              Text(
                                'Rp ${NumberFormat('#,###').format(po.totalAmount)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(po.status)
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  po.status.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _getStatusColor(po.status),
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      _getShipmentStatusColor(po.shipmentStatus)
                                          .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  po.shipmentStatus
                                      .replaceAll('_', ' ')
                                      .toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: _getShipmentStatusColor(
                                        po.shipmentStatus),
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.visibility_outlined,
                                        size: 20),
                                    color: Colors.grey.shade600,
                                    tooltip: 'View',
                                    onPressed: () => _showDetailDialog(po),
                                  ),
                                  if (po.status == 'pending' && canApprove)
                                    IconButton(
                                      icon: const Icon(
                                          Icons.check_circle_outline,
                                          size: 20),
                                      color: Colors.green.shade600,
                                      tooltip: 'Approve',
                                      onPressed: () => _approvePO(po),
                                    ),
                                  if (po.status == 'pending')
                                    IconButton(
                                      icon: const Icon(Icons.cancel_outlined,
                                          size: 20),
                                      color: Colors.red.shade600,
                                      tooltip: 'Cancel',
                                      onPressed: () => _cancelPO(po),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (error, stackTrace) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: $error'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      ref.read(poNotifierProvider.notifier).refresh();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  )
                ],
              ),
            ),
          ),
        )
      ]),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToForm(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
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
