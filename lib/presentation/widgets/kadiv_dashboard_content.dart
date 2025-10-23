import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:erp_purchasing_apps/data/providers/pr_provider.dart';

class KadivDashboardContent extends ConsumerWidget {
  const KadivDashboardContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingCount = ref.watch(pendingPRCountProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Approval Dashboard',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2196F3)),
          ),
          const SizedBox(height: 4),
          Text(
            'Review and approve purchase request',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),

          // Stats Row
          Row(
            children: [
              Expanded(
                child: _buildStatCard('Pending Approval', '$pendingCount',
                    Icons.pending_actions, Colors.orange),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                    'Approved Today', '3', Icons.check_circle, Colors.green),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                    'High Priority', '2', Icons.priority_high, Colors.red),
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
                  label: const Text('PR Approval'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/po-approval'),
                  icon: const Icon(Icons.check_circle),
                  label: const Text('PO Approval'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: const Color(0xFF2196F3),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Departement Performance
          _buildDepartementPerformance(context),
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
        ],
      ),
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

  Widget _buildDepartementPerformance(BuildContext context) {
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
              const Icon(Icons.analytics, size: 18, color: Color(0xFF2196F3)),
              const SizedBox(width: 8),
              const Text(
                'Departement Performance',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildPerformanceRow('Team PRs', '12', Icons.description),
          const SizedBox(height: 12),
          _buildPerformanceRow('Approval Rate', '85%', Icons.check_circle),
          const SizedBox(height: 12),
          _buildPerformanceRow('Avg Response Time', '2 hours', Icons.timer),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.go('/pr-history'),
              icon: const Icon(Icons.history),
              label: const Text('View All History'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF2196F3), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2196F3),
          ),
        )
      ],
    );
  }
}
