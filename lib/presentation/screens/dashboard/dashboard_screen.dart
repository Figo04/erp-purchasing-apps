import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:erp_purchasing_apps/data/providers/auth_providers.dart';
import 'package:go_router/go_router.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authStateProvider.notifier).signOut();
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(currentUser?.fullName ?? 'User'),
              accountEmail: Text(currentUser?.email ?? ''),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  currentUser?.username.substring(0, 1).toUpperCase() ?? 'U',
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('User Management'),
              onTap: () => context.go('/users'),
            ),
            ListTile(
              leading: const Icon(Icons.request_page),
              title: const Text('Purchase Requisition'),
              onTap: () => context.go('/pr'),
            ),
            ListTile(
              leading: const Icon(Icons.shopping_cart),
              title: const Text('Purchase Order'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to PO
              },
            ),
            ListTile(
              leading: const Icon(Icons.inventory),
              title: const Text('Inventory'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to Inventory
              },
            ),
            ListTile(
              leading: const Icon(Icons.assessment_sharp),
              title: const Text('Asset'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to Asset
              },
            ),
            ListTile(
              leading: const Icon(Icons.payment),
              title: const Text('Payment'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to Payment
              },
            ),
            ListTile(
              leading: const Icon(Icons.business),
              title: const Text('Suppliers'),
              onTap: () => context.go('/suppliers'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                await ref.read(authStateProvider.notifier).signOut();
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, ${currentUser?.fullName ?? 'User'}!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Role: ${currentUser?.role.toUpperCase()}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey,
                  ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildDashboardCard(
                    context,
                    icon: Icons.request_page,
                    title: 'PR',
                    count: '0',
                    color: Colors.blue,
                    onTap: () => context.go('/pr'),
                  ),
                  _buildDashboardCard(
                    context,
                    icon: Icons.shopping_cart,
                    title: 'PO',
                    count: '0',
                    color: Colors.green,
                    onTap: () {},
                  ),
                  _buildDashboardCard(
                    context,
                    icon: Icons.inventory,
                    title: 'Inventory',
                    count: '0',
                    color: Colors.orange,
                    onTap: () {},
                  ),
                  _buildDashboardCard(
                    context,
                    icon: Icons.payment,
                    title: 'Payment',
                    count: '0',
                    color: Colors.purple,
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String count,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                count,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
