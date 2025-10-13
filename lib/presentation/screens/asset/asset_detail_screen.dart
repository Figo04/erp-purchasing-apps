import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:erp_purchasing_apps/data/models/asset_model.dart';
import 'package:erp_purchasing_apps/data/providers/asset_provider.dart';
import 'package:erp_purchasing_apps/data/providers/user_provider.dart';
import 'package:erp_purchasing_apps/data/providers/auth_providers.dart';
import 'package:erp_purchasing_apps/presentation/screens/asset/asset_form_screen.dart';
import 'package:intl/intl.dart';

class AssetDetailScreen extends ConsumerStatefulWidget {
  final String assetId;

  const AssetDetailScreen({
    super.key,
    required this.assetId,
  });

  @override
  ConsumerState<AssetDetailScreen> createState() => _AssetDetailScreenState();
}

class _AssetDetailScreenState extends ConsumerState<AssetDetailScreen> {
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
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final canManage =
        currentUser?.role == 'admin' || currentUser?.role == 'warehouse';

    return FutureBuilder<AssetModel?>(
      future: ref.read(assetRepositoryProvider).getAssetById(widget.assetId),
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
                  Text('Error: ${snapshot.error ?? "Asset not found"}'),
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

        final asset = snapshot.data!;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Asset Detail'),
            actions: [
              if (canManage)
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AssetFormScreen(assetId: asset.id),
                      ),
                    ).then(
                      (_) {
                        ref.invalidate(assetStreamProvider);
                        setState(() {});
                      },
                    );
                  },
                ),
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
                      _confirmDelete(asset);
                    }
                  },
                )
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Asset Header Card
                Card(
                  color: _getCategoryColor(asset.category).withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          _getCategoryIcon(asset.category),
                          size: 48,
                          color: _getCategoryColor(asset.category),
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
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                asset.assetCode,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Colors.grey.shade700,
                                    ),
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                //Status & Category Row
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoCard(
                        'Category',
                        asset.category.toUpperCase(),
                        _getCategoryColor(asset.category),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildInfoCard(
                        'Status',
                        asset.status.toUpperCase(),
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
                        '${asset.quantity} ${asset.category == 'loanable' ? 'unit(s)' : 'pcs'}',
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

                // Assignment Info (if borrowed)
                if (asset.status == 'borrowed' && asset.assignedToName != null)
                  Card(
                    color: Colors.orange.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.person, color: Colors.orange.shade700),
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
                          _builInfoRow('Assigned to', asset.assignedToName!),
                          if (asset.assignedDate != null)
                            _builInfoRow(
                              'Since',
                              DateFormat('dd MMM yyyy')
                                  .format(asset.assignedDate!),
                            )
                        ],
                      ),
                    ),
                  ),
                if (asset.status == 'borrowed') const SizedBox(height: 16),

                // Additional Information
                Text(
                  'Additional Information',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),

                if (asset.notes != null && asset.notes!.isNotEmpty) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Notes / History:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            asset.notes!,
                            style: const TextStyle(fontSize: 13),
                          )
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                _builInfoRow('Created At',
                    DateFormat('dd MMM yyyy HH:mm').format(asset.createdAt)),
                _builInfoRow('Last Updated',
                    DateFormat('dd MMM yyyy HH:mm').format(asset.updatedAt)),
                const SizedBox(height: 24),

                // Action Buttons (Admin/Warehouse only)
                if (canManage) ...[
                  Text(
                    'Actions',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),

                  // Assign/Return Button
                  if (asset.category == 'loadnable') ...[
                    if (asset.status == 'available')
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _showAssignDialog(asset),
                          icon: const Icon(Icons.person_add),
                          label: const Text('Assign to User'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    if (asset.status == 'borrowed')
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _showReturnDialog(asset),
                          icon: const Icon(Icons.assignment_return),
                          label: const Text('Return Asset'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    SizedBox(height: 8),
                  ],

                  // Decrease Quantity (Consumble Only)
                  if (asset.category == 'consumable' && asset.quantity > 0) ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _showDecreaseQuantityDialog(asset),
                        icon: const Icon(Icons.remove_circle_outline),
                        label: const Text('Use/Consume Item'),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Change Status
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showStatusChangeDialog(asset),
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
    );
  }

  Widget _buildInfoCard(String label, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _builInfoRow(String label, String value) {
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
          )
        ],
      ),
    );
  }

  void _showAssignDialog(AssetModel asset) {
    final userListAsync = ref.read(userListProvider);
    String? selectedUserId;
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
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
                      labelText: 'Select User',
                      border: OutlineInputBorder(),
                    ),
                    items: activeUsers.map((user) {
                      return DropdownMenuItem(
                        value: user.id,
                        child: Text('${user.fullName} (${user.role})'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      selectedUserId = value;
                    },
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (error, _) => Text('Error: $error'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              )
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (selectedUserId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select a user')),
                );
                return;
              }

              Navigator.pop(dialogContext);
              await _performAssign(
                asset.id,
                selectedUserId!,
                reasonController.text.trim(),
              );
            },
            child: const Text('Assign'),
          )
        ],
      ),
    );
  }

  Future<void> _performAssign(
      String assetId, String userId, String reason) async {
    final repository = ref.read(assetRepositoryProvider);
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
                Text('Assigning asset...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      await repository.assignAsset(
        id: assetId,
        userId: userId,
        reason: reason.isEmpty ? null : reason,
      );

      navigator.pop();
      ref.invalidate(assetStreamProvider);

      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Asset assigned successfully'),
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

  void _showReturnDialog(AssetModel asset) {
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Return Asset'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Return asset from ${asset.assignedToName}?'),
            const SizedBox(height: 16),
            TextFormField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Return Notes (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            )
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _performReturn(asset.id, notesController.text.trim());
            },
            child: const Text('Return'),
          )
        ],
      ),
    );
  }

  Future<void> _performReturn(String assetId, String notes) async {
    final repository = ref.read(assetRepositoryProvider);
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
                Text('Processing return...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      await repository.unassignAsset(
        id: assetId,
        returnNotes: notes.isEmpty ? null : notes,
      );

      navigator.pop();
      ref.invalidate(assetStreamProvider);

      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Asset returned successfully'),
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

  void _showDecreaseQuantityDialog(AssetModel asset) {
    final quantityController = TextEditingController();
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Use/Consume item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Avilable: ${asset.quantity} pcs'),
            const SizedBox(height: 16),
            TextFormField(
              controller: quantityController,
              decoration: const InputDecoration(
                labelText: 'Quantity to Use',
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
              ),
              maxLines: 3,
            )
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

              Navigator.pop(dialogContext);
              await _performDecreaseQuantity(asset.id, quantity, reason);
            },
            child: const Text('Confirm'),
          )
        ],
      ),
    );
  }

  Future<void> _performDecreaseQuantity(
      String assetId, int quantity, String reason) async {
    final repository = ref.read(assetRepositoryProvider);
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
                Text('Processing...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      await repository.decreaseQuantity(
        id: assetId,
        quantity: quantity,
        reason: reason,
      );

      navigator.pop();
      ref.invalidate(assetStreamProvider);

      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Quantity decreased successfully'),
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

  void _showStatusChangeDialog(AssetModel asset) {
    String selectedStatus = asset.status;
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Change Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Current Status: ${asset.status.toUpperCase()}'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'New Status',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                      value: 'available', child: Text('Available')),
                  DropdownMenuItem(value: 'borrowed', child: Text('Borrowed')),
                  DropdownMenuItem(
                      value: 'maintenance', child: Text('Maintenance')),
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
                if (selectedStatus == asset.status) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Status unchanged')),
                  );
                  return;
                }

                Navigator.pop(dialogContext);
                await _performStatusChange(
                  asset.id,
                  selectedStatus,
                  reasonController.text.trim(),
                );
              },
              child: const Text('Confirm'),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _performStatusChange(
      String assetId, String status, String reason) async {
    final repository = ref.read(assetRepositoryProvider);
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
        id: assetId,
        status: status,
        reason: reason.isEmpty ? null : reason,
      );

      navigator.pop();
      ref.invalidate(assetStreamProvider);

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

  void _confirmDelete(AssetModel asset) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Asset'),
        content: Text('Are you sure you want to delete "${asset.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _performDelete(asset.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _performDelete(String assetId) async {
    final repository = ref.read(assetRepositoryProvider);
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
                Text('Deleting...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      await repository.deleteAsset(assetId);

      navigator.pop(); // Close loading
      navigator.pop(); // Close detail screen
      ref.invalidate(assetStreamProvider);

      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Asset deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
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
