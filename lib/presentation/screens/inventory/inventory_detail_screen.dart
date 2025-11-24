import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:erp_purchasing_apps/data/models/inventory_model.dart';
import 'package:erp_purchasing_apps/data/providers/inventory_provider.dart';
import 'package:erp_purchasing_apps/data/providers/auth_providers.dart';
import 'package:intl/intl.dart';

class InventoryDetailScreen extends ConsumerStatefulWidget {
  final String inventoryId;

  const InventoryDetailScreen({
    super.key,
    required this.inventoryId,
  });

  @override
  ConsumerState<InventoryDetailScreen> createState() =>
      _InventoryDetailScreenState();
}

class _InventoryDetailScreenState extends ConsumerState<InventoryDetailScreen> {
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _itemNameController;
  late TextEditingController _quantityController;
  late TextEditingController _unitController;
  late TextEditingController _locationController;
  late TextEditingController _notesController;
  String _selectedStatus = 'available';

  @override
  void initState() {
    super.initState();
    _itemNameController = TextEditingController();
    _quantityController = TextEditingController();
    _unitController = TextEditingController();
    _locationController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _initializeControllers(InventoryModel item) {
    _itemNameController.text = item.itemName;
    _quantityController.text = item.quantity.toString();
    _unitController.text = item.unit;
    _locationController.text = item.location ?? '';
    _notesController.text = item.notes ?? '';
    _selectedStatus = item.status;
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
    final currentUser = ref.watch(currentUserProvider);
    final canEdit =
        currentUser?.role == 'admin' || currentUser?.role == 'warehouse';
    final InventoryAsync =
        ref.watch(inventoryDetailProvider(widget.inventoryId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Detail'),
        actions: [
          if (canEdit && !_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() => _isEditing = false);
                ref.invalidate(inventoryDetailProvider(widget.inventoryId));
              },
            ),
        ],
      ),
      body: InventoryAsync.when(
        data: (item) {
          if (item == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('Inventory not found'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          if (!_isEditing) _initializeControllers(item);
          final isLowStock = item.quantity < 10 && item.status == 'available';

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(inventoryDetailProvider(widget.inventoryId));
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stock Card
                    Card(
                      color:
                          _getStockLevelColor(item.quantity).withOpacity(0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Stock Card
                            Card(
                              color: _getStockLevelColor(item.quantity)
                                  .withOpacity(0.1),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Icon(Icons.inventory_2,
                                        size: 48,
                                        color:
                                            _getStockLevelColor(item.quantity)),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text('Current Stock',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall),
                                          Text('${item.quantity} ${item.unit}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .headlineMedium
                                                  ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          _getStockLevelColor(
                                                              item.quantity))),
                                          if (isLowStock)
                                            const Row(
                                              children: [
                                                Icon(Icons.warning,
                                                    color: Colors.red,
                                                    size: 16),
                                                SizedBox(width: 4),
                                                Text('Low Stock Alert!',
                                                    style: TextStyle(
                                                        color: Colors.red,
                                                        fontWeight:
                                                            FontWeight.bold))
                                              ],
                                            )
                                        ],
                                      ),
                                    ),
                                    Chip(
                                      label: Text(item.status.toUpperCase(),
                                          style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold)),
                                      backgroundColor:
                                          _getStatusColor(item.status)
                                              .withOpacity(0.2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Form Fiels
                            Text('Item Information',
                                style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 16),

                            TextFormField(
                              initialValue: item.itemName,
                              decoration: const InputDecoration(
                                  labelText: 'Item Name',
                                  border: OutlineInputBorder()),
                              enabled: false,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _quantityController,
                                    decoration: const InputDecoration(
                                        labelText: 'Quantity',
                                        border: OutlineInputBorder()),
                                    keyboardType: TextInputType.number,
                                    enabled: _isEditing,
                                    validator: (v) => v == null || v.isEmpty
                                        ? 'Required'
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    initialValue: item.unit,
                                    decoration: const InputDecoration(
                                        labelText: 'Unit',
                                        border: OutlineInputBorder()),
                                    enabled: false,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            if (_isEditing)
                              DropdownButtonFormField<String>(
                                value: _selectedStatus,
                                decoration: const InputDecoration(
                                    labelText: 'Status',
                                    border: OutlineInputBorder()),
                                items: const [
                                  DropdownMenuItem(
                                      value: 'available',
                                      child: Text('Available')),
                                  DropdownMenuItem(
                                      value: 'reserved',
                                      child: Text('Reserved')),
                                  DropdownMenuItem(
                                      value: 'damaged', child: Text('Damaged')),
                                  DropdownMenuItem(
                                      value: 'disposed',
                                      child: Text('Disposed')),
                                ],
                                onChanged: (v) =>
                                    setState(() => _selectedStatus = v!),
                              )
                            else
                              TextFormField(
                                initialValue: item.status.toUpperCase(),
                                decoration: const InputDecoration(
                                    labelText: 'Status',
                                    border: OutlineInputBorder()),
                                enabled: false,
                              ),
                            const SizedBox(height: 16),

                            TextFormField(
                              controller: _locationController,
                              decoration: const InputDecoration(
                                  labelText: 'Location',
                                  border: OutlineInputBorder(),
                                  hintText: 'Warehouse location'),
                              enabled: _isEditing,
                            ),
                            const SizedBox(height: 16),

                            TextFormField(
                              controller: _notesController,
                              decoration: const InputDecoration(
                                  labelText: 'Notes',
                                  border: OutlineInputBorder()),
                              maxLines: 3,
                              enabled: _isEditing,
                            ),
                            const SizedBox(height: 16),

                            if (item.receivedDate != null)
                              _buildInfoRow(
                                  'Received Date',
                                  DateFormat('dd MMM yyyy')
                                      .format(item.receivedDate!)),
                            _buildInfoRow(
                                'Created At',
                                DateFormat('dd MMM yyyy HH:mm')
                                    .format(item.createdAt)),
                            _buildInfoRow(
                                'Last Updated',
                                DateFormat('dd MMM yyyy HH:mm')
                                    .format(item.updatedAt)),
                            const SizedBox(height: 24),

                            // action buttons
                            if (_isEditing)
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () => _saveChanges(item),
                                  child: const Text('Save Changes'),
                                ),
                              )
                            else if (canEdit)
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () =>
                                          _showAdjustDialog(item, false),
                                      icon: const Icon(
                                          Icons.remove_circle_outline),
                                      label: const Text('Stock Out'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () =>
                                          _showAdjustDialog(item, true),
                                      icon:
                                          const Icon(Icons.add_circle_outline),
                                      label: const Text('Stock In'),
                                    ),
                                  ),
                                ],
                              )
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              ElevatedButton(
                onPressed: () =>
                    ref.invalidate(inventoryDetailProvider(widget.inventoryId)),
                child: const Text('Retry'),
              ),
            ],
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
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveChanges(InventoryModel item) async {
    if (!_formKey.currentState!.validate()) return;

    _showLoading('Updating...');
    try {
      await ref.read(inventoryRepositoryProvider).updateInventory(
            id: item.id,
            quantity: int.parse(_quantityController.text),
            location: _locationController.text.isEmpty
                ? null
                : _locationController.text,
            status: _selectedStatus,
            notes: _notesController.text.isEmpty ? null : _notesController.text,
          );

      if (!mounted) return;
      Navigator.pop(context);
      ref.invalidate(inventoryDetailProvider(widget.inventoryId));
      ref.invalidate(filteredInventoryListProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('✓ Updated successfully'),
            backgroundColor: Colors.green),
      );
      setState(() => _isEditing = false);
    } catch (e) {
      Navigator.pop(context);
      _showError(e.toString());
    }
  }

  void _showAdjustDialog(InventoryModel item, bool isStockIn) {
    final qtyCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isStockIn ? 'Stock In' : 'Stock Out'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current: ${item.quantity} ${item.unit}'),
            const SizedBox(height: 16),
            TextField(
              controller: qtyCtrl,
              decoration: const InputDecoration(
                  labelText: 'Quantity', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                  labelText: 'Reason', border: OutlineInputBorder()),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final qty = int.tryParse(qtyCtrl.text);
              if (qty == null || qty <= 0 || reasonCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid input')));
                return;
              }
              Navigator.pop(ctx);
              _performAdjust(item.id, isStockIn ? qty : -qty, reasonCtrl.text);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<void> _performAdjust(String id, int qty, String reason) async {
    _showLoading('Processing...');
    try {
      await ref
          .read(inventoryRepositoryProvider)
          .adjustInventory(id: id, quantity: qty, reason: reason);

      if (!mounted) return;
      Navigator.pop(context);
      ref.invalidate(inventoryDetailProvider(widget.inventoryId));
      ref.invalidate(filteredInventoryListProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('✓ Adjustment successful'),
            backgroundColor: Colors.green),
      );
    } catch (e) {
      Navigator.pop(context);
      _showError(e.toString());
    }
  }

  void _showLoading(String msg) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(msg),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed: $msg'), backgroundColor: Colors.red),
    );
  }
}
