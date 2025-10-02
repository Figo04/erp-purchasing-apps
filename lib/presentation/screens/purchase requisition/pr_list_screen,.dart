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
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
        title: const Text('Purchase Requisitions'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(prListProvider);
            },
          )
        ],
      ),
      body: Column(
        children: [
          //  Filter Tabs
          Container(
            padding: const EdgeInsets.all(8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('all', 'All'),
                  const SizedBox(width: 8),
                  _buildFilterChip('draft', 'Draft'),
                  const SizedBox(width: 8),
                  _buildFilterChip('pending', 'Pending'),
                  const SizedBox(width: 8),
                  _buildFilterChip('approved', 'Approved'),
                  const SizedBox(width: 8),
                  _buildFilterChip('rejected', 'Rejected'),
                ],
              ),
            ),
          ),

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
                          trailing: Chip(
                            label: Text(
                              pr.status.toUpperCase(),
                              style: const TextStyle(fontSize: 10),
                            ),
                            backgroundColor:
                                _getStatusColor(pr.status).withOpacity(0.2),
                          ),
                          onTap: () {
                            if (pr.status == 'draft' &&
                                pr.requesterId == currentUser?.id) {
                              _navigateToForm(prId: pr.id);
                            } else {
                              // Show detail (read-only)
                              _showPRDetail(pr);
                            }
                          }),
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
                        ref.invalidate(prListProvider);
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

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _filterStatus == value;
    return FilterChip(
      label: Text(label),
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
                    child: const Text('Closer'),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
