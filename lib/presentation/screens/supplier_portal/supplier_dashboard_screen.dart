import 'package:erp_purchasing_apps/core/constants/api_constants.dart';
import 'package:erp_purchasing_apps/core/service/api_service.dart';
import 'package:erp_purchasing_apps/data/providers/supplier_auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SupplierDashboardScreen extends ConsumerStatefulWidget {
  const SupplierDashboardScreen({super.key});

  @override
  ConsumerState<SupplierDashboardScreen> createState() =>
      _SupplierDashboardScreenState();
}

class _SupplierDashboardScreenState
    extends ConsumerState<SupplierDashboardScreen> {
  final ApiService _apiService = ApiService();

  String? _supplierName;
  String? _supplierId;
  Map<String, int> _stats = {
    'active_pos': 0,
    'pending_shipments': 0,
    'completed_shipments': 0,
  };
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Get supplier info from provider
      final supplier = ref.read(currentSupplierProvider);

      if (supplier == null) {
        throw Exception('Supplier not found');
      }

      _supplierName = supplier.name;
      _supplierId = supplier.id;

      // ✅ GANTI INI - Pakai endpoint supplier
      final posResponse = await _apiService.get(
        ApiEndpoints.supplierPOs, // ← Ganti dari purchaseOrders ke supplierPOs
        queryParameters: {
          'status': 'approved', // ← Hapus supplier_id, backend otomatis filter
        },
      );

      // ✅ GANTI INI JUGA - Pakai endpoint supplier shipments
      final pendingShipmentsResponse = await _apiService.get(
        ApiEndpoints.supplierShipments, // ← Ganti dari shipments
        queryParameters: {
          'status': 'pending', // ← Hapus supplier_id
        },
      );

      // ✅ DAN INI
      final completedShipmentsResponse = await _apiService.get(
        ApiEndpoints.supplierShipments, // ← Ganti dari shipments
        queryParameters: {
          'status': 'received', // ← Hapus supplier_id
        },
      );

      if (mounted) {
        setState(() {
          final posData = posResponse.data as List?;
          final pendingData = pendingShipmentsResponse.data as List?;
          final completedData = completedShipmentsResponse.data as List?;

          _stats = {
            'active_pos': posData?.length ?? 0,
            'pending_shipments': pendingData?.length ?? 0,
            'completed_shipments': completedData?.length ?? 0,
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading dashboard: $e');
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
      print('👋 Logout button clicked');

      // ✅ Pakai SupplierAuthNotifier.signOut()
      await ref.read(supplierAuthStateProvider.notifier).signOut();

      print('✅ Logout complete, provider cleared');

      if (mounted) {
        // Small delay untuk pastikan state propagate
        await Future.delayed(const Duration(milliseconds: 100));

        print('🚀 Navigating to login...');
        context.go('/supplier/login');
        print('✅ Navigation complete');
      }
    } catch (e) {
      print('❌ Logout error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: $e'),
            backgroundColor: Colors.red,
          ),
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
                        'Pending Shipments',
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
