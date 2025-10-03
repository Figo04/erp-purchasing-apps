import 'package:erp_purchasing_apps/data/models/purchase_requisition_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:erp_purchasing_apps/data/providers/pr_provider.dart';
import 'package:erp_purchasing_apps/data/providers/auth_providers.dart';
import 'package:erp_purchasing_apps/presentation/screens/purchase requisition/pr_form_screen.dart';
import 'package:intl/intl.dart';

class PRListScreen extends ConsumerStatefulWidget {
  const PRListScreen({super.key});

  @override
  ConsumerState<PRListScreen> createState() => _PRListScreenState();
}

class _PRListScreenState extends ConsumerState<PRListScreen> {
  String _filterStatus = 'all';

  Color _getStatusColor(String status) {
    switch (status) {
      case 'draft':
        return Colors.grey;
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _navigateToForm({String? prId}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PRFormScreen(prId: prId),
      ),
    ).then((_) {
      ref.invalidate(prListProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final prList = ref.watch(prListProvider);
    final prStream = ref.watch(prStreamProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
        title: const Text('Purchase Requisitions'),
        actions: [
          // Real-time indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: prStream.when(
                data: (_) => const Icon(Icons.cloud_done, color: Colors.green),
                loading: () => const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (_, __) =>
                    const Icon(Icons.cloud_off, color: Colors.red),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(prStreamProvider);
            },
          )
        ],
      ),
      body: Column(
        children: [
          //  Filter Tabs
          // Filter Tabs with Count Badges
          Container(
            padding: const EdgeInsets.all(8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: prStream.when(
                data: (prs) {
                  final draftCount =
                      prs.where((pr) => pr.status == 'draft').length;
                  final pendingCount =
                      prs.where((pr) => pr.status == 'pending').length;
                  final approvedCount =
                      prs.where((pr) => pr.status == 'approved').length;
                  final rejectedCount =
                      prs.where((pr) => pr.status == 'rejected').length;

                  return Row(
                    children: [
                      _buildFilterChip('all', 'All', prs.length),
                      const SizedBox(width: 8),
                      _buildFilterChip('draft', 'Draft', draftCount),
                      const SizedBox(width: 8),
                      _buildFilterChip('pending', 'Pending', pendingCount),
                      const SizedBox(width: 8),
                      _buildFilterChip('approved', 'Approved', approvedCount),
                      const SizedBox(width: 8),
                      _buildFilterChip('rejected', 'Rejected', rejectedCount),
                    ],
                  );
                },
                loading: () => Row(
                  children: [
                    _buildFilterChip('all', 'All', 0),
                    const SizedBox(width: 8),
                    _buildFilterChip('draft', 'Draft', 0),
                    const SizedBox(width: 8),
                    _buildFilterChip('pending', 'Pending', 0),
                    const SizedBox(width: 8),
                    _buildFilterChip('approved', 'Approved', 0),
                    const SizedBox(width: 8),
                    _buildFilterChip('rejected', 'Rejected', 0),
                  ],
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
          ),

          // PR List
          Expanded(
            child: prList.when(
              data: (prs) {
                // Filter By Status
                final filteredPRs = _filterStatus == 'all'
                    ? prs
                    : prs.where((pr) => pr.status == _filterStatus).toList();

                if (filteredPRs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.request_page, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No PRs found',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        )
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filteredPRs.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final pr = filteredPRs[index];
                    final itemCount = pr.items?.length ?? 0;
                    final canEdit = pr.status == 'draft' &&
                        pr.requesterId == currentUser?.id;
                    final canDelete = pr.status == 'draft' &&
                        pr.requesterId == currentUser?.id;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getStatusColor(pr.status),
                          child: Text(
                            pr.prNumber.split('_').last.substring(0, 2),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        title: Text(
                          pr.prNumber,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Items: $itemCount'),
                            Text(
                                'Total: Rp ${NumberFormat('#,###').format(pr.totalEstimated)}'),
                            Text(
                                'Created: ${DateFormat('dd MMM yyyy').format(pr.createdAt)}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Chip(
                              label: Text(
                                pr.status.toUpperCase(),
                                style: const TextStyle(fontSize: 10),
                              ),
                              backgroundColor:
                                  _getStatusColor(pr.status).withOpacity(0.2),
                            ),
                            if (canDelete) ...[
                              const SizedBox(width: 8),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () =>
                                    _confirmDelete(pr.id, pr.prNumber),
                              ),
                            ],
                          ],
                        ),
                        onTap: () {
                          if (canEdit) {
                            _navigateToForm(prId: pr.id);
                          } else {
                            _showPRDetail(pr);
                          }
                        },
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
                        ref.invalidate(prStreamProvider);
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToForm(),
        child: const Icon(Icons.add),
      ),
    );
  }

  // Update _buildFilterChip to include count badge
  Widget _buildFilterChip(String value, String label, int count) {
    final isSelected = _filterStatus == value;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.blue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected ? Colors.blue : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterStatus = value;
        });
      },
    );
  }

  void _showPRDetail(PurchaseRequisitionModel pr) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PR Detail: ${pr.prNumber}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 15),
                Text('Status: ${pr.status.toUpperCase()}'),
                Text('Items: ${pr.items?.length ?? 0}'),
                Text(
                    'Total: Rp ${NumberFormat('#,###').format(pr.totalEstimated)}'),
                if (pr.notes != null) Text('Notes: ${pr.notes}'),
                const SizedBox(height: 16),
                if (pr.items != null && pr.items!.isNotEmpty) ...[
                  const Text('Items:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...pr.items!.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                          '. ${item.itemName} (${item.quantity} ${item.unit})'),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Align(
                  alignment: AlignmentGeometry.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(String prId, String prNumber) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete PR $prNumber?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Tutup dialog

              // Tampilkan loading
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Deleting...'),
                  duration: Duration(seconds: 1),
                ),
              );

              try {
                // Panggil repository untuk delete
                final repo = ref.read(prRepositoryProvider);
                await repo.deletePR(prId);

                // Refresh list - stream akan otomatis update
                ref.invalidate(prListProvider);
                ref.invalidate(prStreamProvider);

                // Tampilkan success message
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('PR $prNumber deleted successfully'),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                // Tampilkan error message
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete PR: ${e.toString()}'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
