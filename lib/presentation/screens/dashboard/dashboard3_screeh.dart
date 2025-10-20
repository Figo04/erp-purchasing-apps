// import 'package:erp_purchasing_apps/data/providers/asset_provider.dart';
// import 'package:erp_purchasing_apps/data/providers/inventory_provider.dart';
// import 'package:erp_purchasing_apps/data/providers/payment_provider.dart';
// import 'package:erp_purchasing_apps/data/providers/pr_provider.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:erp_purchasing_apps/data/providers/auth_providers.dart';
// import 'package:go_router/go_router.dart';

// class DashboardScreen3 extends ConsumerWidget {
//   const DashboardScreen3({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final currentUser = ref.watch(currentUserProvider);
//     final pendingCount = ref.watch(pendingPRCountProvider);
//     final lowStockCount = ref.watch(lowStockCountProvider);
//     final borrowedAssetsCount = ref.watch(borrowedAssetsCountProvider);
//     final overduePaymentsCount = ref.watch(overduePaymentsCountProvider);

//     // Responsive check
//     final isDesktop = MediaQuery.of(context).size.width > 900;

//     if (isDesktop) {
//       return _buildDesktopLayout(
//         context,
//         ref,
//         currentUser,
//         pendingCount,
//         lowStockCount,
//         borrowedAssetsCount,
//         overduePaymentsCount,
//       );
//     } else {
//       return _buildMobileLayout(
//         context,
//         ref,
//         currentUser,
//         pendingCount,
//         lowStockCount,
//         borrowedAssetsCount,
//         overduePaymentsCount,
//       );
//     }
//   }

