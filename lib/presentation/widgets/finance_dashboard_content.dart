import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:erp_purchasing_apps/data/providers/dashboard_provider.dart';
import 'package:erp_purchasing_apps/data/providers/payment_provider.dart';

class FinanceDashboardContent extends ConsumerWidget {
  const FinanceDashboardContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardStatsAsync = ref.watch(dashboardStatsProvider);
    final overdueCountAsync = ref.watch(overduePaymentsCountProvider);
    final pendingCountAsync = ref.watch(pendingPaymentsCountProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Finance Dashboard',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2196F3),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Manage invoices and payments',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),

          // Stats Row - REAL DATA
          dashboardStatsAsync.when(
            data: (stats) => Row(
              children: [
                Expanded(
                  child: pendingCountAsync.when(
                    data: (count) => _buildStatCard(
                      'Pending',
                      count.toString(),
                      Icons.pending,
                      Colors.orange,
                    ),
                    loading: () => _buildStatCard(
                      'Pending',
                      '...',
                      Icons.pending,
                      Colors.orange,
                    ),
                    error: (_, __) => _buildStatCard(
                      'Pending',
                      '0',
                      Icons.pending,
                      Colors.orange,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: overdueCountAsync.when(
                    data: (count) => _buildStatCard(
                      'Overdue',
                      count.toString(),
                      Icons.warning,
                      Colors.red,
                    ),
                    loading: () => _buildStatCard(
                      'Overdue',
                      '...',
                      Icons.warning,
                      Colors.red,
                    ),
                    error: (_, __) => _buildStatCard(
                      'Overdue',
                      '0',
                      Icons.warning,
                      Colors.red,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Total Payments',
                    stats.totalPayments.toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Text('Error: $error'),
          ),
          const SizedBox(height: 24),

          // Overdue Warning
          overdueCountAsync.when(
            data: (overdueCount) {
              if (overdueCount > 0) {
                return Container(
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
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          if ((overdueCountAsync.asData?.value ?? 0) > 0)
            const SizedBox(height: 16),

          // Spending Summary - REAL DATA
          dashboardStatsAsync.when(
            data: (stats) => Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.monetization_on,
                          size: 18, color: Color(0xFF2196F3)),
                      const SizedBox(width: 8),
                      const Text(
                        'Financial Summary',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Total Spending',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rp ${NumberFormat('#,###').format(stats.totalSpending)}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2196F3),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Pending Payments:',
                          style: TextStyle(color: Colors.grey[600])),
                      pendingCountAsync.when(
                        data: (count) => Text(
                          count.toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        loading: () => const Text('...'),
                        error: (_, __) => const Text('0'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Overdue Payments:',
                          style: TextStyle(color: Colors.grey[600])),
                      overdueCountAsync.when(
                        data: (count) => Text(
                          count.toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        loading: () => const Text('...'),
                        error: (_, __) => const Text('0'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 16),

          // Quick Action
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.go('/payment'),
              icon: const Icon(Icons.payment),
              label: const Text('Manage Payments'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
              ),
            ),
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
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          )
        ],
      ),
    );
  }
}


