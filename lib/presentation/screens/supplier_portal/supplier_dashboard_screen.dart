import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupplierDashboardScreen extends ConsumerStatefulWidget {
  const SupplierDashboardScreen({super.key});

  @override
  ConsumerState<SupplierDashboardScreen> createState() =>
      _SupplierDashboardScreenState();
}

class _SupplierDashboardScreenState
    extends ConsumerState<SupplierDashboardScreen> {
  String? _supplierName;
  Map<String, int> _stats = {
    'active_pos': 0,
    'pending_shipments': 0,
    'completed_shipments': 0,
  };
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final userEmail = supabase.auth.currentUser?.email;

      if (userEmail == null) throw Exception('Not logged in');

      // Get supplier info
      final supplierResponse = await supabase
          .from('suppliers')
          .select()
          .eq('auth_email', userEmail)
          .single();

      final supplierId = supplierResponse['id'];
      _supplierName = supplierResponse['name'];

      // Get active POs count
      final posResponse = await supabase
          .from('purchase_order')
          .select('id')
          .eq('supplier_id', supplierId)
          .eq('status', 'approved')
          .count();

      // Get pending shipments count
      final pendingShipmentsResponse = await supabase
          .from('shipment')
          .select('id')
          .eq('supplier_id', supplierId)
          .eq('status', 'pending')
          .count();

      // Get completed shipments count
      final completedShipmentsResponse = await supabase
          .from('shipment')
          .select('id')
          .eq('supplier_id', supplierId)
          .eq('status', 'received')
          .count();

      if (mounted) {
        setState(() {
          _stats = {
            'active_pos': posResponse.count,
            'pending_shipments': pendingShipmentsResponse.count,
            'completed_shipments': completedShipmentsResponse.count,
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleLogout() async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        context.go('/supplier/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supplier Portal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Theme.of(context).primaryColor,
                            child: const Icon(
                              Icons.business,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome back!',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        color: Colors.grey,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _supplierName ?? 'Supplier',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Stats Cards
                  Text(
                    'Overview',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.5,
                    children: [
                      _buildStatCard(
                        context,
                        'Active POs',
                        _stats['active_pos']!,
                        Icons.shopping_cart,
                        Colors.blue,
                      ),
                      _buildStatCard(
                        context,
                        'Pending Shipements',
                        _stats['pending_shipments']!,
                        Icons.pending_actions,
                        Colors.orange,
                      ),
                      _buildStatCard(
                        context,
                        'Completed',
                        _stats['completed_shipments']!,
                        Icons.check_circle,
                        Colors.green,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Quick Actions
                  Text(
                    'Quick Actions',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 2,
                    children: [
                      _buildActionCard(
                        context,
                        'View Purchase Orders',
                        Icons.list_alt,
                        Colors.blue,
                        () => context.go('/supplier/pos'),
                      ),
                      _buildActionCard(
                        context,
                        'Create Shipment',
                        Icons.add_box,
                        Colors.green,
                        () => context.go('/supplier/shipment/create'),
                      ),
                      _buildActionCard(
                        context,
                        'My Shipments',
                        Icons.local_shipping,
                        Colors.orange,
                        () => context.go('/supplier/shipments'),
                      ),
                      _buildActionCard(context, 'Help & Support',
                          Icons.help_outline, Colors.grey, () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Contact admin for support')),
                        );
                      })
                    ],
                  )
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    int value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value.toString(),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  size: 16, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
