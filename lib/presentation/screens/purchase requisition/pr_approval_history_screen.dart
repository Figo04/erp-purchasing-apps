import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:erp_purchasing_apps/data/providers/pr_provider.dart';
import 'package:erp_purchasing_apps/data/providers/user_provider.dart';
import 'package:erp_purchasing_apps/data/models/purchase_requisition_model.dart';
import 'package:intl/intl.dart';

class PRApprovalHistoryScreen extends ConsumerStatefulWidget {
  const PRApprovalHistoryScreen({super.key});

  @override
  ConsumerState<PRApprovalHistoryScreen> createState() =>
      _PRApprovalHistoryScreenState();
}

class _PRApprovalHistoryScreenState
    extends ConsumerState<PRApprovalHistoryScreen> {
  String _filterStatus = 'all';

  @override
  Widget build(BuildContext context) {
    final prList = ref.watch(prListProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
        title: const Text('PR Approval History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(prListProvider);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter
          Container(
            padding: const EdgeInsets.all(8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('all', 'All'),
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
                // Filter PRs with approval history
                var historyPRs = prs.where((pr) {
                  return pr.status == 'approved' || pr.status == 'rejected';
                }).toList();

                // Apply status filter
                if (_filterStatus != 'all') {
                  historyPRs = historyPRs
                      .where((pr) => pr.status == _filterStatus)
                      .toList();
                }

                if (historyPRs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No approval history',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: historyPRs.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final pr = historyPRs[index];
                    return _buildHistoryCard(pr);
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

  Widget _buildHistoryCard(PurchaseRequisitionModel pr) {
    final isApproved = pr.status == 'approved';
    final statusColor = isApproved ? Colors.green : Colors.red;
    final statusIcon = isApproved ? Icons.check_circle : Icons.cancel;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _showHistoryDetail(pr),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // PR Number & Status
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
                  Row(
                    children: [
                      Icon(statusIcon, color: statusColor, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        pr.status.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 16),

              // PR Info
              Text(
                'Items: ${pr.items?.length ?? 0} | Total: Rp ${NumberFormat('#,###').format(pr.totalEstimated)}',
              ),
              const SizedBox(height: 4),
              Text(
                'Created: ${DateFormat('dd MMM yyyy HH:mm').format(pr.createdAt)}',
                style: TextStyle(color: Colors.grey.shade600),
              ),

              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isApproved ? Icons.thumb_up : Icons.thumb_down,
                          size: 16,
                          color: statusColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isApproved ? 'Approved by' : 'Rejected by',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    FutureBuilder(
                      future: _getApproverName(pr.approvedBy),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return Text(
                            snapshot.data as String,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          );
                        }
                        return const Text('Loading...');
                      },
                    ),
                    if (pr.approvedAt != null)
                      Text(
                        DateFormat('dd MMM yyyy HH:mm').format(pr.approvedAt!),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    if (!isApproved && pr.rejectionReason != null) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Reason:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        pr.rejectionReason!,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String> _getApproverName(String? approverId) async {
    if (approverId == null) return 'Unknown';
    try {
      final repo = ref.read(userRepositoryProvider);
      final user = await repo.getUserById(approverId);
      return user?.fullName ?? user?.username ?? 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }

  void _showHistoryDetail(PurchaseRequisitionModel pr) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PR History: ${pr.prNumber}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Divider(height: 24),

                // Status
                Row(
                  children: [
                    Icon(
                      pr.status == 'approved'
                          ? Icons.check_circle
                          : Icons.cancel,
                      color:
                          pr.status == 'approved' ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      pr.status.toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color:
                            pr.status == 'approved' ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Timeline
                _buildInfoRow('Created',
                    DateFormat('dd MMM yyyy HH:mm').format(pr.createdAt)),
                if (pr.approvedAt != null)
                  _buildInfoRow(
                    pr.status == 'approved' ? 'Approved' : 'Rejected',
                    DateFormat('dd MMM yyyy HH:mm').format(pr.approvedAt!),
                  ),
                FutureBuilder(
                  future: _getApproverName(pr.approvedBy),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return _buildInfoRow(
                        pr.status == 'approved' ? 'Approved by' : 'Rejected by',
                        snapshot.data as String,
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),

                if (pr.rejectionReason != null) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow('Rejection Reason', pr.rejectionReason!),
                ],

                const SizedBox(height: 16),
                _buildInfoRow(
                  'Total',
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

                // Items List
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
                                  'Subtotal: Rp ${NumberFormat('#,###').format(item.subtotal)}',
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.w600,
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
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
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
}
