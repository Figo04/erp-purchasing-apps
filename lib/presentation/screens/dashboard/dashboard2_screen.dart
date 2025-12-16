import 'package:erp_purchasing_apps/data/providers/asset_provider.dart';
import 'package:erp_purchasing_apps/data/providers/inventory_provider.dart';
import 'package:erp_purchasing_apps/data/providers/payment_provider.dart';
import 'package:erp_purchasing_apps/data/providers/pr_provider.dart';
import 'package:erp_purchasing_apps/core/utils/rbac_helper.dart';
import 'package:erp_purchasing_apps/presentation/widgets/user_dashboard_content.dart';
import 'package:erp_purchasing_apps/presentation/widgets/purchasing_dashboard_content.dart';
import 'package:erp_purchasing_apps/presentation/widgets/warehouse_dashboard_content.dart';
import 'package:erp_purchasing_apps/presentation/widgets/finance_dashboard_content.dart';
import 'package:erp_purchasing_apps/presentation/widgets/kadiv_dashboard_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:erp_purchasing_apps/data/providers/auth_providers.dart';
import 'package:go_router/go_router.dart';

class DashboardScreen2 extends ConsumerWidget {
  const DashboardScreen2({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final userRole = currentUser?.role?.toLowerCase();

    // ✅ ONLY watch providers if user has permission
    final pendingCount = ref.watch(pendingPRCountProvider);

    // ✅ Conditional watching based on role
    final lowStockCount = RBACHelper.canAccessMenu(userRole, 'inventory')
        ? ref.watch(lowStockCountProvider)
        : const AsyncValue.data(0);

    final borrowedAssetsCount = RBACHelper.canAccessMenu(userRole, 'asset')
        ? ref.watch(borrowedAssetsCountProvider)
        : const AsyncValue.data(0);

    final overduePaymentsCount = RBACHelper.canAccessMenu(userRole, 'payment')
        ? ref.watch(overduePaymentsCountProvider)
        : const AsyncValue.data(0);

    // Dekstop only - no responsive check
    return _buildDesktopLayout(
      context,
      ref,
      currentUser,
      pendingCount,
      lowStockCount.asData?.value ?? 0,
      borrowedAssetsCount.asData?.value ?? 0,
      overduePaymentsCount.asData?.value ?? 0,
    );
  }

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
          // Sidebar with RBAC
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
                              color: Colors.white, fontWeight: FontWeight.bold),
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
                                  fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              RBACHelper.getRoleDisplayName(
                                  currentUser?.role ?? 'User'),
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 11),
                              overflow: TextOverflow.ellipsis,
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                const Divider(color: Colors.white24, height: 1),

                // Menu Items with RBAC filtering
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      _buildSideMenuItem(
                          context, Icons.dashboard, 'Dashboard', () {},
                          isActive: true),

                      // User Management - Admin only
                      if (RBACHelper.canAccessMenu(currentUser?.role, 'users'))
                        _buildSideMenuItem(context, Icons.people,
                            'User Management', () => context.go('/users')),

                      if (RBACHelper.canAccessMenu(
                          currentUser?.role, 'master_product'))
                        _buildSideMenuItem(context, Icons.dataset,
                            'Master data', () => context.go('/master_product')),

                      // Purchase Requisition - All roles
                      if (RBACHelper.canAccessMenu(currentUser?.role, 'pr'))
                        _buildSideMenuItemWithBadge(
                          context,
                          Icons.request_page,
                          'Purchase Requisition',
                          () => context.go('/pr'),
                          pendingCount,
                        ),

                      // Purchase Order - Admin, Purchasing
                      if (RBACHelper.canAccessMenu(currentUser?.role, 'po'))
                        _buildSideMenuItem(context, Icons.shopping_cart,
                            'Purchase Order', () => context.go('/po')),

                      // Inventory - Admin, Warehouse
                      if (RBACHelper.canAccessMenu(
                          currentUser?.role, 'inventory'))
                        _buildSideMenuItemWithBadge(
                          context,
                          Icons.inventory,
                          'Inventory',
                          () => context.go('/inventory'),
                          lowStockCount,
                        ),

                      // Asset - Admin, Warehouse
                      if (RBACHelper.canAccessMenu(currentUser?.role, 'asset'))
                        _buildSideMenuItemWithBadge(
                          context,
                          Icons.assessment,
                          'Asset',
                          () => context.go('/asset'),
                          borrowedAssetsCount,
                          badgeColor: Colors.orange,
                        ),

                      // Payment - Admin, Finance
                      if (RBACHelper.canAccessMenu(
                          currentUser?.role, 'payment'))
                        _buildSideMenuItemWithBadge(
                          context,
                          Icons.payment,
                          'Payment',
                          () => context.go('/payment'),
                          overduePaymentsCount,
                        ),

                      // Suppliers - Admin, Purchasing
                      if (RBACHelper.canAccessMenu(
                          currentUser?.role, 'suppliers'))
                        _buildSideMenuItem(context, Icons.business, 'Suppliers',
                            () => context.go('/suppliers')),

                      // PR History - All roles
                      if (RBACHelper.canAccessMenu(
                          currentUser?.role, 'pr_history'))
                        _buildSideMenuItem(context, Icons.history, 'PR History',
                            () => context.go('/pr-history')),

                      // PR Approval - Admin, Purchasing, Kadiv
                      if (RBACHelper.canAccessMenu(
                          currentUser?.role, 'pr_approval'))
                        _buildSideMenuItem(context, Icons.approval,
                            'PR Approval', () => context.go('/pr-approval')),

                      // PO Approval - Admin, Purchasing, Kadiv
                      if (RBACHelper.canAccessMenu(
                          currentUser?.role, 'po_approval'))
                        _buildSideMenuItem(context, Icons.approval,
                            'PO Approval', () => context.go('/po-approval')),

                      // Assessment product - Admin, Kadiv
                      if (RBACHelper.canAccessMenu(
                          currentUser?.role, 'assessment_product'))
                        _buildSideMenuItem(
                            context,
                            Icons.approval,
                            'Assessment Product',
                            () => context.go('/assessment-product')),

                      if (RBACHelper.canAccessMenu(
                          currentUser?.role, 'assessment_supplier'))
                        _buildSideMenuItem(
                            context,
                            Icons.approval,
                            'Assessment Supplier',
                            () => context.go('/assessment-supplier')),

                      // Receipt - Admin, Warehouse, Purchasing
                      if (RBACHelper.canAccessMenu(
                          currentUser?.role, 'receipt'))
                        _buildSideMenuItem(context, Icons.receipt_long,
                            'Receipt', () => context.go('/receipt')),
                    ],
                  ),
                )
              ],
            ),
          ),

          // Main Content Area
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
                      const Text(
                        'ERP System',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.logout),
                        onPressed: () async {
                          await ref.read(authStateProvider.notifier).signOut();
                        },
                      )
                    ],
                  ),
                ),

                // Dashboard Content per Role
                Expanded(
                  child: _buiildDashboardContent(currentUser),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  // Dashboard content router based on role
  Widget _buiildDashboardContent(dynamic currentUser) {
    final userRole = currentUser?.role?.toLowerCase() ?? 'user';

    switch (userRole) {
      case 'admin':
        return _buildAdminDashboard(currentUser);
      case 'purchasing':
        return const PurchasingDashboardContent();
      case 'warehouse':
        return const WarehouseDashboardContent();
      case 'finance':
        return const FinanceDashboardContent();
      case 'kadiv':
        return const KadivDashboardContent();
      case 'user':
      default:
        return UserDashboardContent(userId: currentUser?.id ?? '');
    }
  }

  // Admin Dashboard - Keep original stats
  Widget _buildAdminDashboard(dynamic currentUser) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome, ${currentUser?.fullName ?? 'Admin'}!',
            style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2196F3)),
          ),
          const SizedBox(height: 4),
          Text(
            "ERP system",
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),

          // Stats Row 1
          Row(
            children: [
              Expanded(
                  child: _buildStatCard('Total PR', '24', Icons.description,
                      const Color(0xFF2196F3))),
              SizedBox(width: 16),
              Expanded(
                  child: _buildStatCard('Total PO', '18', Icons.shopping_cart,
                      const Color(0xFF4CAF50))),
              SizedBox(height: 16),
              Expanded(
                  child: _buildStatCard('Inventory Items', '342',
                      Icons.inventory_2, const Color(0xFF9C27B0))),
              SizedBox(width: 16),
              Expanded(
                  child: _buildStatCard('Total PO', '18', Icons.shopping_cart,
                      const Color(0xFF2196F3))),
            ],
          ),
          const SizedBox(height: 16),

          // Stats Row 2
          Row(
            children: [
              Expanded(
                  child: _buildMoneyCard('Monthly Spending', '\$45,231',
                      '+13.2% from last month', const Color(0xFF2196F3))),
              const SizedBox(width: 16),
              Expanded(
                  child: _buildAlertCard('Pending Approvals', '8',
                      'Requires attetention', Colors.orange)),
              const SizedBox(width: 16),
              Expanded(
                  child: _buildSuccessCard('Completed Today', '12',
                      'Great progress!', Colors.green)),
            ],
          ),
          const SizedBox(height: 24),

          // Bottom Section
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 5, child: _buildRecentActivity()),
              const SizedBox(width: 16),
              Expanded(flex: 4, child: _buildPendingApprovals()),
            ],
          )
        ],
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
                child: Text(title,
                    style: const TextStyle(color: Colors.white, fontSize: 14)),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSideMenuItemWithBadge(BuildContext context, IconData icon,
      String title, VoidCallback onTap, int count,
      {Color badgeColor = Colors.red}) {
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
                        constraints:
                            const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          count.toString(),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(title,
                      style:
                          const TextStyle(color: Colors.white, fontSize: 14))),
            ],
          ),
        ),
      ),
    );
  }

  // Stat Card
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color.withOpacity(0.7), size: 32),
          const SizedBox(height: 12),
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          const SizedBox(height: 4),
          Text(value,
              style:
                  const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildMoneyCard(
      String label, String value, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(value,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(width: 12),
              Icon(Icons.monetization_on,
                  color: color.withOpacity(0.5), size: 32),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.arrow_upward, color: Colors.green, size: 14),
              const SizedBox(width: 4),
              Text(subtitle,
                  style: const TextStyle(color: Colors.green, fontSize: 12)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildAlertCard(
      String label, String value, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(value,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(width: 12),
              Icon(Icons.check_circle, color: color.withOpacity(0.5), size: 32),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.check, color: color, size: 14),
              const SizedBox(width: 4),
              Text(subtitle, style: TextStyle(color: color, fontSize: 12)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSuccessCard(
      String label, String value, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(value,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(width: 12),
              Icon(Icons.check_circle, color: color.withOpacity(0.5), size: 32),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.check, color: color, size: 14),
              const SizedBox(width: 4),
              Text(subtitle, style: TextStyle(color: color, fontSize: 12)),
            ],
          )
        ],
      ),
    );
  }

  // Recent Activity widget
  Widget _buildRecentActivity() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.access_time, size: 18, color: Colors.blue[700]),
              const SizedBox(width: 8),
              const Text('Recent Activity',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          _buildActivityItem(Icons.check_circle, Colors.green,
              'Purchase Order #PO-2024-001 approved', '2 hours ago'),
          _buildActivityItem(Icons.description, Colors.blue,
              'New Purchase Requisition #PR-2024-045', '4 hours ago'),
          _buildActivityItem(Icons.inventory, Colors.blue,
              'Inventory updated for Item #ITM-890', '6 hours ago'),
          _buildActivityItem(Icons.check_circle, Colors.green,
              'Payment processed for Supplier XYZ', '1 day ago'),
          _buildActivityItem(Icons.warning, Colors.red,
              'Pending approval for PR-2024-044', '1 day ago',
              isLast: true),
        ],
      ),
    );
  }

  Widget _buildActivityItem(
      IconData icon, Color color, String time, String title,
      {bool isLast = false}) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500)),
                  Text(time,
                      style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                ],
              ),
            ),
          ],
        ),
        if (!isLast) ...[
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
        ]
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
              offset: const Offset(0, 2))
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, size: 18, color: Colors.red[700]),
              const SizedBox(width: 8),
              const Text('Pending Approvals',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          _buildApprovalItem(
              'PR-2024-044', 'IT Department', '\$12,500', 'High', Colors.red),
          const SizedBox(height: 12),
          _buildApprovalItem(
              'PO-2024-023', 'Operations', '\$8,200', 'Medium', Colors.orange),
          const SizedBox(height: 12),
          _buildApprovalItem(
              'PR-2024-043', 'Marketing', '\$5,400', 'Low', Colors.grey,
              isLast: true),
        ],
      ),
    );
  }

  Widget _buildApprovalItem(String id, String department, String amount,
      String priority, Color priorityColor,
      {bool isLast = false}) {
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
                      Text(id,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: priorityColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(priority,
                            style: TextStyle(
                                color: priorityColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(department,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(amount,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  Align(
                    alignment: AlignmentGeometry.centerRight,
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
                          Text('Review',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.blue[700])),
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_forward,
                              size: 14, color: Colors.blue[700]),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            )
          ],
        )
      ],
    );
  }
}
