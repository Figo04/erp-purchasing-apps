import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:erp_purchasing_apps/data/models/asset_model.dart';
import 'package:erp_purchasing_apps/data/providers/asset_provider.dart';
import 'package:erp_purchasing_apps/data/providers/user_provider.dart';
import 'package:erp_purchasing_apps/data/providers/auth_providers.dart';
import 'package:intl/intl.dart';

class AssetDetailScreen extends ConsumerWidget {
  final String assetId;

  const AssetDetailScreen({super.key, required this.assetId});

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'consumable':
        return Colors.blue;
      case 'loanable':
        return Colors.purple;
      case 'saleable':
        return Colors.green;
      case 'pending':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'available':
        return Colors.green;
      case 'borrowed':
        return Colors.orange;
      case 'disposed':
        return Colors.grey;
      case 'maintenance':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'consumable':
        return Icons.inventory_2;
      case 'loanable':
        return Icons.devices;
      case 'saleable':
        return Icons.shopping_bag;
      case 'pending':
        return Icons.help_outline;
      default:
        return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final canManage =
        currentUser?.role == 'admin' || currentUser?.role == 'warehouse';
    final assetAsync = ref.watch(assetDetailProvider(assetId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Asset Detail'),
        actions: [
          if (canManage)
            PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Edit Asset'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete Asset'),
                    ],
                  ),
                )
              ],
              onSelected: (value) {
                if (value == 'edit' && assetAsync.value != null) {
                  _showEditDialog(context, ref, assetAsync.value!);
                } else if (value == 'delete' && assetAsync.value != null) {
                  _confirmDelete(context, ref, assetAsync.value!);
                }
              },
            )
        ],
      ),
      body: assetAsync.when(
        data: (asset) {
          if (asset == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('Asset not found'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(assetDetailProvider(assetId));
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✅ WARNING: Pending Classification
                  if (asset.isPending)
                    Card(
                      color: Colors.amber.shade100,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                color: Colors.amber.shade900, size: 32),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Classification Required',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.amber.shade900,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'This asset needs to be classified as Consumable, Loanable, or Saleable.',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (asset.isPending) const SizedBox(height: 16),

                  // Asset Header Card
                  Card(
                    color:
                        _getCategoryColor(asset.assetCategory).withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            _getCategoryIcon(asset.assetCategory),
                            size: 48,
                            color: _getCategoryColor(asset.assetCategory),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  asset.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  asset.assetCode,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(color: Colors.grey.shade700),
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // STATUS 1 & STATUS 2 Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          'Category (Status 1)',
                          asset.categoryDisplayName,
                          _getCategoryColor(asset.assetCategory),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildInfoCard(
                          'Status (Status 2)',
                          asset.statusDisplayName,
                          _getStatusColor(asset.status),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Quantity & Price Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          'Quantity',
                          '${asset.quantity} ${asset.assetCategory == 'loanable' ? 'unit(s)' : 'pcs'}',
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Assignment Info
                  if (asset.isBorrowed && asset.assignedToName != null)
                    Card(
                      color: Colors.orange.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.person,
                                    color: Colors.orange.shade700),
                                const SizedBox(width: 8),
                                Text(
                                  'Currently Borrowed',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange.shade700,
                                  ),
                                )
                              ],
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow('Assigned to', asset.assignedToName!),
                            if (asset.assignedDate != null)
                              _buildInfoRow(
                                'Since',
                                DateFormat('dd MMM yyyy')
                                    .format(asset.assignedDate!),
                              )
                          ],
                        ),
                      ),
                    ),
                  if (asset.isBorrowed) const SizedBox(height: 16),

                  // Additional Information
                  Text('Additional Information',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),

                  if (asset.notes != null && asset.notes!.isNotEmpty) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Notes / History:',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 8),
                            Text(asset.notes!,
                                style: const TextStyle(fontSize: 13))
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  _buildInfoRow('Created At',
                      DateFormat('dd MMM yyyy HH:mm').format(asset.createdAt)),
                  _buildInfoRow('Last Updated',
                      DateFormat('dd MMM yyyy HH:mm').format(asset.updatedAt)),
                  const SizedBox(height: 24),

                  // Action Buttons
                  if (canManage) ...[
                    Text('Actions',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),

                    // ✅ PRIORITY: Edit Asset (Always visible)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showEditDialog(context, ref, asset),
                        icon: const Icon(Icons.edit),
                        label: Text(asset.isPending
                            ? 'Set Classification & Status'
                            : 'Edit Asset'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              asset.isPending ? Colors.amber : Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    if (asset.assetCategory == 'loanable' &&
                        !asset.isPending) ...[
                      if (asset.isAvailable)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                _showAssignDialog(context, ref, asset),
                            icon: const Icon(Icons.person_add),
                            label: const Text('Assign to User'),
                          ),
                        ),
                      if (asset.isBorrowed)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                _showReturnDialog(context, ref, asset),
                            icon: const Icon(Icons.assignment_return),
                            label: const Text('Return Asset'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.green,
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                    ],
                    if (asset.assetCategory == 'consumable' &&
                        asset.quantity > 0 &&
                        !asset.isPending) ...[
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _showDecreaseQuantityDialog(context, ref, asset),
                          icon: const Icon(Icons.remove_circle_outline),
                          label: const Text('Use/Consume Item'),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ]
                ],
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
                onPressed: () => ref.invalidate(assetDetailProvider(assetId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold, color: color))
          ],
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
            child: Text('$label:',
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: Colors.grey)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontWeight: FontWeight.w500)),
          )
        ],
      ),
    );
  }

  // ✅ NEW: EDIT DIALOG - Edit both STATUS 1 & STATUS 2
  void _showEditDialog(BuildContext context, WidgetRef ref, AssetModel asset) {
    String selectedCategory = asset.assetCategory;
    String selectedStatus = asset.status;
    int selectedQuantity = asset.quantity;
    final nameController = TextEditingController(text: asset.name);
    final priceController =
        TextEditingController(text: asset.purchasePrice?.toString() ?? '');
    final notesController = TextEditingController(text: asset.notes ?? '');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
              asset.isPending ? 'Set Classification & Status' : 'Edit Asset'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Asset Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // ✅ STATUS 1: Asset Category
                const Text('Category (Status 1):',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    filled: selectedCategory == 'pending',
                    fillColor: selectedCategory == 'pending'
                        ? Colors.amber.shade50
                        : null,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'pending',
                      child: Row(
                        children: [
                          Icon(Icons.help_outline, color: Colors.amber),
                          SizedBox(width: 8),
                          Text('Pending Classification'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'consumable',
                      child: Row(
                        children: [
                          Icon(Icons.inventory_2, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Consumable'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'loanable',
                      child: Row(
                        children: [
                          Icon(Icons.devices, color: Colors.purple),
                          SizedBox(width: 8),
                          Text('Loanable'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'saleable',
                      child: Row(
                        children: [
                          Icon(Icons.shopping_bag, color: Colors.green),
                          SizedBox(width: 8),
                          Text('Saleable'),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (v) => setState(() => selectedCategory = v!),
                ),
                const SizedBox(height: 16),

                // ✅ STATUS 2: Operational Status
                const Text('Status (Status 2):',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'available', child: Text('Available')),
                    DropdownMenuItem(
                        value: 'borrowed', child: Text('Borrowed')),
                    DropdownMenuItem(
                        value: 'maintenance', child: Text('Maintenance')),
                    DropdownMenuItem(
                        value: 'disposed', child: Text('Disposed')),
                  ],
                  onChanged: (v) => setState(() => selectedStatus = v!),
                ),
                const SizedBox(height: 16),

                // Quantity
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Quantity',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (v) {
                    final val = int.tryParse(v);
                    if (val != null) selectedQuantity = val;
                  },
                  controller: TextEditingController(text: '$selectedQuantity'),
                ),
                const SizedBox(height: 16),

                // Notes
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Name is required')));
                  return;
                }

                Navigator.pop(ctx);
                await _performUpdate(
                  context,
                  ref,
                  asset.id,
                  nameController.text,
                  selectedCategory,
                  selectedStatus,
                  selectedQuantity,
                  double.tryParse(priceController.text),
                  notesController.text.isEmpty ? null : notesController.text,
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _performUpdate(
    BuildContext context,
    WidgetRef ref,
    String assetId,
    String name,
    String category,
    String status,
    int quantity,
    double? price,
    String? notes,
  ) async {
    _showLoading(context, 'Updating...');
    try {
      await ref.read(assetRepositoryProvider).updateAsset(
            id: assetId,
            name: name,
            assetCategory: category,
            status: status,
            quantity: quantity,
            purchasePrice: price,
            notes: notes,
          );

      if (!context.mounted) return;
      Navigator.pop(context);
      ref.invalidate(assetDetailProvider(assetId));
      ref.invalidate(filteredAssetListProvider);

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✓ Updated successfully'),
          backgroundColor: Colors.green));
    } catch (e) {
      Navigator.pop(context);
      _showError(context, e.toString());
    }
  }

  void _showAssignDialog(
      BuildContext context, WidgetRef ref, AssetModel asset) {
    final userListAsync = ref.read(userListProvider);
    String? selectedUserId;
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Assign Asset to User'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              userListAsync.when(
                data: (users) {
                  final activeUsers = users.where((u) => u.isActive).toList();
                  return DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                        labelText: 'Select User', border: OutlineInputBorder()),
                    items: activeUsers
                        .map((user) => DropdownMenuItem(
                            value: user.id,
                            child: Text('${user.fullName} (${user.role})')))
                        .toList(),
                    onChanged: (value) => selectedUserId = value,
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (error, _) => Text('Error: $error'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                    labelText: 'Reason (Optional)',
                    border: OutlineInputBorder()),
                maxLines: 3,
              )
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (selectedUserId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a user')));
                return;
              }
              Navigator.pop(ctx);
              await _performAssign(context, ref, asset.id, selectedUserId!,
                  reasonController.text);
            },
            child: const Text('Assign'),
          )
        ],
      ),
    );
  }

  Future<void> _performAssign(BuildContext context, WidgetRef ref,
      String assetId, String userId, String reason) async {
    _showLoading(context, 'Assigning...');
    try {
      await ref.read(assetRepositoryProvider).assignAsset(
          id: assetId,
          assignedTo: userId,
          notes: reason.isEmpty ? null : reason);

      if (!context.mounted) return;
      Navigator.pop(context);
      ref.invalidate(assetDetailProvider(assetId));
      ref.invalidate(filteredAssetListProvider);

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✓ Assigned successfully'),
          backgroundColor: Colors.green));
    } catch (e) {
      Navigator.pop(context);
      _showError(context, e.toString());
    }
  }

  void _showReturnDialog(
      BuildContext context, WidgetRef ref, AssetModel asset) {
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Return Asset'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Return asset from ${asset.assignedToName}?'),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                  labelText: 'Return Notes (Optional)',
                  border: OutlineInputBorder()),
              maxLines: 3,
            )
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _performReturn(
                  context, ref, asset.id, notesController.text.trim());
            },
            child: const Text('Return'),
          )
        ],
      ),
    );
  }

  Future<void> _performReturn(
      BuildContext context, WidgetRef ref, String assetId, String notes) async {
    _showLoading(context, 'Processing return...');
    try {
      await ref.read(assetRepositoryProvider).unassignAsset(
          id: assetId, returnNotes: notes.isEmpty ? null : notes);

      if (!context.mounted) return;
      Navigator.pop(context);
      ref.invalidate(assetDetailProvider(assetId));
      ref.invalidate(filteredAssetListProvider);

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✓ Returned successfully'),
          backgroundColor: Colors.green));
    } catch (e) {
      Navigator.pop(context);
      _showError(context, e.toString());
    }
  }

  void _showDecreaseQuantityDialog(
      BuildContext context, WidgetRef ref, AssetModel asset) {
    final qtyController = TextEditingController();
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Use/Consume Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Available: ${asset.quantity} pcs'),
            const SizedBox(height: 16),
            TextField(
              controller: qtyController,
              decoration: const InputDecoration(
                  labelText: 'Quantity', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                  labelText: 'Reason', border: OutlineInputBorder()),
              maxLines: 3,
            )
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final qty = int.tryParse(qtyController.text);
              if (qty == null || qty <= 0 || reasonController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid input')));
                return;
              }
              Navigator.pop(ctx);
              await _performDecrease(
                  context, ref, asset.id, qty, reasonController.text);
            },
            child: const Text('Confirm'),
          )
        ],
      ),
    );
  }

  Future<void> _performDecrease(BuildContext context, WidgetRef ref,
      String assetId, int qty, String reason) async {
    _showLoading(context, 'Processing...');
    try {
      await ref
          .read(assetRepositoryProvider)
          .decreaseQuantity(id: assetId, quantity: qty, reason: reason);

      if (!context.mounted) return;
      Navigator.pop(context);
      ref.invalidate(assetDetailProvider(assetId));
      ref.invalidate(filteredAssetListProvider);

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✓ Updated successfully'),
          backgroundColor: Colors.green));
    } catch (e) {
      Navigator.pop(context);
      _showError(context, e.toString());
    }
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, AssetModel asset) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Asset'),
        content: Text('Delete "${asset.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _performDelete(context, ref, asset.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _performDelete(
      BuildContext context, WidgetRef ref, String assetId) async {
    _showLoading(context, 'Deleting...');
    try {
      await ref.read(assetRepositoryProvider).deleteAsset(assetId);

      if (!context.mounted) return;
      Navigator.pop(context); // Loading
      Navigator.pop(context); // Detail screen
      ref.invalidate(filteredAssetListProvider);

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✓ Deleted successfully'),
          backgroundColor: Colors.green));
    } catch (e) {
      Navigator.pop(context);
      _showError(context, e.toString());
    }
  }

  void _showLoading(BuildContext context, String msg) {
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

  void _showError(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $msg'), backgroundColor: Colors.red));
  }
}
