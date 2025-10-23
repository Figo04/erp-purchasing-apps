import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class UserDashboardContent extends ConsumerWidget {
  final String userId;

  const UserDashboardContent({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'My Purchase Requisitions',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2196F3)),
          ),
          const SizedBox(height: 4),
          Text(
            'Manage your purchase requisitions here',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),

          // Stats row
          Row(
            children: [
              Expanded(
                  child: _buildStatCard(
                      'Total PR', '5', Icons.description, Colors.blue)),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildStatCard(
                      'Pending', '2', Icons.pending, Colors.orange)),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildStatCard(
                      'Approved', '2', Icons.check_circle, Colors.green)),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildStatCard(
                      'Rejected', '1', Icons.cancel, Colors.red)),
            ],
          ),
          const SizedBox(height: 24),

          // Quick Action
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.go('/pr/create'),
              icon: const Icon(Icons.add),
              label: const Text('Create New Purchase Requisition'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // My PR List
          _buildMyPRList(context),
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

  Widget _buildMyPRList(BuildContext context) {
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
              const Icon(Icons.history, size: 18, color: Color(0xFF2196F3)),
              const SizedBox(width: 8),
              const Text(
                'My Recent PRs',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.go('/pr-history'),
                child: const Text('view All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildPRItem(
              'PR-2024-045', 'Pending Approval', Colors.orange, '2 days ago'),
          const Divider(height: 24),
          _buildPRItem('PR-2024-044', 'Approved', Colors.green, '5 days ago'),
          const Divider(height: 24),
          _buildPRItem('PR-2024-043', 'Rejected', Colors.red, '1 week ago'),
        ],
      ),
    );
  }

  Widget _buildPRItem(String number, String status, Color color, String time) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.description, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                number,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Text(
                time,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              )
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.01),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            status,
            style: TextStyle(
                fontSize: 11, color: color, fontWeight: FontWeight.w600),
          ),
        )
      ],
    );
  }
}