//   // Desktop Layout dengan Sidebar
//   Widget _buildDesktopLayout(
//     BuildContext context,
//     WidgetRef ref,
//     dynamic currentUser,
//     int pendingCount,
//     int lowStockCount,
//     int borrowedAssetsCount,
//     int overduePaymentsCount,
//   ) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F7FA),
//       body: Row(
//         children: [
//           // Sidebar
//           Container(
//             width: 250,
//             color: const Color(0xFF1ABC9C),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // User Profile
//                 Container(
//                   padding: const EdgeInsets.all(20),
//                   child: Row(
//                     children: [
//                       CircleAvatar(
//                         backgroundColor: Colors.white.withOpacity(0.3),
//                         child: Text(
//                           currentUser?.username.substring(0, 1).toUpperCase() ??
//                               'U',
//                           style: const TextStyle(
//                             color: Colors.white,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               currentUser?.fullName ?? 'User',
//                               style: const TextStyle(
//                                 color: Colors.white,
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 14,
//                               ),
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                             Text(
//                               currentUser?.email ?? '',
//                               style: const TextStyle(
//                                 color: Colors.white70,
//                                 fontSize: 11,
//                               ),
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 const Divider(color: Colors.white24, height: 1),
//                 // Menu Items
//                 Expanded(
//                   child: ListView(
//                     padding: const EdgeInsets.symmetric(vertical: 8),
//                     children: [
//                       _buildSideMenuItem(
//                         context,
//                         Icons.dashboard,
//                         'Dashboard',
//                         () => context.go('/'),
//                         isActive: true,
//                       ),
//                       _buildSideMenuItem(
//                         context,
//                         Icons.people,
//                         'User Management',
//                         () => context.go('/users'),
//                       ),
//                       _buildSideMenuItemWithBadge(
//                         context,
//                         Icons.request_page,
//                         'Purchase Requisition',
//                         () => context.go('/pr'),
//                         pendingCount,
//                       ),
//                       _buildSideMenuItem(
//                         context,
//                         Icons.shopping_cart,
//                         'Purchase Order',
//                         () => context.go('/po'),
//                       ),
//                       _buildSideMenuItemWithBadge(
//                         context,
//                         Icons.inventory,
//                         'Inventory',
//                         () => context.go('/inventory'),
//                         lowStockCount,
//                       ),
//                       _buildSideMenuItemWithBadge(
//                         context,
//                         Icons.assessment,
//                         'Asset',
//                         () => context.go('/asset'),
//                         borrowedAssetsCount,
//                         badgeColor: Colors.orange,
//                       ),
//                       _buildSideMenuItemWithBadge(
//                         context,
//                         Icons.payment,
//                         'Payment',
//                         () => context.go('/payment'),
//                         overduePaymentsCount,
//                       ),
//                       _buildSideMenuItem(
//                         context,
//                         Icons.business,
//                         'Suppliers',
//                         () => context.go('/suppliers'),
//                       ),
//                       _buildSideMenuItem(
//                         context,
//                         Icons.history,
//                         'PR History',
//                         () => context.go('/pr-history'),
//                       ),
//                       if (currentUser?.role == 'admin' ||
//                           currentUser?.role == 'purchasing')
//                         _buildSideMenuItem(
//                           context,
//                           Icons.approval,
//                           'PR Approval',
//                           () => context.go('/pr-approval'),
//                         ),
//                       _buildSideMenuItem(
//                         context,
//                         Icons.check_circle,
//                         'PO Approval',
//                         () => context.go('/po-approval'),
//                       ),
//                       if (currentUser?.role == 'admin' ||
//                           currentUser?.role == 'warehouse')
//                         _buildSideMenuItem(
//                           context,
//                           Icons.local_shipping,
//                           'Receipt',
//                           () => context.go('/receipt'),
//                         ),
//                     ],
//                   ),
//                 ),
//                 // Logout Button
//                 Container(
//                   padding: const EdgeInsets.all(8),
//                   child: _buildSideMenuItem(
//                     context,
//                     Icons.logout,
//                     'Logout',
//                     () async {
//                       await ref.read(authStateProvider.notifier).signOut();
//                     },
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           // Main Content
//           Expanded(
//             child: Column(
//               children: [
//                 // Header
//                 Container(
//                   height: 60,
//                   color: Colors.white,
//                   padding: const EdgeInsets.symmetric(horizontal: 24),
//                   child: Row(
//                     children: [
//                       const Icon(Icons.menu_open, color: Colors.grey),
//                       const SizedBox(width: 16),
//                       const Text(
//                         'ERP System',
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                       const Spacer(),
//                       IconButton(
//                         icon: const Icon(Icons.notifications_outlined),
//                         onPressed: () {},
//                       ),
//                       const SizedBox(width: 8),
//                       IconButton(
//                         icon: const Icon(Icons.logout),
//                         onPressed: () async {
//                           await ref.read(authStateProvider.notifier).signOut();
//                         },
//                       ),
//                     ],
//                   ),
//                 ),
//                 // Dashboard Content
//                 Expanded(
//                   child: _buildDashboardContent(
//                     context,
//                     currentUser,
//                     pendingCount,
//                     lowStockCount,
//                     borrowedAssetsCount,
//                     overduePaymentsCount,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // Mobile Layout dengan Drawer
//   Widget _buildMobileLayout(
//     BuildContext context,
//     WidgetRef ref,
//     dynamic currentUser,
//     int pendingCount,
//     int lowStockCount,
//     int borrowedAssetsCount,
//     int overduePaymentsCount,
//   ) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F7FA),
//       appBar: AppBar(
//         title: const Text('Dashboard'),
//         backgroundColor: const Color(0xFF1ABC9C),
//         foregroundColor: Colors.white,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.notifications_outlined),
//             onPressed: () {},
//           ),
//           IconButton(
//             icon: const Icon(Icons.logout),
//             onPressed: () async {
//               await ref.read(authStateProvider.notifier).signOut();
//             },
//           ),
//         ],
//       ),
//       drawer: _buildDrawer(
//         context,
//         ref,
//         currentUser,
//         pendingCount,
//         lowStockCount,
//         borrowedAssetsCount,
//         overduePaymentsCount,
//       ),
//       body: _buildDashboardContent(
//         context,
//         currentUser,
//         pendingCount,
//         lowStockCount,
//         borrowedAssetsCount,
//         overduePaymentsCount,
//       ),
//     );
//   }

//   Widget _buildDrawer(
//     BuildContext context,
//     WidgetRef ref,
//     dynamic currentUser,
//     int pendingCount,
//     int lowStockCount,
//     int borrowedAssetsCount,
//     int overduePaymentsCount,
//   ) {
//     return Drawer(
//       child: Container(
//         color: const Color(0xFF1ABC9C),
//         child: ListView(
//           padding: EdgeInsets.zero,
//           children: [
//             DrawerHeader(
//               decoration: BoxDecoration(
//                 color: const Color(0xFF1ABC9C).withOpacity(0.8),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   CircleAvatar(
//                     backgroundColor: Colors.white.withOpacity(0.3),
//                     radius: 30,
//                     child: Text(
//                       currentUser?.username.substring(0, 1).toUpperCase() ??
//                           'U',
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontWeight: FontWeight.bold,
//                         fontSize: 24,
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 12),
//                   Text(
//                     currentUser?.fullName ?? 'User',
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontWeight: FontWeight.bold,
//                       fontSize: 16,
//                     ),
//                   ),
//                   Text(
//                     currentUser?.email ?? '',
//                     style: const TextStyle(
//                       color: Colors.white70,
//                       fontSize: 12,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             _buildDrawerMenuItem(
//               context,
//               Icons.dashboard,
//               'Dashboard',
//               () {
//                 Navigator.pop(context);
//                 context.go('/');
//               },
//             ),
//             _buildDrawerMenuItem(
//               context,
//               Icons.people,
//               'User Management',
//               () {
//                 Navigator.pop(context);
//                 context.go('/users');
//               },
//             ),
//             _buildDrawerMenuItemWithBadge(
//               context,
//               Icons.request_page,
//               'Purchase Requisition',
//               () {
//                 Navigator.pop(context);
//                 context.go('/pr');
//               },
//               pendingCount,
//             ),
//             _buildDrawerMenuItem(
//               context,
//               Icons.shopping_cart,
//               'Purchase Order',
//               () {
//                 Navigator.pop(context);
//                 context.go('/po');
//               },
//             ),
//             _buildDrawerMenuItemWithBadge(
//               context,
//               Icons.inventory,
//               'Inventory',
//               () {
//                 Navigator.pop(context);
//                 context.go('/inventory');
//               },
//               lowStockCount,
//             ),
//             _buildDrawerMenuItemWithBadge(
//               context,
//               Icons.assessment,
//               'Asset',
//               () {
//                 Navigator.pop(context);
//                 context.go('/asset');
//               },
//               borrowedAssetsCount,
//               badgeColor: Colors.orange,
//             ),
//             _buildDrawerMenuItemWithBadge(
//               context,
//               Icons.payment,
//               'Payment',
//               () {
//                 Navigator.pop(context);
//                 context.go('/payment');
//               },
//               overduePaymentsCount,
//             ),
//             _buildDrawerMenuItem(
//               context,
//               Icons.business,
//               'Suppliers',
//               () {
//                 Navigator.pop(context);
//                 context.go('/suppliers');
//               },
//             ),
//             _buildDrawerMenuItem(
//               context,
//               Icons.history,
//               'PR History',
//               () {
//                 Navigator.pop(context);
//                 context.go('/pr-history');
//               },
//             ),
//             if (currentUser?.role == 'admin' ||
//                 currentUser?.role == 'purchasing')
//               _buildDrawerMenuItem(
//                 context,
//                 Icons.approval,
//                 'PR Approval',
//                 () {
//                   Navigator.pop(context);
//                   context.go('/pr-approval');
//                 },
//               ),
//             _buildDrawerMenuItem(
//               context,
//               Icons.check_circle,
//               'PO Approval',
//               () {
//                 Navigator.pop(context);
//                 context.go('/po-approval');
//               },
//             ),
//             if (currentUser?.role == 'admin' ||
//                 currentUser?.role == 'warehouse')
//               _buildDrawerMenuItem(
//                 context,
//                 Icons.local_shipping,
//                 'Receipt',
//                 () {
//                   Navigator.pop(context);
//                   context.go('/receipt');
//                 },
//               ),
//             const Divider(color: Colors.white24),
//             _buildDrawerMenuItem(
//               context,
//               Icons.logout,
//               'Logout',
//               () async {
//                 await ref.read(authStateProvider.notifier).signOut();
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildDashboardContent(
//     BuildContext context,
//     dynamic currentUser,
//     int pendingCount,
//     int lowStockCount,
//     int borrowedAssetsCount,
//     int overduePaymentsCount,
//   ) {
//     final isDesktop = MediaQuery.of(context).size.width > 900;

//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(24),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Welcome Text
//           Text(
//             'Welcome Back, ${currentUser?.fullName ?? 'User'}!',
//             style: const TextStyle(
//               fontSize: 28,
//               fontWeight: FontWeight.bold,
//               color: Color(0xFF2196F3),
//             ),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             "Here's what's happening with your ERP system today",
//             style: TextStyle(
//               fontSize: 14,
//               color: Colors.grey[600],
//             ),
//           ),
//           const SizedBox(height: 8),
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//             decoration: BoxDecoration(
//               color: const Color(0xFF1ABC9C).withOpacity(0.1),
//               borderRadius: BorderRadius.circular(20),
//             ),
//             child: Text(
//               'Role: ${currentUser?.role.toUpperCase()}',
//               style: const TextStyle(
//                 fontSize: 12,
//                 fontWeight: FontWeight.w600,
//                 color: Color(0xFF1ABC9C),
//               ),
//             ),
//           ),
//           const SizedBox(height: 24),
//           // Stats Cards Row 1
//           LayoutBuilder(
//             builder: (context, constraints) {
//               if (isDesktop) {
//                 return Row(
//                   children: [
//                     Expanded(
//                       child: _buildStatCard(
//                         'Total PR',
//                         pendingCount.toString(),
//                         Icons.description,
//                         const Color(0xFF2196F3),
//                         () => context.go('/pr'),
//                       ),
//                     ),
//                     const SizedBox(width: 16),
//                     Expanded(
//                       child: _buildStatCard(
//                         'Total PO',
//                         '0',
//                         Icons.shopping_cart,
//                         const Color(0xFF4CAF50),
//                         () => context.go('/po'),
//                       ),
//                     ),
//                     const SizedBox(width: 16),
//                     Expanded(
//                       child: _buildStatCard(
//                         'Inventory Items',
//                         lowStockCount.toString(),
//                         Icons.inventory_2,
//                         const Color(0xFF9C27B0),
//                         () => context.go('/inventory'),
//                       ),
//                     ),
//                     const SizedBox(width: 16),
//                     Expanded(
//                       child: _buildStatCard(
//                         'Active Users',
//                         '0',
//                         Icons.people,
//                         const Color(0xFF2196F3),
//                         () => context.go('/users'),
//                       ),
//                     ),
//                   ],
//                 );
//               } else {
//                 return Column(
//                   children: [
//                     Row(
//                       children: [
//                         Expanded(
//                           child: _buildStatCard(
//                             'Total PR',
//                             pendingCount.toString(),
//                             Icons.description,
//                             const Color(0xFF2196F3),
//                             () => context.go('/pr'),
//                           ),
//                         ),
//                         const SizedBox(width: 12),
//                         Expanded(
//                           child: _buildStatCard(
//                             'Total PO',
//                             '0',
//                             Icons.shopping_cart,
//                             const Color(0xFF4CAF50),
//                             () => context.go('/po'),
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 12),
//                     Row(
//                       children: [
//                         Expanded(
//                           child: _buildStatCard(
//                             'Inventory',
//                             lowStockCount.toString(),
//                             Icons.inventory_2,
//                             const Color(0xFF9C27B0),
//                             () => context.go('/inventory'),
//                           ),
//                         ),
//                         const SizedBox(width: 12),
//                         Expanded(
//                           child: _buildStatCard(
//                             'Users',
//                             '0',
//                             Icons.people,
//                             const Color(0xFF2196F3),
//                             () => context.go('/users'),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 );
//               }
//             },
//           ),
//           const SizedBox(height: 16),
//           // Stats Cards Row 2
//           LayoutBuilder(
//             builder: (context, constraints) {
//               if (isDesktop) {
//                 return Row(
//                   children: [
//                     Expanded(
//                       child: _buildInfoCard(
//                         'Pending Approvals',
//                         pendingCount.toString(),
//                         'Requires attention',
//                         Icons.access_time,
//                         Colors.orange,
//                         isWarning: true,
//                       ),
//                     ),
//                     const SizedBox(width: 16),
//                     Expanded(
//                       child: _buildInfoCard(
//                         'Low Stock Items',
//                         lowStockCount.toString(),
//                         'Need reorder',
//                         Icons.warning,
//                         Colors.red,
//                         isWarning: true,
//                       ),
//                     ),
//                     const SizedBox(width: 16),
//                     Expanded(
//                       child: _buildInfoCard(
//                         'Borrowed Assets',
//                         borrowedAssetsCount.toString(),
//                         'Currently in use',
//                         Icons.assignment,
//                         Colors.blue,
//                       ),
//                     ),
//                     const SizedBox(width: 16),
//                     Expanded(
//                       child: _buildInfoCard(
//                         'Overdue Payments',
//                         overduePaymentsCount.toString(),
//                         overduePaymentsCount > 0
//                             ? 'Action required'
//                             : 'All clear',
//                         Icons.payment,
//                         overduePaymentsCount > 0 ? Colors.red : Colors.green,
//                         isWarning: overduePaymentsCount > 0,
//                       ),
//                     ),
//                   ],
//                 );
//               } else {
//                 return Column(
//                   children: [
//                     _buildInfoCard(
//                       'Pending Approvals',
//                       pendingCount.toString(),
//                       'Requires attention',
//                       Icons.access_time,
//                       Colors.orange,
//                       isWarning: true,
//                     ),
//                     const SizedBox(height: 12),
//                     _buildInfoCard(
//                       'Low Stock Items',
//                       lowStockCount.toString(),
//                       'Need reorder',
//                       Icons.warning,
//                       Colors.red,
//                       isWarning: true,
//                     ),
//                     const SizedBox(height: 12),
//                     _buildInfoCard(
//                       'Borrowed Assets',
//                       borrowedAssetsCount.toString(),
//                       'Currently in use',
//                       Icons.assignment,
//                       Colors.blue,
//                     ),
//                     const SizedBox(height: 12),
//                     _buildInfoCard(
//                       'Overdue Payments',
//                       overduePaymentsCount.toString(),
//                       overduePaymentsCount > 0
//                           ? 'Action required'
//                           : 'All clear',
//                       Icons.payment,
//                       overduePaymentsCount > 0 ? Colors.red : Colors.green,
//                       isWarning: overduePaymentsCount > 0,
//                     ),
//                   ],
//                 );
//               }
//             },
//           ),
//           const SizedBox(height: 24),
//           // Quick Actions
//           Container(
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(8),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.05),
//                   blurRadius: 10,
//                   offset: const Offset(0, 2),
//                 ),
//               ],
//             ),
//             padding: const EdgeInsets.all(20),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     Icon(
//                       Icons.bolt,
//                       size: 18,
//                       color: Colors.blue[700],
//                     ),
//                     const SizedBox(width: 8),
//                     const Text(
//                       'Quick Actions',
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 16),
//                 Wrap(
//                   spacing: 12,
//                   runSpacing: 12,
//                   children: [
//                     _buildQuickActionButton(
//                       context,
//                       'New PR',
//                       Icons.add_circle,
//                       Colors.blue,
//                       () => context.go('/pr'),
//                     ),
//                     _buildQuickActionButton(
//                       context,
//                       'New PO',
//                       Icons.shopping_bag,
//                       Colors.green,
//                       () => context.go('/po'),
//                     ),
//                     _buildQuickActionButton(
//                       context,
//                       'Check Inventory',
//                       Icons.search,
//                       Colors.purple,
//                       () => context.go('/inventory'),
//                     ),
//                     _buildQuickActionButton(
//                       context,
//                       'View Payments',
//                       Icons.receipt,
//                       Colors.orange,
//                       () => context.go('/payment'),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // Sidebar Menu Item
//   Widget _buildSideMenuItem(
//     BuildContext context,
//     IconData icon,
//     String title,
//     VoidCallback onTap, {
//     bool isActive = false,
//   }) {
//     return Material(
//       color: Colors.transparent,
//       child: InkWell(
//         onTap: onTap,
//         child: Container(
//           padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//           decoration: BoxDecoration(
//             color: isActive ? Colors.white.withOpacity(0.15) : null,
//             borderRadius: BorderRadius.circular(4),
//           ),
//           margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//           child: Row(
//             children: [
//               Icon(icon, color: Colors.white, size: 20),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Text(
//                   title,
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 14,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildSideMenuItemWithBadge(
//     BuildContext context,
//     IconData icon,
//     String title,
//     VoidCallback onTap,
//     int count, {
//     Color badgeColor = Colors.red,
//   }) {
//     return Material(
//       color: Colors.transparent,
//       child: InkWell(
//         onTap: onTap,
//         child: Container(
//           padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//           margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//           child: Row(
//             children: [
//               Stack(
//                 clipBehavior: Clip.none,
//                 children: [
//                   Icon(icon, color: Colors.white, size: 20),
//                   if (count > 0)
//                     Positioned(
//                       right: -8,
//                       top: -6,
//                       child: Container(
//                         padding: const EdgeInsets.all(4),
//                         decoration: BoxDecoration(
//                           color: badgeColor,
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                         constraints: const BoxConstraints(
//                           minWidth: 16,
//                           minHeight: 16,
//                         ),
//                         child: Text(
//                           count.toString(),
//                           style: const TextStyle(
//                             color: Colors.white,
//                             fontSize: 9,
//                             fontWeight: FontWeight.bold,
//                           ),
//                           textAlign: TextAlign.center,
//                         ),
//                       ),
//                     ),
//                 ],
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Text(
//                   title,
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 14,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   // Drawer Menu Items
//   Widget _buildDrawerMenuItem(
//     BuildContext context,
//     IconData icon,
//     String title,
//     VoidCallback onTap,
//   ) {
//     return ListTile(
//       leading: Icon(icon, color: Colors.white),
//       title: Text(
//         title,
//         style: const TextStyle(color: Colors.white),
//       ),
//       onTap: onTap,
//     );
//   }

//   Widget _buildDrawerMenuItemWithBadge(
//     BuildContext context,
//     IconData icon,
//     String title,
//     VoidCallback onTap,
//     int count, {
//     Color badgeColor = Colors.red,
//   }) {
//     return ListTile(
//       leading: Stack(
//         clipBehavior: Clip.none,
//         children: [
//           Icon(icon, color: Colors.white),
//           if (count > 0)
//             Positioned(
//               right: -8,
//               top: -4,
//               child: Container(
//                 padding: const EdgeInsets.all(4),
//                 decoration: BoxDecoration(
//                   color: badgeColor,
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 constraints: const BoxConstraints(
//                   minWidth: 16,
//                   minHeight: 16,
//                 ),
//                 child: Text(
//                   count.toString(),
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 10,
//                     fontWeight: FontWeight.bold,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//               ),
//             ),
//         ],
//       ),
//       title: Text(
//         title,
//         style: const TextStyle(color: Colors.white),
//       ),
//       onTap: onTap,
//     );
//   }

//   // Stat Card with Click
//   Widget _buildStatCard(
//     String label,
//     String value,
//     IconData icon,
//     Color color,
//     VoidCallback onTap,
//   ) {
//     return InkWell(
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.all(20),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(8),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.05),
//               blurRadius: 10,
//               offset: const Offset(0, 2),
//             ),
//           ],
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Icon(icon, color: color.withOpacity(0.7), size: 32),
//             const SizedBox(height: 12),
//             Text(
//               label,
//               style: TextStyle(
//                 color: Colors.grey[600],
//                 fontSize: 13,
//               ),
//             ),
//             const SizedBox(height: 4),
//             Text(
//               value,
//               style: const TextStyle(
//                 fontSize: 28,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // Info Card
//   Widget _buildInfoCard(
//     String label,
//     String value,
//     String subtitle,
//     IconData icon,
//     Color color, {
//     bool isWarning = false,
//   }) {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(8),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             label,
//             style: TextStyle(
//               color: Colors.grey[600],
//               fontSize: 13,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Row(
//             children: [
//               Text(
//                 value,
//                 style: const TextStyle(
//                   fontSize: 24,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Icon(
//                 icon,
//                 color: color.withOpacity(0.5),
//                 size: 32,
//               ),
//             ],
//           ),
//           const SizedBox(height: 8),
//           Row(
//             children: [
//               Icon(
//                 isWarning ? Icons.warning : Icons.check,
//                 color: color,
//                 size: 14,
//               ),
//               const SizedBox(width: 4),
//               Expanded(
//                 child: Text(
//                   subtitle,
//                   style: TextStyle(
//                     color: color,
//                     fontSize: 12,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   // Quick Action Button
//   Widget _buildQuickActionButton(
//     BuildContext context,
//     String label,
//     IconData icon,
//     Color color,
//     VoidCallback onTap,
//   ) {
//     return ElevatedButton.icon(
//       onPressed: onTap,
//       icon: Icon(icon, size: 18),
//       label: Text(label),
//       style: ElevatedButton.styleFrom(
//         backgroundColor: color,
//         foregroundColor: Colors.white,
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(8),
//         ),
//         elevation: 2,
//       ),
//     );
//   }
// }
