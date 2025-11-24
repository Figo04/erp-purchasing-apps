import 'package:erp_purchasing_apps/core/utils/unpaid_lpbs_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:erp_purchasing_apps/data/models/payment_model.dart';
import 'package:erp_purchasing_apps/data/providers/payment_provider.dart';
import 'package:erp_purchasing_apps/data/providers/auth_providers.dart';
import 'package:erp_purchasing_apps/presentation/screens/payment/payment_form_screen.dart';
import 'package:erp_purchasing_apps/presentation/screens/payment/payment_detail_screen.dart';

class PaymentListScreen extends ConsumerStatefulWidget {
  const PaymentListScreen({super.key});

  @override
  ConsumerState<PaymentListScreen> createState() => _PaymentListScreenState();
}

class _PaymentListScreenState extends ConsumerState<PaymentListScreen> {
  String _filterStatus = 'all';
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'scheduled':
        return Colors.blue;
      case 'paid':
        return Colors.green;
      case 'failed':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.schedule;
      case 'scheduled':
        return Icons.event;
      case 'paid':
        return Icons.check_circle;
      case 'failed':
        return Icons.error;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  bool _isOverdue(PaymentModel payment) {
    if (payment.dueDate == null) return false;
    return payment.dueDate!.isBefore(DateTime.now()) &&
        (payment.status == 'pending' || payment.status == 'scheduled');
  }

  PaymentFilterParams _buildFilterParams() {
    return PaymentFilterParams(
      status: _filterStatus == 'all' ? null : _filterStatus,
      search: _searchQuery.isEmpty ? null : _searchQuery,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final canManage = currentUser?.role == 'admin' || currentUser?.role == 'finance';
    
    final paymentsAsync = ref.watch(paymentListProvider(_buildFilterParams()));
    final overdueCountAsync = ref.watch(overduePaymentsCountProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
        title: const Text('Payment Management'),
        actions: [
          // Overdue badge
          overdueCountAsync.when(
            data: (count) {
              if (count > 0) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Center(
                    child: Chip(
                      label: Text(
                        'Overdue: $count',
                        style: const TextStyle(fontSize: 12, color: Colors.white),
                      ),
                      backgroundColor: Colors.red,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(paymentListProvider);
              ref.invalidate(overduePaymentsCountProvider);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Overdue Alert Banner
          overdueCountAsync.when(
            data: (count) {
              if (count > 0) {
                return Container(
                  width: double.infinity,
                  color: Colors.red.shade50,
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$count payment${count > 1 ? 's' : ''} overdue!',
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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

          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search payment number or supplier...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),

          // Status Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('all', 'All'),
                  const SizedBox(width: 8),
                  _buildFilterChip('pending', 'Pending'),
                  const SizedBox(width: 8),
                  _buildFilterChip('scheduled', 'Scheduled'),
                  const SizedBox(width: 8),
                  _buildFilterChip('paid', 'Paid'),
                  const SizedBox(width: 8),
                  _buildFilterChip('failed', 'Failed'),
                  const SizedBox(width: 8),
                  _buildFilterChip('cancelled', 'Cancelled'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Payment List
          Expanded(
            child: paymentsAsync.when(
              data: (payments) {
                if (payments.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.payment, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No payments found',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: payments.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final payment = payments[index];
                    final isOverdue = _isOverdue(payment);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      color: isOverdue ? Colors.red.shade50 : null,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getStatusColor(payment.status),
                          child: Icon(
                            _getStatusIcon(payment.status),
                            color: Colors.white,
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                payment.paymentNumber,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (isOverdue)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'OVERDUE',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (payment.supplierName != null)
                              Text('Supplier: ${payment.supplierName}'),
                            
                            // Show LPB count
                            if (payment.lpbs.isNotEmpty)
                              Text(
                                'LPBs: ${payment.lpbs.length} invoice(s)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),

                            Text(
                              'Amount: Rp ${NumberFormat('#,###').format(payment.amount)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.blue,
                              ),
                            ),

                            if (payment.dueDate != null)
                              Text(
                                'Due: ${DateFormat('dd MMM yyyy').format(payment.dueDate!)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isOverdue ? Colors.red : Colors.grey,
                                  fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                          ],
                        ),
                        trailing: Chip(
                          label: Text(
                            payment.status.toUpperCase(),
                            style: const TextStyle(fontSize: 10),
                          ),
                          backgroundColor: _getStatusColor(payment.status).withOpacity(0.2),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PaymentDetailScreen(
                                paymentId: payment.id,
                              ),
                            ),
                          ).then((_) {
                            ref.invalidate(paymentListProvider);
                          });
                        },
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        ref.invalidate(paymentListProvider);
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: canManage
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // View Unpaid LPBs Button
                FloatingActionButton(
                  heroTag: 'unpaid_lpbs',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const UnpaidLPBsScreen(),
                      ),
                    );
                  },
                  child: const Icon(Icons.list_alt),
                ),
                const SizedBox(height: 8),
                
                // Create Payment Button
                FloatingActionButton.extended(
                  heroTag: 'create_payment',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PaymentFormScreen(),
                      ),
                    ).then((_) {
                      ref.invalidate(paymentListProvider);
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('New Payment'),
                ),
              ],
            )
          : null,
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _filterStatus == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterStatus = value;
        });
      },
    );
  }
}