import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:erp_purchasing_apps/data/models/asset_model.dart';
import 'package:erp_purchasing_apps/data/providers/asset_provider.dart';
import 'package:erp_purchasing_apps/data/providers/user_provider.dart';
import 'package:erp_purchasing_apps/data/providers/auth_providers.dart';
import 'package:intl/intl.dart';

/// Asset Detail Screen - Updated for Golang Backend (SIMPLIFIED)
/// Path: lib/presentation/screens/asset/asset_detail_screen.dart
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
                if (value == 'delete') {
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

                  // Status & Category Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          'Category',
                          asset.categoryDisplayName,
                          _getCategoryColor(asset.assetCategory),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildInfoCard(
                          'Status',
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
                      Expanded(
                        child: _buildInfoCard(
                          'Price',
                          asset.purchasePrice != null
                              ? 'Rp ${NumberFormat('#,###').format(asset.purchasePrice)}'
                              : 'N/A',
                          Colors.green,
                        ),
                      ),
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
                    if (asset.assetCategory == 'loanable') ...[
                      if (asset.isAvailable)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                _showAssignDialog(context, ref, asset),
                            icon: const Icon(Icons.person_add),
                            label: const Text('Assign to User'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      if (asset.isBorrowed)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                _showReturnDialog(context, ref, asset),
                            icon: const Icon(Icons.assignment_return),
                            label: const Text('Return Asset'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                    ],
                    if (asset.assetCategory == 'consumable' &&
                        asset.quantity > 0) ...[
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
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _showStatusChangeDialog(context, ref, asset),
                        icon: const Icon(Icons.swap_horiz),
                        label: const Text('Change Status'),
                      ),
                    ),
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

  void _showStatusChangeDialog(
      BuildContext context, WidgetRef ref, AssetModel asset) {
    String selectedStatus = asset.status;
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Change Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Current: ${asset.statusDisplayName}'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedStatus,
                decoration: const InputDecoration(
                    labelText: 'New Status', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(
                      value: 'available', child: Text('Available')),
                  DropdownMenuItem(value: 'borrowed', child: Text('Borrowed')),
                  DropdownMenuItem(
                      value: 'maintenance', child: Text('Maintenance')),
                  DropdownMenuItem(value: 'disposed', child: Text('Disposed')),
                ],
                onChanged: (v) => setState(() => selectedStatus = v!),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                    labelText: 'Reason (Optional)',
                    border: OutlineInputBorder()),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await _performStatusChange(context, ref, asset.id,
                    selectedStatus, reasonController.text);
              },
              child: const Text('Confirm'),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _performStatusChange(BuildContext context, WidgetRef ref,
      String assetId, String status, String reason) async {
    _showLoading(context, 'Updating...');
    try {
      await ref.read(assetRepositoryProvider).updateStatus(
          id: assetId, status: status, reason: reason.isEmpty ? null : reason);

      if (!context.mounted) return;
      Navigator.pop(context);
      ref.invalidate(assetDetailProvider(assetId));
      ref.invalidate(filteredAssetListProvider);

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✓ Status updated'), backgroundColor: Colors.green));
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
