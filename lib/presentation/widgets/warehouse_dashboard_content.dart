        import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:erp_purchasing_apps/data/providers/inventory_provider.dart';

class WarehouseDashboardContent extends ConsumerWidget {
  const WarehouseDashboardContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lowStockCount = ref.watch(lowStockCountProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Receiving Overview',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2196F3)),
          ),
          const SizedBox(height: 4),
          Text(
            'Manage goods receipt and inventory',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),

          // Stats Row
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                    'Pending Receipt', '6', Icons.inbox, Colors.orange),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                    'Received Today', '15', Icons.done_all, Colors.green),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                    'Low Stock', '$lowStockCount', Icons.warning, Colors.red),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Quick Action
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.go('/receipt/create'),
              icon: const Icon(Icons.add),
              label: const Text('Create Goods Receipt (LPB)'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Inventory Status
          _buildInventoryStatus(lowStockCount),
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

  Widget _buildInventoryStatus(int lowStockCount) {
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
              const Icon(Icons.inventory_2, size: 18, color: Color(0xFF2196F3)),
              const SizedBox(width: 8),
              const Text(
                'Inventory Status',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildStatusRow('Total Items', '342', Colors.blue),
          const SizedBox(height: 12),
          _buildStatusRow('Need Restocking', '$lowStockCount', Colors.orange),
          const SizedBox(height: 12),
          _buildStatusRow('Damaged Items', '2', Colors.red),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.view_list),
              label: const Text('View Full Inventory'),
            ),
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
