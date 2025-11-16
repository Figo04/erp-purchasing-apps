// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:go_router/go_router.dart';
// import 'package:erp_purchasing_apps/data/models/payment_model.dart';
// import 'package:erp_purchasing_apps/data/providers/payment_provider.dart';
// import 'package:erp_purchasing_apps/data/providers/auth_providers.dart';
// import 'package:erp_purchasing_apps/presentation/screens/payment/payment_form_screen.dart';
// import 'package:erp_purchasing_apps/presentation/screens/payment/payment_detail_screen.dart';
// import 'package:intl/intl.dart';

// class PaymentListScreen extends ConsumerStatefulWidget {
//   const PaymentListScreen({super.key});

//   @override
//   ConsumerState<PaymentListScreen> createState() => _PaymentListScreenState();
// }

// class _PaymentListScreenState extends ConsumerState<PaymentListScreen> {
//   String _filterStatus = 'all';
//   String _searchQuery = '';
//   final _searchController = TextEditingController();

//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }

//   Color _getStatusColor(String status) {
//     switch (status) {
//       case 'pending':
//         return Colors.orange;
//       case 'scheduled':
//         return Colors.blue;
//       case 'paid':
//         return Colors.green;
//       case 'failed':
//         return Colors.red;
//       case 'cancelled':
//         return Colors.grey;
//       default:
//         return Colors.grey;
//     }
//   }

//   IconData _getStatusIcon(String status) {
//     switch (status) {
//       case 'pending':
//         return Icons.schedule;
//       case 'scheduled':
//         return Icons.event;
//       case 'paid':
//         return Icons.check_circle;
//       case 'failed':
//         return Icons.error;
//       case 'cancelled':
//         return Icons.cancel;
//       default:
//         return Icons.help;
//     }
//   }

//   bool _isOverdue(PaymentModel payment) {
//     if (payment.dueDate == null) return false;
//     return payment.dueDate!.isBefore(DateTime.now()) &&
//         (payment.status == 'pending' || payment.status == 'scheduled');
//   }

//   @override
//   Widget build(BuildContext context) {
//     final paymentStream = ref.watch(paymentStreamProvider);
//     final currentUser = ref.watch(currentUserProvider);
//     final canManage =
//         currentUser?.role == 'admin' || currentUser?.role == 'finance';
//     final overdueCount = ref.watch(overduePaymentsCountProvider);

