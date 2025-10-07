import 'package:erp_purchasing_apps/presentation/screens/purchase order/po_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:erp_purchasing_apps/data/providers/pr_provider.dart';
import 'package:erp_purchasing_apps/data/providers/auth_providers.dart';
import 'package:erp_purchasing_apps/data/models/purchase_requisition_model.dart';
import 'package:intl/intl.dart';

class PRApprovalScreen extends ConsumerStatefulWidget {
  const PRApprovalScreen({super.key});

  @override
  ConsumerState<PRApprovalScreen> createState() => _PrApprovalScreenState();
}

class _PrApprovalScreenState extends ConsumerState<PRApprovalScreen> {
  @override
  Widget build(BuildContext context) {
    final prList = ref.watch(prListProvider);
    final currentUser = ref.watch(currentUserProvider);

    // Check if user has approval permission
    final canApporove =
        currentUser?.role == 'admin' || currentUser?.role == 'purchasing';

    if (!canApporove) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('PR Approval'),
        ),
        body: const Center(
          child: Text('You do not have permission to approve PRs'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
        title: const Text('PR Approval Queue'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(prListProvider);
            },
          )
        ],
      ),
      body: prList.when(
        data: (prs) {
          // Filter Only Pending PRs
          final pendingPRs = prs.where((pr) => pr.status == 'pending').toList();

          if (pendingPRs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 64, color: Colors.green),
                  SizedBox(height: 16),
                  Text(
                    'No pending PRs',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: pendingPRs.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final pr = pendingPRs[index];
              //final itemCount = pr.items?.length ?? 0;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                child: InkWell(
                  onTap: () => _showApprovalDialog(pr),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              pr.prNumber,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Chip(
                              label: const Text(
                                'PENDING',
                                style: TextStyle(fontSize: 10),
                              ),
                              backgroundColor: Colors.orange.shade100,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Total: Rp ${NumberFormat('#,###').format(pr.totalEstimated)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.blue,
                          ),
                        ),
                        Text(
                          'Created: ${DateFormat('dd MMM yyyy HH:mm').format(pr.createdAt)}',
                        ),
                        if (pr.notes != null && pr.notes!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Notes: ${pr.notes}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => _showRejectDialog(pr),
                              icon: const Icon(Icons.close, size: 16),
                              label: const Text('Reject'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: () => _confirmApprove(pr),
                              icon: const Icon(Icons.check, size: 16),
                              label: const Text('Approve'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                            )
                          ],
                        )
                      ],
                    ),
                  ),
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
                  ref.invalidate(prListProvider);
                },
                child: const Text('Retry'),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _showApprovalDialog(PurchaseRequisitionModel pr) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 600),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PR detail: ${pr.prNumber}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Divider(height: 24),

                // PR Info
                _buildInfoRow('Status', pr.status.toUpperCase()),
                _buildInfoRow(
                  'Created',
                  DateFormat('dd MMMM yyyy HH:mm').format(pr.createdAt),
                ),
                _buildInfoRow(
                  'Total Estimated',
                  'Rp ${NumberFormat('#,###').format(pr.totalEstimated)}',
                ),
                if (pr.notes != null && pr.notes!.isNotEmpty)
                  _buildInfoRow('Notes', pr.notes!),

                const SizedBox(height: 16),
                const Text(
                  'Items:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                // Item List
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: pr.items?.length ?? 0,
                    itemBuilder: (context, index) {
                      final item = pr.items![index];
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
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text('Qty: ${item.quantity} ${item.unit}'),
                              if (item.estimatedPrice != null)
                                Text(
                                  'Price: Rp ${NumberFormat('#,###').format(item.estimatedPrice)} × ${item.quantity} = Rp ${NumberFormat('#,###').format(item.subtotal)}',
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              if (item.notes != null && item.notes!.isNotEmpty)
                                Text(
                                  'Notes: ${item.notes}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _showRejectDialog(pr),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _confirmApprove(pr),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => POFormScreen(prId: pr.id),
                          ),
                        ).then((_) => ref.invalidate(prListProvider));
                      },
                      icon: const Icon(Icons.shopping_cart, size: 16),
                      label: const Text('Create PO'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
        title: const Text('Approve PR'),
        content: Text('Are you sure you want to approve ${pr.prNumber}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _approvePR(pr.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(PurchaseRequisitionModel pr) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject PR'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reject ${pr.prNumber}?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Rejection Reason *',
                border: OutlineInputBorder(),
                hintText: 'Enter reason for rejection...',
              ),
            )
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter rejection reason'),
                  ),
                );
                return;
              }
              Navigator.pop(context);
              await _rejectPR(pr.id, reasonController.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Reject'),
          )
        ],
      ),
    );
  }

  Future<void> _approvePR(String prId) async {
    try {
      final repo = ref.read(prRepositoryProvider);
      final currentUser = ref.read(currentUserProvider);

      await repo.approvePR(prId, currentUser!.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('PR approved successfully'),
          backgroundColor: Colors.green,
        ));
        ref.invalidate(prListProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error approving PR: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectPR(String prId, String reason) async {
    try {
      final repo = ref.read(prRepositoryProvider);
      final currentUser = ref.read(currentUserProvider);

      await repo.rejectPR(prId, currentUser!.id, reason);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PR rejected'),
            backgroundColor: Colors.orange,
          ),
        );
        ref.invalidate(prListProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error rejecting PR: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
