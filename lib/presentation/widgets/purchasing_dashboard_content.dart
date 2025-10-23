import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:erp_purchasing_apps/data/providers/pr_provider.dart';

class PurchasingDashboardContent extends ConsumerWidget {
  const PurchasingDashboardContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingPRCount = ref.watch(pendingPRCountProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Purchase Overview',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2196F3)),
          ),
          const SizedBox(height: 4),
          Text(
            'Manage purchase requisitions and orders',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),

          // Stats Row
          Row(
            children: [
              Expanded(
                child: _buildStatCard('Pending PR', '$pendingPRCount',
                    Icons.pending_actions, Colors.orange),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                    'Active POs', '12', Icons.shopping_cart, Colors.blue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard('Awaiting Delivery', '5',
                    Icons.local_shipping, Colors.purple),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Quick Actions
          const Text(
            'Quick Actions',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/pr-approval'),
                  icon: const Icon(Icons.approval),
                  label: const Text('Approve PR'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/po/create'),
                  icon: const Icon(Icons.add),
                  label: const Text('Create PO'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: const Color(0xFF2196F3),
                    foregroundColor: Colors.white,
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 24),

          // Tasks List
          _buildTasksList(context),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
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
            )
          ]),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          )
        ],
      ),
    );
  }

  Widget _buildTasksList(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.task_alt, size: 18, color: Color(0xFF2196F3)),
              const SizedBox(width: 8),
              const Text(
                'My Tasks',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              )
            ],
          ),
          const SizedBox(height: 16),
          _buildTaskItem(
            context,
            'PR-2024-044 needs PO creation',
            Icons.add_shopping_cart,
            Colors.blue,
            () => context.go('/po/create'),
          ),
          const Divider(height: 24),
          _buildTaskItem(
            context,
            'PO-2024-023 pending approval',
            Icons.pending,
            Colors.orange,
            () => context.go('/po-approval'),
          ),
          const Divider(height: 24),
          _buildTaskItem(
            context,
            '8 PRs waiting for review',
            Icons.rate_review,
            Colors.purple,
            () => context.go('/pr-approval'),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
        ],
      ),
    );
  }
}
