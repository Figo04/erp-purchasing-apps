import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:erp_purchasing_apps/data/providers/payment_provider.dart';
import 'package:erp_purchasing_apps/data/models/payment_model.dart';
import 'package:intl/intl.dart';

class PaymentEditScreen extends ConsumerStatefulWidget {
  final String paymentId;

  const PaymentEditScreen({
    super.key,
    required this.paymentId,
  });

  @override
  ConsumerState<PaymentEditScreen> createState() => _PaymentEditScreenState();
}

class _PaymentEditScreenState extends ConsumerState<PaymentEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _invoiceNumberController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime? _selectedDueDate;
  bool _isLoading = false;
  PaymentModel? _payment;

  @override
  void initState() {
    super.initState();
    _loadPaymentData();
  }

  @override
  void dispose() {
    _invoiceNumberController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadPaymentData() async {
    setState(() => _isLoading = true);

    try {
      final repository = ref.read(paymentRepositoryProvider);
      final payment = await repository.getPaymentById(widget.paymentId);

      if (payment != null) {
        setState(() {
          _payment = payment;
          _invoiceNumberController.text = payment.invoiceNumber ?? '';
          _amountController.text = payment.amount.toStringAsFixed(0);
          _notesController.text = payment.notes ?? '';
          _selectedDueDate = payment.dueDate;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading payment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedDueDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _selectedDueDate = picked;
      });
    }
  }

  Future<void> _updatePayment() async {
    if (!_formKey.currentState!.validate()) return;

    if (_payment == null) return;

    // Check if payment is still pending
    if (_payment!.status != 'pending') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Can only edit pending payments. Current status: ${_payment!.status}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final repository = ref.read(paymentRepositoryProvider);

    try {
      final amount = double.parse(_amountController.text.replaceAll(',', ''));
      final invoiceNumber = _invoiceNumberController.text.trim();
      final notes = _notesController.text.trim();

      await repository.updatePayment(
        id: widget.paymentId,
        invoiceNumber: invoiceNumber.isEmpty ? null : invoiceNumber,
        amount: amount,
        dueDate: _selectedDueDate,
        notes: notes.isEmpty ? null : notes,
      );

      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Payment updated succesfully'),
          backgroundColor: Colors.green,
        ),
      );

      ref.invalidate(paymentStreamProvider);
      navigator.pop(true);
    } catch (e) {
      scaffoldMessenger.showSnackBar(SnackBar(
        content: Text(('Failed: ${e.toString()}')),
        backgroundColor: Colors.red,
      ));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_payment == null && _isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_payment == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(
          child: Text('Payment not found'),
        ),
      );
    }

    // Check if payment can be edited
    final canEdit = _payment!.status == 'pending';

    if (!canEdit) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cannot Edit')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 64, color: Colors.orange),
              const SizedBox(height: 16),
              Text(
                'Payment cannot be edited',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Status: ${_payment!.status.toUpperCase()}',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 25),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              )
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Payment'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info card
                    Card(
                      color: Colors.orange.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: Colors.orange.shade700),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'you can only edit payments with "Pendig" status',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Payment Number (Read-Only)
                    TextFormField(
                      initialValue: _payment!.paymentNumber,
                      decoration: const InputDecoration(
                        labelText: 'Payment Number',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.tag),
                      ),
                      enabled: false,
                    ),
                    const SizedBox(height: 16),

                    // PO Number (Read-only)
                    TextFormField(
                      initialValue: _payment!.poNumber ?? 'N/A',
                      decoration: const InputDecoration(
                        labelText: 'Purchase order',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.shopping_cart),
                      ),
                      enabled: false,
                    ),
                    const SizedBox(height: 16),

                    // Supplier (Read-only)
                    TextFormField(
                      initialValue: _payment!.supplierName ?? 'N/A',
                      decoration: const InputDecoration(
                        labelText: 'Supplier',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.business),
                      ),
                      enabled: false,
                    ),
                    const SizedBox(height: 16),

                    // Invoice Number (Editable)
                    TextFormField(
                      controller: _invoiceNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Invoice Number (from Supplier)',
                        hintText: 'e.g., INV-2024-001',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.receipt),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Payment Amount (Editable)
                    TextFormField(
                      controller: _amountController,
                      decoration: const InputDecoration(
                        labelText: 'Payment Amount *',
                        hintText: 'e.g., 15000000',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                        prefixText: 'Rp ',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter amount';
                        }
                        final amount =
                            double.tryParse(value.replaceAll(',', ''));
                        if (amount == null || amount <= 0) {
                          return 'Invalid amount';
                        }
                        return null;
                      },
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 8),

                    // Amount display
                    if (_amountController.text.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Payment:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.green.shade700,
                              ),
                            ),
                            Text(
                              'Rp ${NumberFormat('#,###').format(double.tryParse(_amountController.text.replaceAll('', '')) ?? 0)}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            )
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Due Date (Editable)
                    InkWell(
                      onTap: _selectDueDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Due Date (Payment Schedule)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          _selectedDueDate != null
                              ? DateFormat('dd MMM yyyy')
                                  .format(_selectedDueDate!)
                              : 'Select due date (optional)',
                          style: TextStyle(
                            color: _selectedDueDate != null
                                ? Colors.black
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Update Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _updatePayment,
                        icon: const Icon(Icons.save),
                        label: const Text(
                          'Update Payment',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
    );
  }
}
