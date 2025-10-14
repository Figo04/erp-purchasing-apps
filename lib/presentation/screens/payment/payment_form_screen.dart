import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:erp_purchasing_apps/data/providers/payment_provider.dart';
import 'package:erp_purchasing_apps/data/repositories/po_repository.dart';
import 'package:intl/intl.dart';

class PaymentFormScreen extends ConsumerStatefulWidget {
  final String? poId;

  const PaymentFormScreen({
    super.key,
    this.poId,
  });

  @override
  ConsumerState<PaymentFormScreen> createState() => _PaymentFormScreenState();
}

class _PaymentFormScreenState extends ConsumerState<PaymentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _invoiceNumberController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedPoId;
  DateTime? _selectedDueDate;
  bool _isLoading = false;
  List<Map<String, dynamic>> _receivedPOs = [];

  @override
  void initState() {
    super.initState();
    _selectedPoId = widget.poId;
    _loadReceivedPOs();
  }

  @override
  void dispose() {
    _invoiceNumberController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadReceivedPOs() async {
    setState(() => _isLoading = true);

    try {
      final poRepo = PoRepository();
      final pos = await poRepo.getAllPOs();

      // Filter POs that are received don't have payment yet
      final paymentRepo = ref.read(paymentRepositoryProvider);
      final List<Map<String, dynamic>> receivedPOs = [];

      for (var po in pos) {
        if (po.status == 'received') {
          // Check if payment already exists
          final existingPaayment = await paymentRepo.getPaymentByPOId(po.id);
          if (existingPaayment == null) {
            receivedPOs.add({
              'id': po.id,
              'po_number': po.poNumber,
              'supplier_name': po.supplierName,
              'total_amount': po.totalAmount,
            });
          }
        }
      }

      setState(() {
        _receivedPOs = receivedPOs;
        if (_selectedPoId != null) {
          _loadPOData();
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading POs: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _loadPOData() {
    if (_selectedPoId == null) return;

    final po = _receivedPOs.firstWhere(
      (po) => po['id'] == _selectedPoId,
      orElse: () => {},
    );

    if (po.isNotEmpty) {
      _amountController.text = po['total_amount'].toStringAsFized(0);
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

  Future<void> _createPayment() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedPoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a PO'),
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

      await repository.createPayment(
        poId: _selectedPoId!,
        amount: amount,
        invoiceNumber: invoiceNumber.isEmpty ? null : invoiceNumber,
        dueDate: _selectedDueDate,
        notes: notes.isEmpty ? null : notes,
      );

      scaffoldMessenger.showSnackBar(const SnackBar(
        content: Text('Payment created successfully'),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Payment'),
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
                    // Info Card
                    Card(
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: Colors.blue.shade700),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Create payment for received Purchase Orders',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Select PO
                    DropdownButtonFormField<String>(
                      value: _selectedPoId,
                      decoration: const InputDecoration(
                        labelText: 'Select Purchase Order *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.shopping_cart),
                      ),
                      items: _receivedPOs.map((po) {
                        return DropdownMenuItem<String>(
                          value: po['id'],
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                po['po_number'],
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${po['supplier_name']} - Rp ${NumberFormat('#,###').format(po['total_amount'])}',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedPoId = value;
                          _loadPOData();
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a PO';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Invoice Number
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

                    // Amount Display
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
                              'Rp ${NumberFormat('#,###').format(double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0)}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Due Date
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
                              ? DateFormat('dd MMMM yyyy')
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

                    // Notes
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes (Optional)',
                        hintText: 'Additional information...',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.note),
                      ),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 24),

                    // Create Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _createPayment,
                        icon: const Icon(Icons.add),
                        label: const Text(
                          'Create Payment',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // info Note
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.orange.shade700, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Payment will be created with "Pending" status. Finance team can verify and process the payment later.',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.orange.shade700),
                            ),
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
    );
  }
}
