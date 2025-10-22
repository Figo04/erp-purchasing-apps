import 'package:erp_purchasing_apps/data/providers/asset_provider.dart';
import 'package:erp_purchasing_apps/data/providers/inventory_provider.dart';
import 'package:erp_purchasing_apps/data/providers/payment_provider.dart';
import 'package:erp_purchasing_apps/data/providers/pr_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:erp_purchasing_apps/data/providers/auth_providers.dart';
import 'package:go_router/go_router.dart';

class DashboardScreen2 extends ConsumerWidget {
  const DashboardScreen2({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final pendingCount = ref.watch(pendingPRCountProvider);
    final lowStockCount = ref.watch(lowStockCountProvider);
    final borrowedAssetsCount = ref.watch(borrowedAssetsCountProvider);
    final overduePaymentsCount = ref.watch(overduePaymentsCountProvider);

    // Responsive check
    final isDesktop = MediaQuery.of(context).size.width > 900;

    if (isDesktop) {
      return _buildDesktopLayout(
        context,
        ref,
        currentUser,
        pendingCount,
        lowStockCount,
        borrowedAssetsCount,
        overduePaymentsCount,
      );
    } else {
      return _buildMobileLayout(
        context,
        ref,
        currentUser,
        pendingCount,
        lowStockCount,
        borrowedAssetsCount,
        overduePaymentsCount,
      );
    }
  }

  // Desktop Layout dengan Sidebar
  Widget _buildDesktopLayout(
    BuildContext context,
    WidgetRef ref,
    dynamic currentUser,
    int pendingCount,
    int lowStockCount,
    int borrowedAssetsCount,
    int overduePaymentsCount,
  ) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 250,
            color: const Color(0xFF1ABC9C),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Profile
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.white.withOpacity(0.3),
                        child: Text(
                          currentUser?.username.substring(0, 1).toUpperCase() ??
                              'A',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${currentUser?.fullName ?? 'User'}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${currentUser?.role.toUpperCase()}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white24, height: 1),
                // Menu Items
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      _buildSideMenuItem(
                        context,
                        Icons.dashboard,
                        'Dashboard',
                        () {},
                        isActive: true,
                      ),
                      _buildSideMenuItem(
                        context,
                        Icons.people,
                        'User Management',
                        () => context.go('/users'),
                      ),
                      _buildSideMenuItemWithBadge(
                        context,
                        Icons.request_page,
                        'Purchase Requisition',
                        () => context.go('/pr'),
                        pendingCount,
                      ),
                      _buildSideMenuItem(
                        context,
                        Icons.shopping_cart,
                        'Purchase Order',
                        () => context.go('/po'),
                      ),
                      _buildSideMenuItemWithBadge(
                        context,
                        Icons.inventory,
                        'Inventory',
                        () => context.go('/inventory'),
                        lowStockCount,
                      ),
                      _buildSideMenuItemWithBadge(
                        context,
                        Icons.assessment,
                        'Asset',
                        () => context.go('/asset'),
                        borrowedAssetsCount,
                        badgeColor: Colors.orange,
                      ),
                      _buildSideMenuItemWithBadge(
                        context,
                        Icons.payment,
                        'Payment',
                        () => context.go('/payment'),
                        overduePaymentsCount,
                      ),
                      _buildSideMenuItem(
                        context,
                        Icons.business,
                        'Suppliers',
                        () => context.go('/suppliers'),
                      ),
                      _buildSideMenuItem(
                        context,
                        Icons.history,
                        'PR History',
                        () => context.go('/pr-history'),
                      ),
                      if (currentUser?.role == 'admin' ||
                          currentUser?.role == 'purchasing')
                        _buildSideMenuItem(
                          context,
                          Icons.approval,
                          'PR Approval',
                          () => context.go('/pr-approval'),
                        ),
                      _buildSideMenuItem(
                        context,
                        Icons.check_circle,
                        'PO Approval',
                        () => context.go('/po-approval'),
                      ),
                      if (currentUser?.role == 'admin' ||
                          currentUser?.role == 'warehouse')
                        _buildSideMenuItem(
                          context,
                          Icons.receipt_long,
                          'Receipt',
                          () => context.go('/receipt'),
                        ),
                      _buildSideMenuItem(
                        context,
                        Icons.history,
                        'Creat account suppliers',
                        () => context.go('/admin'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Main Content
          Expanded(
            child: Column(
              children: [
                // Header
                Container(
                  height: 60,
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      const Text(
                        'ERP System',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.logout),
                        onPressed: () async {
                          await ref.read(authStateProvider.notifier).signOut();
                        },
                      ),
                    ],
                  ),
                ),
                // Dashboard Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Welcome Text
                        Text(
                          'Welcome, ${currentUser?.fullName ?? 'User'}!',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2196F3),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Here's what's happening with your ERP system today",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Stats Cards Row 1 - 4 cards
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'Total PR',
                                '24',
                                Icons.description,
                                const Color(0xFF2196F3),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildStatCard(
                                'Total PO',
                                '18',
                                Icons.shopping_cart,
                                const Color(0xFF4CAF50),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildStatCard(
                                'Inventory Items',
                                '342',
                                Icons.inventory_2,
                                const Color(0xFF9C27B0),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildStatCard(
                                'Active Users',
                                '15',
                                Icons.people,
                                const Color(0xFF2196F3),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Stats Cards Row 2 - 3 cards
                        Row(
                          children: [
                            Expanded(
                              child: _buildMoneyCard(
                                'Monthly Spending',
                                '\$45,231',
                                '+13.2% from last month',
                                const Color(0xFF2196F3),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildAlertCard(
                                'Pending Approvals',
                                '8',
                                'Requires attention',
                                Colors.orange,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildSuccessCard(
                                'Completed Today',
                                '12',
                                'Great progress!',
                                Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Bottom Section - 2 columns
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Recent Activity
                            Expanded(
                              flex: 5,
                              child: _buildRecentActivity(),
                            ),
                            const SizedBox(width: 16),
                            // Pending Approvals
                            Expanded(
                              flex: 4,
                              child: _buildPendingApprovals(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Mobile Layout
  Widget _buildMobileLayout(
    BuildContext context,
    WidgetRef ref,
    dynamic currentUser,
    int pendingCount,
    int lowStockCount,
    int borrowedAssetsCount,
    int overduePaymentsCount,
  ) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: const Color(0xFF1ABC9C),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authStateProvider.notifier).signOut();
            },
          ),
        ],
      ),
      drawer: _buildDrawer(
        context,
        ref,
        currentUser,
        pendingCount,
        lowStockCount,
        borrowedAssetsCount,
        overduePaymentsCount,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome Back, ${currentUser?.fullName ?? 'System Admin'}!',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2196F3),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Here's what's happening with your ERP system today",
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),
            // Mobile grid
            _buildStatCard(
                'Total PR', '24', Icons.description, const Color(0xFF2196F3)),
            const SizedBox(height: 12),
            _buildStatCard(
                'Total PO', '18', Icons.shopping_cart, const Color(0xFF4CAF50)),
            const SizedBox(height: 12),
            _buildStatCard('Inventory Items', '342', Icons.inventory_2,
                const Color(0xFF9C27B0)),
            const SizedBox(height: 12),
            _buildStatCard(
                'Active Users', '15', Icons.people, const Color(0xFF2196F3)),
            const SizedBox(height: 16),
            _buildMoneyCard('Monthly Spending', '\$45,231',
                '+13.2% from last month', const Color(0xFF2196F3)),
            const SizedBox(height: 12),
            _buildAlertCard(
                'Pending Approvals', '8', 'Requires attention', Colors.orange),
            const SizedBox(height: 12),
            _buildSuccessCard(
                'Completed Today', '12', 'Great progress!', Colors.green),
            const SizedBox(height: 20),
            _buildRecentActivity(),
            const SizedBox(height: 16),
            _buildPendingApprovals(),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(
    BuildContext context,
    WidgetRef ref,
    dynamic currentUser,
    int pendingCount,
    int lowStockCount,
    int borrowedAssetsCount,
    int overduePaymentsCount,
  ) {
    return Drawer(
      child: Container(
        color: const Color(0xFF1ABC9C),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: const Color(0xFF1ABC9C).withOpacity(0.8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white.withOpacity(0.3),
                    radius: 30,
                    child: Text(
                      currentUser?.username.substring(0, 1).toUpperCase() ??
                          'A',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    currentUser?.fullName ?? 'System Admin',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    currentUser?.email ?? 'admin@example.com',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            _buildDrawerMenuItem(context, Icons.dashboard, 'Dashboard', () {
              Navigator.pop(context);
            }),
            _buildDrawerMenuItem(context, Icons.people, 'User Management', () {
              Navigator.pop(context);
              context.go('/users');
            }),
            _buildDrawerMenuItemWithBadge(
              context,
              Icons.request_page,
              'Purchase Requisition',
              () {
                Navigator.pop(context);
                context.go('/pr');
              },
              pendingCount,
            ),
            _buildDrawerMenuItem(context, Icons.shopping_cart, 'Purchase Order',
                () {
              Navigator.pop(context);
              context.go('/po');
            }),
            _buildDrawerMenuItemWithBadge(
              context,
              Icons.inventory,
              'Inventory',
              () {
                Navigator.pop(context);
                context.go('/inventory');
              },
              lowStockCount,
            ),
            _buildDrawerMenuItemWithBadge(
              context,
              Icons.assessment,
              'Asset',
              () {
                Navigator.pop(context);
                context.go('/asset');
              },
              borrowedAssetsCount,
              badgeColor: Colors.orange,
            ),
            _buildDrawerMenuItemWithBadge(
              context,
              Icons.payment,
              'Payment',
              () {
                Navigator.pop(context);
                context.go('/payment');
              },
              overduePaymentsCount,
            ),
            _buildDrawerMenuItem(context, Icons.business, 'Suppliers', () {
              Navigator.pop(context);
              context.go('/suppliers');
            }),
            _buildDrawerMenuItem(context, Icons.history, 'PR History', () {
              Navigator.pop(context);
              context.go('/pr-history');
            }),
            if (currentUser?.role == 'admin' ||
                currentUser?.role == 'purchasing')
              _buildDrawerMenuItem(context, Icons.approval, 'PR Approval', () {
                Navigator.pop(context);
                context.go('/pr-approval');
              }),
            _buildDrawerMenuItem(context, Icons.check_circle, 'PO Approval',
                () {
              Navigator.pop(context);
              context.go('/po-approval');
            }),
            if (currentUser?.role == 'admin' ||
                currentUser?.role == 'warehouse')
              _buildDrawerMenuItem(context, Icons.receipt_long, 'Receipt', () {
                Navigator.pop(context);
                context.go('/receipt');
              }),
            const Divider(color: Colors.white24),
            _buildDrawerMenuItem(context, Icons.logout, 'Logout', () async {
              await ref.read(authStateProvider.notifier).signOut();
            }),
          ],
        ),
      ),
    );
  }

  // Sidebar Menu Item
  Widget _buildSideMenuItem(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isActive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? Colors.white.withOpacity(0.15) : null,
            borderRadius: BorderRadius.circular(4),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSideMenuItemWithBadge(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
    int count, {
    Color badgeColor = Colors.red,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, color: Colors.white, size: 20),
                  if (count > 0)
                    Positioned(
                      right: -8,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: badgeColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          count.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerMenuItem(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: onTap,
    );
  }

  Widget _buildDrawerMenuItemWithBadge(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
    int count, {
    Color badgeColor = Colors.red,
  }) {
    return ListTile(
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(icon, color: Colors.white),
          if (count > 0)
            Positioned(
              right: -8,
              top: -4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Text(
                  count.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: onTap,
    );
  }

  // Stat Card
  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
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
          Icon(icon, color: color.withOpacity(0.7), size: 32),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Money Card with trend
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
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.monetization_on,
                color: color.withOpacity(0.5),
                size: 32,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.arrow_upward,
                color: Colors.green,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.green,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Alert Card
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
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.access_time,
                color: color.withOpacity(0.5),
                size: 32,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.warning,
                color: color,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Success Card
  Widget _buildSuccessCard(
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
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.check_circle,
                color: color.withOpacity(0.5),
                size: 32,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.check,
                color: color,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Recent Activity Widget
  Widget _buildRecentActivity() {
    return Container(
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 18,
                color: Colors.blue[700],
              ),
              const SizedBox(width: 8),
              const Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildActivityItem(
            Icons.check_circle,
            Colors.green,
            'Purchase Order #PO-2024-001 approved',
            '2 hours ago',
          ),
          _buildActivityItem(
            Icons.description,
            Colors.blue,
            'New Purchase Requisition #PR-2024-045',
            '4 hours ago',
          ),
          _buildActivityItem(
            Icons.inventory,
            Colors.blue,
            'Inventory updated for Item #ITM-890',
            '6 hours ago',
          ),
          _buildActivityItem(
            Icons.check_circle,
            Colors.green,
            'Payment processed for Supplier XYZ',
            '1 day ago',
          ),
          _buildActivityItem(
            Icons.warning,
            Colors.red,
            'Pending approval for PR-2024-044',
            '1 day ago',
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(
    IconData icon,
    Color color,
    String title,
    String time, {
    bool isLast = false,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (!isLast) ...[
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  // Pending Approvals Widget
  Widget _buildPendingApprovals() {
    return Container(
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.error_outline,
                size: 18,
                color: Colors.red[700],
              ),
              const SizedBox(width: 8),
              const Text(
                'Pending Approvals',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildApprovalItem(
            'PR-2024-044',
            'IT Department',
            '\$12,500',
            'High',
            Colors.red,
          ),
          const SizedBox(height: 12),
          _buildApprovalItem(
            'PO-2024-023',
            'Operations',
            '\$8,200',
            'Medium',
            Colors.orange,
          ),
          const SizedBox(height: 12),
          _buildApprovalItem(
            'PR-2024-043',
            'Marketing',
            '\$5,400',
            'Low',
            Colors.grey,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalItem(
    String id,
    String department,
    String amount,
    String priority,
    Color priorityColor, {
    bool isLast = false,
  }) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        id,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: priorityColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          priority,
                          style: TextStyle(
                            color: priorityColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    department,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    amount,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Review',
                            style: TextStyle(
                                fontSize: 12, color: Colors.blue[700]),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_forward,
                              size: 14, color: Colors.blue[700]),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (!isLast) const Divider(height: 1),
      ],
    );
  }
}
