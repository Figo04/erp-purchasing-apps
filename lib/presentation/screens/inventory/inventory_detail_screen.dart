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
  ConsumerState<InventoryDetailScreen> createState() => _InventoryDetailScreenState();
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
    final canEdit = currentUser?.role == 'admin' || currentUser?.role == 'warehouse';

    return FutureBuilder<InventoryModel?>(
      future: ref.read(inventoryRepositoryProvider).getInventoryById(widget.inventoryId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error ?? "Item not found"}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          );
        }

        final item = snapshot.data!;
        if (!_isEditing) {
          _initializeControllers(item);
        }

        final isLowStock = item.quantity < 10 && item.status == 'available';

        return Scaffold(
          appBar: AppBar(
            title: const Text('Inventory Detail'),
            actions: [
              if (canEdit && !_isEditing)
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    setState(() {
                      _isEditing = true;
                    });
                  },
                ),
              if (_isEditing)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _isEditing = false;
                      _initializeControllers(item);
                    });
                  },
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stock Level Indicator
                  Card(
                    color: _getStockLevelColor(item.quantity).withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.inventory_2,
                            size: 48,
                            color: _getStockLevelColor(item.quantity),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Current Stock',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                Text(
                                  '${item.quantity} ${item.unit}',
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: _getStockLevelColor(item.quantity),
                                  ),
                                ),
                                if (isLowStock)
                                  Row(
                                    children: [
                                      Icon(Icons.warning, color: Colors.red, size: 16),
                                      const SizedBox(width: 4),
                                      const Text(
                                        'Low Stock Alert!',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                          Chip(
                            label: Text(
                              item.status.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            backgroundColor: _getStatusColor(item.status).withOpacity(0.2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Item Details Form
                  Text(
                    'Item Information',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _itemNameController,
                    decoration: const InputDecoration(
                      labelText: 'Item Name',
                      border: OutlineInputBorder(),
                    ),
                    enabled: _isEditing,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter item name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _quantityController,
                          decoration: const InputDecoration(
                            labelText: 'Quantity',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          enabled: _isEditing,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Invalid number';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _unitController,
                          decoration: const InputDecoration(
                            labelText: 'Unit',
                            border: OutlineInputBorder(),
                          ),
                          enabled: _isEditing,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (_isEditing)
                    DropdownButtonFormField<String>(
                      initialValue: _selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'available', child: Text('Available')),
                        DropdownMenuItem(value: 'reserved', child: Text('Reserved')),
                        DropdownMenuItem(value: 'damaged', child: Text('Damaged')),
                        DropdownMenuItem(value: 'disposed', child: Text('Disposed')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedStatus = value!;
                        });
                      },
                    )
                  else
                    TextFormField(
                      initialValue: item.status.toUpperCase(),
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                      ),
                      enabled: false,
                    ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      labelText: 'Location',
                      border: OutlineInputBorder(),
                      hintText: 'Warehouse location',
                    ),
                    enabled: _isEditing,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes / History',
                      border: OutlineInputBorder(),
                      hintText: 'Additional notes',
                    ),
                    maxLines: 5,
                    enabled: _isEditing,
                  ),
                  const SizedBox(height: 16),

                  // Additional Info
                  if (item.receivedDate != null)
                    _buildInfoRow(
                      'Received Date',
                      DateFormat('dd MMM yyyy').format(item.receivedDate!),
                    ),
                  _buildInfoRow(
                    'Created At',
                    DateFormat('dd MMM yyyy HH:mm').format(item.createdAt),
                  ),
                  _buildInfoRow(
                    'Last Updated',
                    DateFormat('dd MMM yyyy HH:mm').format(item.updatedAt),
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  if (_isEditing)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _saveChanges(item),
                        child: const Text('Save Changes'),
                      ),
                    )
                  else if (canEdit) ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _showStockOutDialog(item),
                            icon: const Icon(Icons.remove_circle_outline),
                            label: const Text('Stock Out'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _showStockAdjustmentDialog(item),
                            icon: const Icon(Icons.tune),
                            label: const Text('Adjustment'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _showStatusChangeDialog(item),
                        icon: const Icon(Icons.swap_horiz),
                        label: const Text('Change Status'),
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

    final repository = ref.read(inventoryRepositoryProvider);
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Updating...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      await repository.updateInventory(
        id: item.id,
        itemName: _itemNameController.text,
        quantity: int.parse(_quantityController.text),
        unit: _unitController.text,
        location: _locationController.text.isEmpty ? null : _locationController.text,
        status: _selectedStatus,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      navigator.pop(); // Close loading
      ref.invalidate(inventoryStreamProvider);

      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 16),
              Text('Inventory updated successfully'),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        _isEditing = false;
      });
    } catch (e) {
      navigator.pop();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showStockOutDialog(InventoryModel item) {
    final quantityController = TextEditingController();
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Stock Out'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Available Stock: ${item.quantity} ${item.unit}'),
            const SizedBox(height: 16),
            TextFormField(
              controller: quantityController,
              decoration: const InputDecoration(
                labelText: 'Quantity Out',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason',
                border: OutlineInputBorder(),
                hintText: 'e.g., Used in production',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final quantity = int.tryParse(quantityController.text);
              final reason = reasonController.text.trim();

              if (quantity == null || quantity <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid quantity')),
                );
                return;
              }

              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter reason')),
                );
                return;
              }

              Navigator.pop(dialogContext);
              await _performStockOut(item.id, quantity, reason);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<void> _performStockOut(String id, int quantity, String reason) async {
    final repository = ref.read(inventoryRepositoryProvider);
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Processing stock out...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      await repository.stockOut(
        id: id,
        quantityOut: quantity,
        reason: reason,
      );

      navigator.pop();
      ref.invalidate(inventoryStreamProvider);

      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Stock out successful'),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {}); // Refresh UI
    } catch (e) {
      navigator.pop();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showStockAdjustmentDialog(InventoryModel item) {
    final adjustmentController = TextEditingController();
    final reasonController = TextEditingController();
    String adjustmentType = 'add';

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Stock Adjustment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Current Stock: ${item.quantity} ${item.unit}'),
              const SizedBox(height: 16),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'add', label: Text('Add (+)')),
                  ButtonSegment(value: 'subtract', label: Text('Subtract (-)')),
                ],
                selected: {adjustmentType},
                onSelectionChanged: (Set<String> newSelection) {
                  setDialogState(() {
                    adjustmentType = newSelection.first;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: adjustmentController,
                decoration: const InputDecoration(
                  labelText: 'Adjustment Quantity',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Physical count correction',
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final quantity = int.tryParse(adjustmentController.text);
                final reason = reasonController.text.trim();

                if (quantity == null || quantity <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid quantity')),
                  );
                  return;
                }

                if (reason.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter reason')),
                  );
                  return;
                }

                final adjustmentQty = adjustmentType == 'add' ? quantity : -quantity;

                Navigator.pop(dialogContext);
                await _performStockAdjustment(item.id, adjustmentQty, reason);
              },
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _performStockAdjustment(String id, int adjustment, String reason) async {
    final repository = ref.read(inventoryRepositoryProvider);
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Processing adjustment...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      await repository.stockAdjustment(
        id: id,
        adjustmentQuantity: adjustment,
        reason: reason,
      );

      navigator.pop();
      ref.invalidate(inventoryStreamProvider);

      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Stock adjustment successful'),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {});
    } catch (e) {
      navigator.pop();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showStatusChangeDialog(InventoryModel item) {
    String selectedStatus = item.status;
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Change Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Current Status: ${item.status.toUpperCase()}'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'New Status',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'available', child: Text('Available')),
                  DropdownMenuItem(value: 'reserved', child: Text('Reserved')),
                  DropdownMenuItem(value: 'damaged', child: Text('Damaged')),
                  DropdownMenuItem(value: 'disposed', child: Text('Disposed')),
                ],
                onChanged: (value) {
                  setDialogState(() {
                    selectedStatus = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason (Optional)',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Reserved for project X',
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedStatus == item.status) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Status unchanged')),
                  );
                  return;
                }

                Navigator.pop(dialogContext);
                await _performStatusChange(
                  item.id,
                  selectedStatus,
                  reasonController.text.trim(),
                );
              },
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _performStatusChange(String id, String status, String reason) async {
    final repository = ref.read(inventoryRepositoryProvider);
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Updating status...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      await repository.updateStatus(
        id: id,
        status: status,
        reason: reason.isEmpty ? null : reason,
      );

      navigator.pop();
      ref.invalidate(inventoryStreamProvider);

      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Status updated successfully'),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {});
    } catch (e) {
      navigator.pop();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}