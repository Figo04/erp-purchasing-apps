import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:erp_purchasing_apps/data/providers/dashboard_provider.dart';
import 'package:erp_purchasing_apps/data/providers/inventory_provider.dart';

class WarehouseDashboardContent extends ConsumerWidget {
  const WarehouseDashboardContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardStatsAsync = ref.watch(dashboardStatsProvider);
    final lowStockCountAsync = ref.watch(lowStockCountProvider);
    final itemTrackingSummaryAsync = ref.watch(itemTrackingSummaryProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Warehouse Dashboard',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2196F3),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Manage goods receipt and inventory',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),

          // Stats Row - REAL DATA
          dashboardStatsAsync.when(
            data: (stats) => Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Incoming',
                    stats.incomingShipments.toString(),
                    Icons.local_shipping,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Completed LPB',
                    stats.totalLPB.toString(),
                    Icons.done_all,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: lowStockCountAsync.when(
                    data: (count) => _buildStatCard(
                      'Low Stock',
                      count.toString(),
                      Icons.warning,
                      Colors.red,
                    ),
                    loading: () => _buildStatCard(
                      'Low Stock',
                      '...',
                      Icons.warning,
                      Colors.red,
                    ),
                    error: (_, __) => _buildStatCard(
                      'Low Stock',
                      '0',
                      Icons.warning,
                      Colors.red,
                    ),
                  ),
                ),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Text('Error: $error'),
          ),
          const SizedBox(height: 24),

          // Low Stock Warning
          lowStockCountAsync.when(
            data: (count) {
              if (count > 0) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '$count item${count > 1 ? 's' : ''} need restocking!',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go('/inventory'),
                        child: const Text('View'),
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
          if ((lowStockCountAsync.asData?.value ?? 0) > 0)
            const SizedBox(height: 16),

          // Quick Actions
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/receipt'),
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Scan QR'),
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
                  onPressed: () => context.go('/inventory'),
                  icon: const Icon(Icons.inventory_2),
                  label: const Text('View Inventory'),
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

          // Item Tracking Summary - REAL DATA
          itemTrackingSummaryAsync.when(
            data: (summary) {
              if (summary.isEmpty) {
                return const SizedBox.shrink();
              }

              return Container(
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
                        const Icon(Icons.track_changes,
                            size: 18, color: Color(0xFF2196F3)),
                        const SizedBox(width: 8),
                        const Text(
                          'Item Tracking Status',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildStatusRow(
                        'Shipped', '${summary['shipped'] ?? 0}', Colors.indigo),
                    const SizedBox(height: 12),
                    _buildStatusRow(
                        'Received', '${summary['received'] ?? 0}', Colors.teal),
                    const SizedBox(height: 12),
                    _buildStatusRow('In Stock', '${summary['in_stock'] ?? 0}',
                        Colors.green),
                    const SizedBox(height: 12),
                    _buildStatusRow(
                        'Complete', '${summary['complete'] ?? 0}', Colors.blue),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 24),

          // Inventory Stats - REAL DATA
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
                      const Icon(Icons.inventory_2,
                          size: 18, color: Color(0xFF2196F3)),
                      const SizedBox(width: 8),
                      const Text(
                        'Inventory Overview',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildStatusRow('Pending Receipt',
                      stats.incomingShipments.toString(), Colors.orange),
                  const SizedBox(height: 12),
                  _buildStatusRow('Low Stock Items',
                      stats.lowStockItems.toString(), Colors.red),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => context.go('/inventory'),
                          icon: const Icon(Icons.view_list),
                          label: const Text('View Inventory'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => context.go('/asset'),
                          icon: const Icon(Icons.assessment),
                          label: const Text('View Assets'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
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
            textAlign: TextAlign.center,
          )
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        )
      ],
    );
  }
}
