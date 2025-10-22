import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:erp_purchasing_apps/data/models/purchase_order_model.dart';
import 'package:erp_purchasing_apps/data/repositories/po_repository.dart';

class SupplierPOListScreen extends ConsumerStatefulWidget {
  const SupplierPOListScreen({super.key});

  @override
  ConsumerState<SupplierPOListScreen> createState() =>
      _SupplierPOListScreenState();
}

class _SupplierPOListScreenState extends ConsumerState<SupplierPOListScreen> {
  List<PurchaseOrderModel> _pos = [];
  bool _isLoading = true;
  String? _supplierId;

  @override
  void initState() {
    super.initState();
    // ✅ Pakai addPostFrameCallback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPOs();
    });
  }

  Future<void> _loadPOs() async {
    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final userEmail = supabase.auth.currentUser?.email;

      if (userEmail == null) throw Exception('Not loggen in');

      // Get supplier ID
      final supplierResponse = await supabase
          .from('suppliers')
          .select('id')
          .eq('auth_email', userEmail)
          .single();

      _supplierId = supplierResponse['id'];

      // Get POs for this supplier
      final poRepo = PoRepository();
      final pos = await poRepo.getPOsBySupplier(_supplierId!);

      if (mounted) {
        setState(() {
          _pos = pos;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading POs: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'received':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/supplier/dashboard'),
        ),
        title: const Text('My Purchase Orders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPOs,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_cart_checkout_outlined,
                          size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'No purchase orders found',
                        style: TextStyle(
                            fontSize: 16, color: Colors.grey.shade600),
                      )
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _pos.length,
                  itemBuilder: (context, index) {
                    final po = _pos[index];
                    final itemCount = po.items?.length ?? 0;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () => _showPODetail(po),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          po.poNumber,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Date: ${DateFormat('dd MMM yyyy').format(po.orderDate)}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                  Chip(
                                    label: Text(
                                      po.status.toUpperCase(),
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                    backgroundColor: _getStatusColor(po.status)
                                        .withOpacity(0.2),
                                    side: BorderSide(
                                        color: _getStatusColor(po.status)),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),

                              // Details
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildInfoItem(
                                      Icons.inventory_2,
                                      'Items',
                                      itemCount.toString(),
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildInfoItem(
                                      Icons.attach_money,
                                      'Total',
                                      'Rp ${NumberFormat('#,###').format(po.totalAmount)}',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Action Button
                              if (po.status == 'approved')
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      context.go(
                                          '/supplier/shipment/create?poId=${po.id}');
                                    },
                                    icon: const Icon(Icons.local_shipping,
                                        size: 18),
                                    label: const Text('Create Shipment'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                )
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showPODetail(PurchaseOrderModel po) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'PO Detail',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 16),

                // PO Info
                Text(
                  po.poNumber,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Status: ${po.status.toUpperCase()}'),
                Text(
                    'Order Date: ${DateFormat('dd MMM yyyy').format(po.orderDate)}'),
                if (po.expectedDeliveryDate != null)
                  Text(
                      'Expected: ${DateFormat('dd MMM yyyy').format(po.expectedDeliveryDate!)}'),
                Text(
                    'Total: Rp ${NumberFormat('#,###').format(po.totalAmount)}'),
                if (po.notes != null && po.notes!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Notes: ${po.notes}'),
                ],
                const SizedBox(height: 24),

                // Items
                Text(
                  'Items:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
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
                              const SizedBox(height: 4),
                              Text('Quantity: ${item.quantity} ${item.unit}'),
                              Text(
                                'Unit Price: Rp ${NumberFormat('#,###').format(item.subtotal)}',
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

                // Actions
                if (po.status == 'approved')
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        context.go('/supplier/shipment/create?poId=${po.id}');
                      },
                      icon: const Icon(Icons.local_shipping),
                      label: const Text('Create Shipment'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
