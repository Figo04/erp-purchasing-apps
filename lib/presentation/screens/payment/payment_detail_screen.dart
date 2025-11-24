import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:erp_purchasing_apps/data/models/payment_model.dart';
import 'package:erp_purchasing_apps/data/providers/payment_provider.dart';
import 'package:erp_purchasing_apps/data/providers/auth_providers.dart';

class PaymentDetailScreen extends ConsumerStatefulWidget {
  final String paymentId;

  const PaymentDetailScreen({
    super.key,
    required this.paymentId,
  });

  @override
  ConsumerState<PaymentDetailScreen> createState() => _PaymentDetailScreenState();
}

class _PaymentDetailScreenState extends ConsumerState<PaymentDetailScreen> {
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

  String _formatMethod(String? method) {
    if (method == null) return 'N/A';
    switch (method) {
      case 'bank_transfer':
        return 'Bank Transfer';
      case 'cash':
        return 'Cash';
      case 'e_wallet':
        return 'E-Wallet';
      case 'check':
        return 'Check';
      default:
        return method;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final canManage = currentUser?.role == 'admin' || currentUser?.role == 'finance';
    
    final paymentAsync = ref.watch(paymentDetailProvider(widget.paymentId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Detail'),
        actions: [
          if (canManage)
            PopupMenuButton(
              itemBuilder: (context) => [
                if (paymentAsync.value?.status != 'paid' && 
                    paymentAsync.value?.status != 'cancelled')
                  const PopupMenuItem(
                    value: 'cancel',
                    child: Row(
                      children: [
                        Icon(Icons.cancel, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Cancel Payment'),
                      ],
                    ),
                  ),
                if (paymentAsync.value?.status == 'pending')
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete Payment'),
                      ],
                    ),
                  ),
              ],
              onSelected: (value) {
                if (value == 'cancel') {
                  _showCancelDialog(paymentAsync.value!);
                } else if (value == 'delete') {
                  _showDeleteDialog(paymentAsync.value!);
                }
              },
            ),
        ],
      ),
      body: paymentAsync.when(
        data: (payment) {
          if (payment == null) {
            return const Center(
              child: Text('Payment not found'),
            );
          }

          final isOverdue = _isOverdue(payment);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Payment Header Card
                Card(
                  color: _getStatusColor(payment.status).withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              _getStatusIcon(payment.status),
                              size: 48,
                              color: _getStatusColor(payment.status),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    payment.paymentNumber,
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Rp ${NumberFormat('#,###').format(payment.amount)}',
                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                          color: Colors.green.shade700,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getStatusColor(payment.status),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            payment.status.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (isOverdue) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.warning, color: Colors.white, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'PAYMENT OVERDUE!',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Supplier Information
                Text(
                  'Supplier Information',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (payment.supplierName != null)
                          _buildInfoRow('Supplier', payment.supplierName!),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // LPBs (Invoices) Covered
                Text(
                  'LPBs Covered (${payment.lpbs.length})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (payment.lpbs.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No LPB information available'),
                    ),
                  )
                else
                  Column(
                    children: payment.lpbs.map((lpb) {
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.receipt, color: Colors.blue),
                          title: Text(
                            lpb.lpbNumber,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Invoice: ${lpb.invoiceNumber}'),
                              Text(
                                'Amount: Rp ${NumberFormat('#,###').format(lpb.amount)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 16),

                // Payment Schedule
                Text(
                  'Payment Schedule',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (payment.dueDate != null)
                          _buildInfoRow(
                            'Due Date',
                            DateFormat('dd MMM yyyy').format(payment.dueDate!),
                          ),
                        if (payment.paymentDate != null)
                          _buildInfoRow(
                            'Payment Date',
                            DateFormat('dd MMM yyyy').format(payment.paymentDate!),
                          ),
                        if (payment.method != null)
                          _buildInfoRow('Payment Method', _formatMethod(payment.method)),
                        if (payment.referenceNumber != null)
                          _buildInfoRow('Reference Number', payment.referenceNumber!),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Verification Info
                if (payment.verifiedBy != null || payment.paidBy != null) ...[
                  Text(
                    'Verification & Processing',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (payment.verifiedByName != null) ...[
                            _buildInfoRow('Verified By', payment.verifiedByName!),
                            if (payment.verifiedAt != null)
                              _buildInfoRow(
                                'Verified At',
                                DateFormat('dd MMM yyyy HH:mm').format(payment.verifiedAt!),
                              ),
                          ],
                          if (payment.paidByName != null)
                            _buildInfoRow('Paid By', payment.paidByName!),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Notes
                if (payment.notes != null && payment.notes!.isNotEmpty) ...[
                  Text(
                    'Notes',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(payment.notes!),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Timestamps
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow(
                          'Created At',
                          DateFormat('dd MMM yyyy HH:mm').format(payment.createdAt),
                        ),
                        _buildInfoRow(
                          'Last Updated',
                          DateFormat('dd MMM yyyy HH:mm').format(payment.updatedAt),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons (Finance/Admin only)
                if (canManage) ...[
                  Text(
                    'Actions',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),

                  // Verify Button
                  if (payment.status == 'pending')
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showVerifyDialog(payment),
                        icon: const Icon(Icons.verified),
                        label: const Text('Verify Payment'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),

                  // Process Payment Button
                  if (payment.status == 'pending' || payment.status == 'scheduled') ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showProcessPaymentDialog(payment),
                        icon: const Icon(Icons.payment),
                        label: const Text('Process Payment'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
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
                  ref.invalidate(paymentDetailProvider(widget.paymentId));
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  void _showVerifyDialog(PaymentModel payment) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Verify Payment'),
        content: const Text(
          'Verify that invoice amounts match with LPBs. After verification, payment will be scheduled.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _performVerify(payment.id);
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }

  Future<void> _performVerify(String paymentId) async {
    final repository = ref.read(paymentRepositoryProvider);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Verifying payment...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      await repository.verifyPayment(paymentId);

      if (mounted) {
        Navigator.pop(context);
        ref.invalidate(paymentDetailProvider(paymentId));
        ref.invalidate(paymentListProvider);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment verified successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showProcessPaymentDialog(PaymentModel payment) {
    DateTime selectedDate = DateTime.now();
    String selectedMethod = 'bank_transfer';
    final referenceController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Process Payment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Payment Date
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Payment Date'),
                  subtitle: Text(DateFormat('dd MMM yyyy').format(selectedDate)),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setDialogState(() {
                        selectedDate = picked;
                      });
                    }
                  },
                ),
                const SizedBox(height: 8),

                // Payment Method
                DropdownButtonFormField<String>(
                  value: selectedMethod,
                  decoration: const InputDecoration(
                    labelText: 'Payment Method',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'bank_transfer', child: Text('Bank Transfer')),
                    DropdownMenuItem(value: 'cash', child: Text('Cash')),
                    DropdownMenuItem(value: 'e_wallet', child: Text('E-Wallet')),
                    DropdownMenuItem(value: 'check', child: Text('Check')),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      selectedMethod = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Reference Number
                TextFormField(
                  controller: referenceController,
                  decoration: const InputDecoration(
                    labelText: 'Reference Number *',
                    hintText: 'e.g., TRX123456',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (referenceController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Reference number is required')),
                  );
                  return;
                }

                Navigator.pop(dialogContext);
                await _performProcessPayment(
                  payment.id,
                  selectedDate,
                  selectedMethod,
                  referenceController.text.trim(),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Process'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _performProcessPayment(
    String paymentId,
    DateTime paymentDate,
    String method,
    String referenceNumber,
  ) async {
    final repository = ref.read(paymentRepositoryProvider);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Processing payment...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final request = ProcessPaymentRequest(
        paymentDate: paymentDate,
        method: method,
        referenceNumber: referenceNumber,
      );

      await repository.processPayment(paymentId, request);

      if (mounted) {
        Navigator.pop(context);
        ref.invalidate(paymentDetailProvider(paymentId));
        ref.invalidate(paymentListProvider);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment processed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCancelDialog(PaymentModel payment) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Are you sure you want to cancel this payment?'),
            const SizedBox(height: 16),
            TextFormField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason *',
                border: OutlineInputBorder(),
                hintText: 'e.g., PO cancelled',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter reason')),
                );
                return;
              }

              Navigator.pop(dialogContext);
              await _performCancel(payment.id, reason);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cancel Payment'),
          ),
        ],
      ),
    );
  }

  Future<void> _performCancel(String paymentId, String reason) async {
    final repository = ref.read(paymentRepositoryProvider);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Cancelling payment...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      await repository.cancelPayment(paymentId, reason);

      if (mounted) {
        Navigator.pop(context);
        ref.invalidate(paymentDetailProvider(paymentId));
        ref.invalidate(paymentListProvider);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment cancelled successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteDialog(PaymentModel payment) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Payment'),
        content: const Text(
          'Are you sure you want to delete this payment? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _performDelete(payment.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _performDelete(String paymentId) async {
    final repository = ref.read(paymentRepositoryProvider);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Deleting payment...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      await repository.deletePayment(paymentId);

      if (mounted) {
        Navigator.pop(context);
        ref.invalidate(paymentListProvider);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}