import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:erp_purchasing_apps/data/providers/payment_provider.dart';

class FinanceDashboardContent extends ConsumerWidget {
  const FinanceDashboardContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overdueCount = ref.watch(overduePaymentsCountProvider);
    final pendingCount = ref.watch(pendingPaymentsCountProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Overview',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2196F3)),
          ),
          const SizedBox(height: 4),
          Text(
            'Manage invoices and payments',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),

          // Stats Row
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                    'Pending', '$pendingCount', Icons.pending, Colors.orange),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                    'Overdue', '$overdueCount', Icons.warning, Colors.red),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                    'Paid', 'Rp 45M', Icons.check_circle, Colors.green),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Warning if overdue
          if (overdueCount > 0)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.red.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '$overdueCount payment${overdueCount > 1 ? 's' : ''} overdue! Immediate action required.',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                ],
              ),
            ),
          if (overdueCount > 0) const SizedBox(height: 16),

          // Quick Action
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.go('/payment'),
              icon: const Icon(Icons.payment),
              label: const Text('Manage Payments'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Payment Tasks
          _buildPaymentTasks(context, overdueCount),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, color) {
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
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 24, color: Colors.grey[600]),
          )
        ],
      ),
    );
  }

  Widget _buildPaymentTasks(BuildContext context, int overdueCount) {
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
          ]),
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
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (overdueCount > 0) ...[
            _buildTaskItem(
              context,
              '$overdueCount Payments Overdue!',
              Icons.error,
              Colors.red,
              () => context.go('/payment'),
            ),
            const Divider(height: 24),
          ],
          _buildTaskItem(
            context,
            'Verify Invoice INV-1234',
            Icons.receipt_long,
            Colors.blue,
            () => context.go('/payment'),
          ),
          const Divider(height: 24),
          _buildTaskItem(
            context,
            'Process Payment PAY-2024-003',
            Icons.payment,
            Colors.green,
            () => context.go('/payment'),
          ),
          const Divider(height: 24),
          _buildTaskItem(
            context,
            'Review pending invoices',
            Icons.rate_review,
            Colors.orange,
            () => context.go('/payment'),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(BuildContext context, String title, IconData icon,
      Color color, VoidCallback onTap) {
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
          Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400])
        ],
      ),
    );
  }
}
