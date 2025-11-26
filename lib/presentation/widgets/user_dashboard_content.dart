import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:erp_purchasing_apps/data/providers/dashboard_provider.dart';
import 'package:erp_purchasing_apps/data/providers/pr_provider.dart';
import 'package:erp_purchasing_apps/data/providers/auth_providers.dart';

class UserDashboardContent extends ConsumerWidget {
  final String userId;

  const UserDashboardContent({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final dashboardStatsAsync = ref.watch(dashboardStatsProvider);
    final recentActivitiesAsync = ref.watch(recentActivitiesProvider);
    
    // Get user's PRs (filter by user)
    final userPRsAsync = ref.watch(
      purchaseFlowSummaryProvider(
        PurchaseFlowFilterParams(search: currentUser?.username),
      ),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Header
          Text(
            'Welcome, ${currentUser?.fullName ?? 'User'}!',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2196F3),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Here\'s your activity overview',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),

          // Stats Cards
          dashboardStatsAsync.when(
            data: (stats) => Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'My PRs',
                    stats.totalPR.toString(),
                    Icons.description,
                    const Color(0xFF2196F3),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Pending',
                    stats.pendingPR.toString(),
                    Icons.pending,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Approved',
                    (stats.totalPR - stats.pendingPR).toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 24),

          // My Purchase Requisitions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'My Purchase Requisitions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to PR list
                },
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          userPRsAsync.when(
            data: (prs) {
              if (prs.isEmpty) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.inbox, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 8),
                          Text(
                            'No purchase requisitions yet',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return Column(
                children: prs.take(5).map((pr) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getStatusColor(pr.overallStatus),
                        child: Icon(
                          _getStatusIcon(pr.overallStatus),
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        pr.prNumber,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Division: ${pr.divisionName}'),
                          Text(
                            'Created: ${DateFormat('dd MMM yyyy').format(pr.prCreatedAt)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      trailing: Chip(
                        label: Text(
                          pr.overallStatus.toUpperCase(),
                          style: const TextStyle(fontSize: 10),
                        ),
                        backgroundColor: _getStatusColor(pr.overallStatus).withOpacity(0.2),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Text('Error: $error'),
          ),
          const SizedBox(height: 24),

          // Recent Activities
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Activities',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to activity log
                },
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          recentActivitiesAsync.when(
            data: (activities) {
              if (activities.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text('No recent activities'),
                    ),
                  ),
                );
              }

              return Card(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: activities.take(5).length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final activity = activities[index];
                    return ListTile(
                      dense: true,
                      leading: Icon(
                        _getActivityIcon(activity.action),
                        color: _getActivityColor(activity.action),
                        size: 20,
                      ),
                      title: Text(
                        activity.description ?? activity.action,
                        style: const TextStyle(fontSize: 13),
                      ),
                      subtitle: Text(
                        DateFormat('dd MMM yyyy HH:mm').format(activity.createdAt),
                        style: const TextStyle(fontSize: 11),
                      ),
                    );
                  },
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color.withOpacity(0.7), size: 32),
          const SizedBox(height: 12),
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.blue;
      case 'ordered':
        return Colors.purple;
      case 'shipped':
        return Colors.indigo;
      case 'received':
        return Colors.teal;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.schedule;
      case 'approved':
        return Icons.check_circle;
      case 'ordered':
        return Icons.shopping_cart;
      case 'shipped':
        return Icons.local_shipping;
      case 'received':
        return Icons.inventory;
      case 'completed':
        return Icons.done_all;
      default:
        return Icons.help;
    }
  }

  IconData _getActivityIcon(String action) {
    switch (action.toLowerCase()) {
      case 'create':
        return Icons.add_circle;
      case 'update':
        return Icons.edit;
      case 'delete':
        return Icons.delete;
      case 'approve':
        return Icons.check_circle;
      case 'reject':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  Color _getActivityColor(String action) {
    switch (action.toLowerCase()) {
      case 'create':
        return Colors.green;
      case 'update':
        return Colors.blue;
      case 'delete':
        return Colors.red;
      case 'approve':
        return Colors.green;
      case 'reject':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}