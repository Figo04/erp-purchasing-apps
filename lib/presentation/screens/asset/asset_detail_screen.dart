import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:erp_purchasing_apps/data/models/asset_model.dart';
import 'package:erp_purchasing_apps/data/providers/asset_provider.dart';
import 'package:erp_purchasing_apps/data/providers/auth_providers.dart';
import 'package:intl/intl.dart';

class AssetDetailScreen extends ConsumerWidget {
  final String assetId;

  const AssetDetailScreen({super.key, required this.assetId});

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'loanable':
        return Colors.purple;
      case 'saleable':
        return Colors.green;
      case 'disposed':
        return Colors.grey;
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
      case 'lent':
        return Colors.blue;
      case 'sold':
        return Colors.purple;
      case 'disposed':
        return Colors.grey;
      case 'returned':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'loanable':
        return Icons.devices;
      case 'saleable':
        return Icons.shopping_bag;
      case 'disposed':
        return Icons.delete_forever;
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
    final loanHistoryAsync = ref.watch(assetLoanHistoryProvider(assetId));

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
              ref.invalidate(assetLoanHistoryProvider(assetId));
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // WARNING: Pending Classification
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

                  // Category & Status Row
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
                      if (!asset.isDisposed)
                        Expanded(
                          child: _buildInfoCard(
                            'Status',
                            asset.statusDisplayName,
                            _getStatusColor(asset.status ?? ''),
                          ),
                        )
                      else // TAMBAH else
                        Expanded(
                          child: _buildInfoCard(
                            'Status',
                            'Disposed (No Status)',
                            Colors.grey,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Type & Division Row (NEW)
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          'Type',
                          asset.assetTypeDisplayName,
                          Colors.deepPurple,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildInfoCard(
                          'Division',
                          asset.divisionName ?? 'Not Assigned',
                          asset.divisionName != null
                              ? Colors.blue
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Quantity & Source Row
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
                          'Source',
                          asset.sourceDisplayName,
                          asset.isFromExternal ? Colors.purple : Colors.teal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Assignment/Loan Info
                  if ((asset.isBorrowed || asset.isLent) &&
                      asset.assignedToName != null)
                    Card(
                      color: asset.isBorrowed
                          ? Colors.orange.shade50
                          : Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                    asset.isBorrowed
                                        ? Icons.outbound
                                        : Icons.input,
                                    color: asset.isBorrowed
                                        ? Colors.orange.shade700
                                        : Colors.blue.shade700),
                                const SizedBox(width: 8),
                                Text(
                                  asset.isBorrowed
                                      ? 'Currently Borrowed Out'
                                      : 'Currently On Loan',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: asset.isBorrowed
                                        ? Colors.orange.shade700
                                        : Colors.blue.shade700,
                                  ),
                                )
                              ],
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow(
                                asset.isBorrowed ? 'Borrowed by' : 'Lent to',
                                asset.assignedToName!),
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
                  if (asset.isBorrowed || asset.isLent)
                    const SizedBox(height: 16),

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

                  // Loan History Section (NEW)
                  if (canManage) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Loan History',
                            style: Theme.of(context).textTheme.titleMedium),
                        TextButton.icon(
                          onPressed: () =>
                              ref.invalidate(assetLoanHistoryProvider(assetId)),
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Refresh'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    loanHistoryAsync.when(
                      data: (loans) {
                        if (loans.isEmpty) {
                          return const Card(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(
                                child: Text(
                                  'No loan history',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            ),
                          );
                        }

                        return Column(
                          children: loans.map((loan) {
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              color: loan.isOngoing
                                  ? Colors.orange.shade50
                                  : loan.isOverdue
                                      ? Colors.red.shade50
                                      : null,
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          loan.isInternal
                                              ? Icons.swap_horiz
                                              : Icons.business,
                                          size: 20,
                                          color: loan.isInternal
                                              ? Colors.blue
                                              : Colors.purple,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            loan.isInternal
                                                ? 'Internal: ${loan.fromDivisionName ?? ''} → ${loan.toDivisionName ?? ''}'
                                                : 'External: ${loan.externalCompanyName ?? ''}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: loan.isReturned
                                                ? Colors.green
                                                : loan.isOverdue
                                                    ? Colors.red
                                                    : Colors.orange,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            loan.status.toUpperCase(),
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Qty: ${loan.quantity} | Loan: ${DateFormat('dd MMM yyyy').format(loan.loanDate)}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    if (loan.expectedReturnDate != null)
                                      Text(
                                        'Expected Return: ${DateFormat('dd MMM yyyy').format(loan.expectedReturnDate!)}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    if (loan.actualReturnDate != null)
                                      Text(
                                        'Returned: ${DateFormat('dd MMM yyyy').format(loan.actualReturnDate!)}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.green,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    if (loan.isOverdue &&
                                        loan.daysOverdue != null)
                                      Text(
                                        '⚠️ Overdue by ${loan.daysOverdue} days',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, _) => Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text('Error loading loan history: $error'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Action Buttons
                  if (canManage) ...[
                    Text('Actions',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),

                    // Edit Asset (Always visible)
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

                    // Loanable Actions
                    if (asset.assetCategory == 'loanable' &&
                        !asset.isPending &&
                        !asset.isDisposed) ...[
                      if (asset.isAvailable)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                _showLoanDialog(context, ref, asset),
                            icon: const Icon(Icons.output),
                            label: const Text('Loan Out Asset'),
                          ),
                        ),
                      if (asset.isBorrowed || asset.isLent)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _showReturnDialog(
                                context, ref, asset, loanHistoryAsync.value),
                            icon: const Icon(Icons.assignment_return),
                            label: const Text('Mark as Returned'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.green,
                            ),
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

  // EDIT DIALOG (UPDATED with assetType)
  void _showEditDialog(BuildContext context, WidgetRef ref, AssetModel asset) {
    String selectedCategory = asset.assetCategory;
    String selectedType = asset.assetType;
    String selectedStatus = asset.status ?? '';
    int selectedQuantity = asset.quantity;
    final nameController = TextEditingController(text: asset.name);
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
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Asset Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Asset Type (NEW)
                const Text('Asset Type:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'mesin',
                      child: Row(
                        children: [
                          Icon(Icons.precision_manufacturing,
                              color: Colors.deepPurple),
                          SizedBox(width: 8),
                          Text('Mesin'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'sparepart',
                      child: Row(
                        children: [
                          Icon(Icons.build_circle, color: Colors.orange),
                          SizedBox(width: 8),
                          Text('Sparepart'),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (v) => setState(() => selectedType = v!),
                ),
                const SizedBox(height: 16),

                // Category
                const Text('Category:',
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
                    DropdownMenuItem(
                      value: 'disposed',
                      child: Row(
                        children: [
                          Icon(Icons.delete_forever, color: Colors.grey),
                          SizedBox(width: 8),
                          Text('Disposed'),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (v) => setState(() => selectedCategory = v!),
                ),
                const SizedBox(height: 16),

                Visibility(
                  visible: selectedCategory != 'disposed',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status
                      const Text('Status:',
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
                          DropdownMenuItem(value: 'lent', child: Text('Lent')),
                          DropdownMenuItem(value: 'sold', child: Text('Sold')),
                          DropdownMenuItem(
                              value: 'returned', child: Text('Returned')),
                        ],
                        onChanged: (v) => setState(() => selectedStatus = v!),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),

                // disposed
                if (selectedCategory == 'disposed')
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.grey.shade700, size: 20),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Disposed items have no status',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

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
                  selectedType,
                  selectedStatus,
                  selectedQuantity,
                  asset.divisionId,
                  asset.purchasePrice,
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
    String type,
    String status,
    int quantity,
    String? divisionId,
    double? price,
    String? notes,
  ) async {
    _showLoading(context, 'Updating...');
    try {
      String? finalStatus = category == 'disposed' ? null : status;

      await ref.read(assetRepositoryProvider).updateAsset(
            id: assetId,
            name: name,
            assetCategory: category,
            assetType: type,
            status: status,
            quantity: quantity,
            divisionId: divisionId,
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

  // LOAN DIALOG (NEW)
  void _showLoanDialog(BuildContext context, WidgetRef ref, AssetModel asset) {
    String loanType = 'internal';
    int quantity = 1;
    final companyController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Loan Out Asset'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Loan Type
                const Text('Loan Type:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: loanType,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'internal', child: Text('Internal (Division)')),
                    DropdownMenuItem(
                        value: 'external', child: Text('External (Company)')),
                  ],
                  onChanged: (v) => setState(() => loanType = v!),
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
                    if (val != null && val <= asset.quantity) quantity = val;
                  },
                  controller: TextEditingController(text: '1'),
                ),
                const SizedBox(height: 8),
                Text('Available: ${asset.quantity}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 16),

                // Company Name (for external)
                if (loanType == 'external') ...[
                  TextField(
                    controller: companyController,
                    decoration: const InputDecoration(
                      labelText: 'Company Name *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Notes
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
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
                if (loanType == 'external' && companyController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Company name is required')));
                  return;
                }

                Navigator.pop(ctx);
                await _performLoan(
                  context,
                  ref,
                  asset.id,
                  loanType,
                  quantity,
                  companyController.text,
                  notesController.text,
                );
              },
              child: const Text('Loan Out'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _performLoan(
    BuildContext context,
    WidgetRef ref,
    String assetId,
    String loanType,
    int quantity,
    String? companyName,
    String? notes,
  ) async {
    _showLoading(context, 'Processing loan...');
    try {
      await ref.read(assetRepositoryProvider).loanAsset(
            assetId: assetId,
            loanType: loanType,
            quantity: quantity,
            externalCompanyName: loanType == 'external' ? companyName : null,
            notes: notes?.isEmpty == true ? null : notes,
          );

      if (!context.mounted) return;
      Navigator.pop(context);
      ref.invalidate(assetDetailProvider(assetId));
      ref.invalidate(assetLoanHistoryProvider(assetId));
      ref.invalidate(filteredAssetListProvider);

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✓ Asset loaned successfully'),
          backgroundColor: Colors.green));
    } catch (e) {
      Navigator.pop(context);
      _showError(context, e.toString());
    }
  }

  // RETURN DIALOG (NEW)
  void _showReturnDialog(BuildContext context, WidgetRef ref, AssetModel asset,
      List<AssetLoanHistoryModel>? loans) {
    if (loans == null || loans.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('No active loans found')));
      return;
    }

    final ongoingLoans = loans.where((l) => l.isOngoing).toList();
    if (ongoingLoans.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No ongoing loans to return')));
      return;
    }

    String? selectedLoanId = ongoingLoans.first.id;
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Return Asset'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select loan to return:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedLoanId,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: ongoingLoans.map((loan) {
                  return DropdownMenuItem(
                    value: loan.id,
                    child: Text(loan.isInternal
                        ? 'Internal: ${loan.toDivisionName}'
                        : 'External: ${loan.externalCompanyName}'),
                  );
                }).toList(),
                onChanged: (v) => setState(() => selectedLoanId = v),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Return Notes (Optional)',
                  border: OutlineInputBorder(),
                ),
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
                if (selectedLoanId == null) return;
                Navigator.pop(ctx);
                await _performReturn(
                  context,
                  ref,
                  asset.id,
                  selectedLoanId!,
                  notesController.text,
                );
              },
              child: const Text('Mark Returned'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _performReturn(
    BuildContext context,
    WidgetRef ref,
    String assetId,
    String loanHistoryId,
    String? notes,
  ) async {
    _showLoading(context, 'Processing return...');
    try {
      await ref.read(assetRepositoryProvider).returnAsset(
            loanHistoryId: loanHistoryId,
            notes: notes?.isEmpty == true ? null : notes,
          );

      if (!context.mounted) return;
      Navigator.pop(context);
      ref.invalidate(assetDetailProvider(assetId));
      ref.invalidate(assetLoanHistoryProvider(assetId));
      ref.invalidate(filteredAssetListProvider);

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✓ Asset returned successfully'),
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
      await ref.read(assetRepositoryProvider);

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
