import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:erp_purchasing_apps/data/providers/dashboard_provider.dart';
import 'package:erp_purchasing_apps/data/providers/auth_providers.dart';

class PurchasingDashboardContent extends ConsumerWidget {
  const PurchasingDashboardContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final dashboardStatsAsync = ref.watch(dashboardStatsProvider);
    final purchaseFlowAsync = ref.watch(
      purchaseFlowSummaryProvider(PurchaseFlowFilterParams()),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Header
          Text(
            'Purchasing Dashboard',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2196F3),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Welcome, ${currentUser?.fullName ?? 'Purchasing'}',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),

          // Stats Overview
          dashboardStatsAsync.when(
            data: (stats) => Column(
              children: [
                // Row 1: PR & PO
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total PR',
                        stats.totalPR.toString(),
                        Icons.description,
                        const Color(0xFF2196F3),
                        subtitle: '${stats.pendingPR} pending approval',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        'Total PO',
                        stats.totalPO.toString(),
                        Icons.shopping_cart,
                        const Color(0xFF4CAF50),
                        subtitle: '${stats.pendingPO} pending',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        'Total LPB',
                        stats.totalLPB.toString(),
                        Icons.inventory,
                        const Color(0xFF9C27B0),
                        subtitle: 'Goods receipts',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Row 2: Financial & Alerts
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildMoneyCard(
                        'Total Spending',
                        'Rp ${NumberFormat('#,###').format(stats.totalSpending)}',
                        'This month',
                        const Color(0xFF2196F3),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildAlertCard(
                        'Incoming Shipments',
                        stats.incomingShipments.toString(),
                        'Need attention',
                        Colors.orange,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Error: $error')),
          ),
          const SizedBox(height: 24),

          // Purchase Flow Overview
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Purchase Orders',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to PO list
                },
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          purchaseFlowAsync.when(
            data: (flows) {
              if (flows.isEmpty) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.inbox, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 8),
                          Text(
                            'No purchase orders yet',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              // Group by overall status
              final pending = flows.where((f) => f.overallStatus == 'pending').length;
              final approved = flows.where((f) => f.overallStatus == 'approved').length;
              final ordered = flows.where((f) => f.overallStatus == 'ordered').length;
              final completed = flows.where((f) => f.overallStatus == 'completed').length;

              return Column(
                children: [
                  // Status Summary
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildMiniStat('Pending', pending, Colors.orange),
                          _buildMiniStat('Approved', approved, Colors.blue),
                          _buildMiniStat('Ordered', ordered, Colors.purple),
                          _buildMiniStat('Completed', completed, Colors.green),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Recent Flows
                  ...flows.take(10).map((flow) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getStatusColor(flow.overallStatus),
                          child: Icon(
                            _getStatusIcon(flow.overallStatus),
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(
                              flow.prNumber,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            if (flow.poNumber != null) ...[
                              const Icon(Icons.arrow_forward, size: 12),
                              Text(
                                flow.poNumber!,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Division: ${flow.divisionName}'),
                            if (flow.daysSincePR != null)
                              Text(
                                '${flow.daysSincePR!.round()} days since PR',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: flow.daysSincePR! > 7 ? Colors.red : Colors.grey,
                                ),
                              ),
                          ],
                        ),
                        trailing: Chip(
                          label: Text(
                            flow.overallStatus.toUpperCase(),
                            style: const TextStyle(fontSize: 10),
                          ),
                          backgroundColor: _getStatusColor(flow.overallStatus).withOpacity(0.2),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Error: $error')),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color, {
    String? subtitle,
  }) {
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
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMoneyCard(
    String label,
    String value,
    String subtitle,
    Color color,
  ) {
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
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              Icon(Icons.monetization_on, color: color.withOpacity(0.5), size: 32),
            ],
          ),
          const SizedBox(height: 8),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildAlertCard(
    String label,
    String value,
    String subtitle,
    Color color,
  ) {
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
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.warning, color: color, size: 14),
              const SizedBox(width: 4),
              Text(subtitle, style: TextStyle(color: color, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
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
}