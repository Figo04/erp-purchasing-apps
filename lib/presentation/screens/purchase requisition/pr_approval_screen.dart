import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:erp_purchasing_apps/data/providers/pr_provider.dart';
import 'package:erp_purchasing_apps/data/providers/auth_providers.dart';
import 'package:erp_purchasing_apps/data/models/purchase_requisition_model.dart';
import 'package:erp_purchasing_apps/presentation/screens/purchase order/po_form_screen.dart';

class PRApprovalScreen extends ConsumerStatefulWidget {
  const PRApprovalScreen({super.key});

  @override
  ConsumerState<PRApprovalScreen> createState() => _PrApprovalScreenState();
}

class _PrApprovalScreenState extends ConsumerState<PRApprovalScreen> {
  String _searchQuery = '';
  String? _selectedDivision;
  String _sortBy = 'date';

  @override
  Widget build(BuildContext context) {
    final prState = ref.watch(prNotifierProvider);
    final currentUser = ref.watch(currentUserProvider);

    // Check if user has approval permission
    final canApprove =
        currentUser?.role == 'admin' || currentUser?.role == 'kadiv';

    if (!canApprove) {
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
            'PR Approval',
            style:
                TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'You do not have permission to approve PRs',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

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
          'PR Approval Queue',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(prNotifierProvider.notifier).refresh();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Filter & Search Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    // Search Field
                    Expanded(
                      flex: 2,
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search PR number, division...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          isDense: true,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value.toLowerCase();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Division Filter
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedDivision,
                        decoration: InputDecoration(
                          labelText: 'Division',
                          prefixIcon: const Icon(Icons.filter_list, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          isDense: true,
                        ),
                        items: const [
                          DropdownMenuItem(value: null, child: Text('All')),
                          DropdownMenuItem(value: '100', child: Text('Motor')),
                          DropdownMenuItem(
                              value: '200', child: Text('Injection')),
                          DropdownMenuItem(
                              value: '300', child: Text('Stamping')),
                          DropdownMenuItem(value: '500', child: Text('PD')),
                          DropdownMenuItem(
                              value: '600', child: Text('Tooling')),
                          DropdownMenuItem(
                              value: '700', child: Text('Machining')),
                          DropdownMenuItem(value: '800', child: Text('Lumina')),
                          DropdownMenuItem(value: '810', child: Text('LED')),
                          DropdownMenuItem(value: '900', child: Text('Sales')),
                          DropdownMenuItem(value: '910', child: Text('Admin')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedDivision = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Sort By
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _sortBy,
                        decoration: InputDecoration(
                          labelText: 'Sort By',
                          prefixIcon: const Icon(Icons.sort, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          isDense: true,
                        ),
                        items: const [
                          DropdownMenuItem(value: 'date', child: Text('Date')),
                          DropdownMenuItem(
                              value: 'total', child: Text('Total')),
                          DropdownMenuItem(
                              value: 'items', child: Text('Items')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _sortBy = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // PR Cards
          Expanded(
            child: prState.when(
              data: (prs) {
                // Filter pending PRs
                var pendingPRs =
                    prs.where((pr) => pr.status == 'pending').toList();

                // Apply search filter
                if (_searchQuery.isNotEmpty) {
                  pendingPRs = pendingPRs.where((pr) {
                    return pr.prNumber.toLowerCase().contains(_searchQuery) ||
                        (pr.divisionName
                                ?.toLowerCase()
                                .contains(_searchQuery) ??
                            false) ||
                        pr.processingType.toLowerCase().contains(_searchQuery);
                  }).toList();
                }

                // Apply division filter
                if (_selectedDivision != null) {
                  pendingPRs = pendingPRs
                      .where((pr) => pr.divisionId == _selectedDivision)
                      .toList();
                }

                // Sort data
                switch (_sortBy) {
                  case 'date':
                    pendingPRs
                        .sort((a, b) => b.createdAt.compareTo(a.createdAt));
                    break;
                  case 'total':
                    pendingPRs.sort(
                        (a, b) => b.totalEstimated.compareTo(a.totalEstimated));
                    break;
                  case 'items':
                    pendingPRs.sort((a, b) =>
                        (b.items?.length ?? 0).compareTo(a.items?.length ?? 0));
                    break;
                }

                if (pendingPRs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline,
                            size: 80, color: Colors.green.shade300),
                        const SizedBox(height: 16),
                        const Text(
                          'No Pending PRs',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'All PRs have been processed',
                          style: TextStyle(
                              fontSize: 14, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    await ref.read(prNotifierProvider.notifier).refresh();
                  },
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, // 2 cards per row for desktop
                      childAspectRatio: 1.6,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: pendingPRs.length,
                    itemBuilder: (context, index) {
                      final pr = pendingPRs[index];
                      return _buildPRCard(pr);
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Error: $error',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        ref.read(prNotifierProvider.notifier).refresh();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
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

  Widget _buildPRCard(PurchaseRequisitionModel pr) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () => _showDetailDialog(pr),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'PENDING',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getProcessingTypeColor(pr.processingType)
                          .withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      pr.processingType.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _getProcessingTypeColor(pr.processingType),
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.visibility, size: 20),
                    tooltip: 'View Detail',
                    onPressed: () => _showDetailDialog(pr),
                    color: Colors.blue,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // PR Number
              Text(
                pr.prNumber,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              // Division & Requester
              Row(
                children: [
                  const Icon(Icons.business, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    pr.divisionName ?? pr.divisionId,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      pr.requesterName ?? 'Unknown',
                      style:
                          TextStyle(fontSize: 13, color: Colors.grey.shade700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Stats
              Row(
                children: [
                  _buildStatChip(
                    Icons.inventory_2,
                    '${pr.items?.length ?? 0} items',
                    Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  _buildStatChip(
                    Icons.calendar_today,
                    DateFormat('dd/MM/yy').format(pr.createdAt),
                    Colors.purple,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Total
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Estimated:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Rp ${NumberFormat('#,###').format(pr.totalEstimated)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showRejectDialog(pr),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _confirmApprove(pr),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: color),
          )
        ],
      ),
    );
  }

  Color _getProcessingTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'material':
        return Colors.blue;
      case 'aset':
        return Colors.purple;
      case 'logistik':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void _showDetailDialog(PurchaseRequisitionModel pr) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700, maxHeight: 600),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.request_page,
                        color: Colors.blue, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Purchase Requisition Detail',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            pr.prNumber,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Body
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // PR Info
                      _buildInfoRow('PR Number', pr.prNumber),
                      _buildInfoRow(
                          'Division', pr.divisionName ?? pr.divisionId),
                      _buildInfoRow(
                          'Processing Type', pr.processingType.toUpperCase()),
                      _buildInfoRow('Status', pr.status.toUpperCase()),
                      _buildInfoRow(
                          'Requester', pr.requesterName ?? pr.requesterId),
                      _buildInfoRow(
                          'Created',
                          DateFormat('dd MMMM yyyy, HH:mm')
                              .format(pr.createdAt)),
                      _buildInfoRow('Total Items', '${pr.items?.length ?? 0}'),
                      _buildInfoRow(
                        'Total Estimated',
                        'Rp ${NumberFormat('#,###').format(pr.totalEstimated)}',
                      ),

                      if (pr.notes != null && pr.notes!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Notes:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(pr.notes!),
                        ),
                      ],

                      const SizedBox(height: 20),
                      const Text(
                        'Items:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Items List
                      if (pr.items != null && pr.items!.isNotEmpty)
                        ...pr.items!.asMap().entries.map((entry) {
                          final index = entry.key;
                          final item = entry.value;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            color: Colors.grey.shade50,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: Colors.blue,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${index + 1}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          item.itemName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Text(
                                          'Qty: ${item.quantity} ${item.unit}'),
                                      if (item.estimatedPrice != null) ...[
                                        const SizedBox(width: 16),
                                        Text(
                                          'Price: Rp ${NumberFormat('#,###').format(item.estimatedPrice)}',
                                          style: TextStyle(
                                            color: Colors.blue.shade700,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  if (item.notes != null &&
                                      item.notes!.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Notes: ${item.notes}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),

              // Footer Actions
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border(top: BorderSide(color: Colors.grey.shade300)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showRejectDialog(pr);
                      },
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _confirmApprove(pr);
                      },
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
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
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _confirmApprove(PurchaseRequisitionModel pr) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 12),
            Text('Approve PR'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to approve this PR?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pr.prNumber,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                      'Total: Rp ${NumberFormat('#,###').format(pr.totalEstimated)}'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await _approvePR(pr.id, pr.prNumber);
            },
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Approve'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(PurchaseRequisitionModel pr) {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.cancel, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text('Reject PR'),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Are you sure you want to reject this PR?'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pr.prNumber,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                        'Total: Rp ${NumberFormat('#,###').format(pr.totalEstimated)}'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: reasonController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Rejection Reason *',
                  hintText: 'Enter reason for rejection...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter rejection reason';
                  }
                  if (value.trim().length < 10) {
                    return 'Reason must be at least 10 characters';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context);
                await _rejectPR(
                    pr.id, pr.prNumber, reasonController.text.trim());
              }
            },
            icon: const Icon(Icons.close, size: 18),
            label: const Text('Reject'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _approvePR(String prId, String prNumber) async {
    // Show loading
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
                Text('Approving PR...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      await ref.read(prNotifierProvider.notifier).approvePR(prId);

      if (mounted) {
        Navigator.pop(context); // Close loading

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 16),
                Expanded(
                  child: Text('PR $prNumber approved successfully'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 16),
                Expanded(
                  child: Text('Failed to approve PR: $e'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _rejectPR(String prId, String prNumber, String reason) async {
    // Show loading
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
                Text('Rejecting PR...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      await ref.read(prNotifierProvider.notifier).rejectPR(prId, reason);

      if (mounted) {
        Navigator.pop(context); // Close loading

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.info, color: Colors.white),
                const SizedBox(width: 16),
                Expanded(
                  child: Text('PR $prNumber rejected'),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 16),
                Expanded(
                  child: Text('Failed to reject PR: $e'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}