//     return Scaffold(
//       appBar: AppBar(
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: () => context.go('/dashboard'),
//         ),
//         title: const Text('Payment Management'),
//         actions: [
//           if (overdueCount > 0)
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 8),
//               child: Center(
//                 child: Chip(
//                   label: Text(
//                     'Overdue: $overdueCount',
//                     style: const TextStyle(fontSize: 12, color: Colors.white),
//                   ),
//                   backgroundColor: Colors.red,
//                 ),
//               ),
//             ),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 8),
//             child: Center(
//               child: paymentStream.when(
//                 data: (_) => const Icon(Icons.cloud_done, color: Colors.green),
//                 loading: () => const SizedBox(
//                   width: 20,
//                   height: 20,
//                   child: CircularProgressIndicator(strokeWidth: 2),
//                 ),
//                 error: (_, __) =>
//                     const Icon(Icons.cloud_off, color: Colors.red),
//               ),
//             ),
//           ),
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: () {
//               ref.invalidate(paymentStreamProvider);
//             },
//           )
//         ],
//       ),
//       body: Column(
//         children: [
//           // overdue Allert Banner
//           if (overdueCount > 0)
//             Container(
//               width: double.infinity,
//               color: Colors.red.shade50,
//               padding: const EdgeInsets.all(12),
//               child: Row(
//                 children: [
//                   const Icon(Icons.warning, color: Colors.red),
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: Text(
//                       '$overdueCount payment${overdueCount > 1 ? 's' : ''} overdue!',
//                       style: const TextStyle(
//                         color: Colors.red,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   )
//                 ],
//               ),
//             ),

//           // Search Bar
//           Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: TextField(
//               controller: _searchController,
//               decoration: InputDecoration(
//                 hintText: 'Search payment number or PO...',
//                 prefixIcon: const Icon(Icons.search),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 suffixIcon: _searchQuery.isNotEmpty
//                     ? IconButton(
//                         icon: const Icon(Icons.clear),
//                         onPressed: () {
//                           setState(() {
//                             _searchController.clear();
//                             _searchQuery = '';
//                           });
//                         },
//                       )
//                     : null,
//               ),
//               onChanged: (value) {
//                 setState(() {
//                   _searchQuery = value.toLowerCase();
//                 });
//               },
//             ),
//           ),

//           // Status Filter
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 16),
//             child: SingleChildScrollView(
//               scrollDirection: Axis.horizontal,
//               child: paymentStream.when(
//                 data: (payments) {
//                   final pendingCount =
//                       payments.where((p) => p.status == 'pending').length;
//                   final scheduledCount =
//                       payments.where((p) => p.status == 'scheduled').length;
//                   final paidCount =
//                       payments.where((p) => p.status == 'paid').length;
//                   final failedCount =
//                       payments.where((p) => p.status == 'failed').length;
//                   final cancelledCount =
//                       payments.where((p) => p.status == 'cancelled').length;

//                   return Row(
//                     children: [
//                       _buildFilterChip('all', 'All', payments.length),
//                       const SizedBox(width: 8),
//                       _buildFilterChip('pending', 'Pending', pendingCount),
//                       const SizedBox(width: 8),
//                       _buildFilterChip(
//                           'scheduled', 'Scheduled', scheduledCount),
//                       const SizedBox(width: 8),
//                       _buildFilterChip('paid', 'Paid', paidCount),
//                       const SizedBox(width: 8),
//                       _buildFilterChip('failed', 'Failed', failedCount),
//                       const SizedBox(width: 8),
//                       _buildFilterChip(
//                           'cancelled', 'Cancelled', cancelledCount),
//                     ],
//                   );
//                 },
//                 loading: () => const SizedBox.shrink(),
//                 error: (_, __) => const SizedBox.shrink(),
//               ),
//             ),
//           ),
//           const SizedBox(height: 8),

//           //Payment List
//           Expanded(
//             child: paymentStream.when(
//               data: (payments) {
//                 var filteredPayments = payments;

//                 // Filter by status
//                 if (_filterStatus != 'all') {
//                   filteredPayments = filteredPayments
//                       .where((payment) => payment.status == _filterStatus)
//                       .toList();
//                 }

//                 if (_searchQuery.isNotEmpty) {
//                   filteredPayments = filteredPayments.where((payment) {
//                     return payment.paymentNumber
//                             .toLowerCase()
//                             .contains(_searchQuery) ||
//                         (payment.poNumber
//                                 ?.toLowerCase()
//                                 .contains(_searchQuery) ??
//                             false) ||
//                         (payment.supplierName
//                                 ?.toLowerCase()
//                                 .contains(_searchQuery) ??
//                             false) ||
//                         // 🆕 NEW: Also search by receipt number
//                         (payment.receiptNumber
//                                 ?.toLowerCase()
//                                 .contains(_searchQuery) ??
//                             false);
//                   }).toList();
//                 }

//                 if (filteredPayments.isEmpty) {
//                   return const Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(Icons.payment, size: 64, color: Colors.grey),
//                         SizedBox(height: 16),
//                         Text(
//                           'No payments found',
//                           style: TextStyle(fontSize: 16, color: Colors.grey),
//                         )
//                       ],
//                     ),
//                   );
//                 }

//                 return ListView.builder(
//                   itemCount: filteredPayments.length,
//                   padding: const EdgeInsets.all(16),
//                   itemBuilder: (context, index) {
//                     final payment = filteredPayments[index];
//                     final isOverdue = _isOverdue(payment);

//                     return Card(
//                       margin: const EdgeInsets.only(bottom: 8),
//                       color: isOverdue ? Colors.red.shade50 : null,
//                       child: ListTile(
//                         leading: CircleAvatar(
//                           backgroundColor: _getStatusColor(payment.status),
//                           child: Icon(
//                             _getStatusIcon(payment.status),
//                             color: Colors.white,
//                           ),
//                         ),
//                         title: Row(
//                           children: [
//                             Expanded(
//                               child: Text(
//                                 payment.paymentNumber,
//                                 style: const TextStyle(
//                                     fontWeight: FontWeight.bold),
//                               ),
//                             ),
//                             if (isOverdue)
//                               Container(
//                                 padding: const EdgeInsets.symmetric(
//                                   horizontal: 8,
//                                   vertical: 2,
//                                 ),
//                                 decoration: BoxDecoration(
//                                   color: Colors.red,
//                                   borderRadius: BorderRadius.circular(12),
//                                 ),
//                                 child: const Text(
//                                   'OVERDUE',
//                                   style: TextStyle(
//                                     color: Colors.white,
//                                     fontSize: 10,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                               ),
//                           ],
//                         ),
//                         subtitle: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             // 🆕 NEW: Show Receipt Number first (if exists)
//                             if (payment.receiptNumber != null)
//                               Row(
//                                 children: [
//                                   Icon(Icons.inventory_2,
//                                       size: 14, color: Colors.green.shade700),
//                                   const SizedBox(width: 4),
//                                   Expanded(
//                                     child: Text(
//                                       'LPB: ${payment.receiptNumber}',
//                                       style: TextStyle(
//                                         fontWeight: FontWeight.w600,
//                                         color: Colors.green.shade700,
//                                       ),
//                                     ),
//                                   ),
//                                 ],
//                               ),

//                             // Existing PO Number
//                             if (payment.poNumber != null)
//                               Text('PO: ${payment.poNumber}'),

//                             // Existing Supplier Name
//                             if (payment.supplierName != null)
//                               Text('Supplier: ${payment.supplierName}'),

//                             // Existing Amount
//                             Text(
//                               'Amount: Rp ${NumberFormat('#,###').format(payment.amount)}',
//                               style: const TextStyle(
//                                   fontWeight: FontWeight.w600,
//                                   color: Colors.blue),
//                             ),

//                             // Existing Due Date
//                             if (payment.dueDate != null)
//                               Text(
//                                 'Due: ${DateFormat('dd MMM yyyy').format(payment.dueDate!)}',
//                                 style: TextStyle(
//                                   fontSize: 12,
//                                   color: isOverdue ? Colors.red : Colors.grey,
//                                   fontWeight: isOverdue
//                                       ? FontWeight.bold
//                                       : FontWeight.normal,
//                                 ),
//                               )
//                           ],
//                         ),
//                         trailing: Chip(
//                           label: Text(
//                             payment.status.toUpperCase(),
//                             style: const TextStyle(fontSize: 10),
//                           ),
//                           backgroundColor:
//                               _getStatusColor(payment.status).withOpacity(0.2),
//                         ),
//                         onTap: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (context) => PaymentDetailScreen(
//                                 paymentId: payment.id,
//                               ),
//                             ),
//                           ).then((_) {
//                             ref.invalidate(paymentStreamProvider);
//                           });
//                         },
//                       ),
//                     );
//                   },
//                 );
//               },
//               loading: () => const Center(child: CircularProgressIndicator()),
//               error: (error, stackTrace) => Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     const Icon(Icons.error, size: 64, color: Colors.red),
//                     const SizedBox(height: 16),
//                     Text('Erro: $error'),
//                     const SizedBox(height: 16),
//                     ElevatedButton(
//                       onPressed: () {
//                         ref.invalidate(paymentStreamProvider);
//                       },
//                       child: const Text('Retry'),
//                     )
//                   ],
//                 ),
//               ),
//             ),
//           )
//         ],
//       ),
//       floatingActionButton: canManage
//           ? FloatingActionButton.extended(
//               onPressed: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => const PaymentFormScreen(),
//                   ),
//                 ).then((_) {
//                   ref.invalidate(paymentStreamProvider);
//                 });
//               },
//               icon: const Icon(Icons.add),
//               label: const Text('New Payment'),
//             )
//           : null,
//     );
//   }

//   Widget _buildFilterChip(String value, String label, int count) {
//     final isSelected = _filterStatus == value;
//     return FilterChip(
//       label: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Text(label),
//           if (count > 0) ...[
//             const SizedBox(width: 4),
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//               decoration: BoxDecoration(
//                 color: isSelected ? Colors.white : Colors.blue,
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               child: Text(
//                 count.toString(),
//                 style: TextStyle(
//                   fontSize: 10,
//                   color: isSelected ? Colors.blue : Colors.white,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//           ],
//         ],
//       ),
//       selected: isSelected,
//       onSelected: (selected) {
//         setState(() {
//           _filterStatus = value;
//         });
//       },
//     );
//   }
// }
