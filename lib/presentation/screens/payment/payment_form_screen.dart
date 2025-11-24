import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:erp_purchasing_apps/data/models/payment_model.dart';
import 'package:erp_purchasing_apps/data/providers/payment_provider.dart';

class PaymentFormScreen extends ConsumerStatefulWidget {
  final String? supplierId;

  const PaymentFormScreen({
    super.key,
    this.supplierId,
  });

  @override
  ConsumerState<PaymentFormScreen> createState() => _PaymentFormScreenState();
}

class _PaymentFormScreenState extends ConsumerState<PaymentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();

  String? _selectedSupplierId;
  String? _selectedSupplierName;
  List<UnpaidLPBInfo> _availableLPBs = [];
  Set<String> _selectedLPBIds = {};
  DateTime? _selectedDueDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedSupplierId = widget.supplierId;
    if (_selectedSupplierId != null) {
      _loadLPBsBySupplier();
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadLPBsBySupplier() async {
    if (_selectedSupplierId == null) return;

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(paymentRepositoryProvider);
      final lpbs = await repository.getUnpaidLPBsBySupplier(_selectedSupplierId!);

      setState(() {
        _availableLPBs = lpbs;
        _selectedLPBIds.clear();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading LPBs: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  double _calculateTotalAmount() {
    return _availableLPBs
        .where((lpb) => _selectedLPBIds.contains(lpb.lpbId))
        .fold(0.0, (sum, lpb) => sum + lpb.amount);
  }

  Future<void> _selectDueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now().add(const Duration(days: 30)),
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

    if (_selectedSupplierId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a supplier'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedLPBIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one LPB'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(paymentRepositoryProvider);
      
      final request = CreatePaymentRequest(
        supplierId: _selectedSupplierId!,
        lpbIds: _selectedLPBIds.toList(),
        dueDate: _selectedDueDate,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      await repository.createPayment(request);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment created successfully'),
            backgroundColor: Colors.green,
          ),
        );
        ref.invalidate(paymentListProvider);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final unpaidGroupedAsync = ref.watch(unpaidLPBsGroupedProvider);

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
                            Icon(Icons.info_outline, color: Colors.blue.shade700),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Select supplier and choose multiple LPBs to create a combined payment',
                                style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // STEP 1: Select Supplier
                    Text(
                      'Step 1: Select Supplier',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),

                    unpaidGroupedAsync.when(
                      data: (summaries) {
                        if (summaries.isEmpty) {
                          return Card(
                            color: Colors.orange.shade50,
                            child: const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'No unpaid LPBs available. All invoices have been paid.',
                                style: TextStyle(color: Colors.orange),
                              ),
                            ),
                          );
                        }

                        return DropdownButtonFormField<String>(
                          value: _selectedSupplierId,
                          decoration: const InputDecoration(
                            labelText: 'Select Supplier *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.business),
                          ),
                          items: summaries.map((summary) {
                            return DropdownMenuItem(
                              value: summary.supplierId,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    summary.supplierName,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '${summary.lpbCount} LPBs - Rp ${NumberFormat('#,###').format(summary.totalAmount)}',
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedSupplierId = value;
                              _selectedSupplierName = summaries
                                  .firstWhere((s) => s.supplierId == value)
                                  .supplierName;
                            });
                            _loadLPBsBySupplier();
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Please select a supplier';
                            }
                            return null;
                          },
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (error, _) => Text('Error: $error'),
                    ),
                    const SizedBox(height: 24),

                    // STEP 2: Select LPBs
                    if (_selectedSupplierId != null) ...[
                      Text(
                        'Step 2: Select LPBs to Pay',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),

                      if (_availableLPBs.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('No unpaid LPBs for this supplier'),
                          ),
                        )
                      else
                        Column(
                          children: _availableLPBs.map((lpb) {
                            final isSelected = _selectedLPBIds.contains(lpb.lpbId);

                            return Card(
                              color: isSelected ? Colors.green.shade50 : null,
                              child: CheckboxListTile(
                                value: isSelected,
                                onChanged: (value) {
                                  setState(() {
                                    if (value == true) {
                                      _selectedLPBIds.add(lpb.lpbId);
                                    } else {
                                      _selectedLPBIds.remove(lpb.lpbId);
                                    }
                                  });
                                },
                                title: Text(
                                  lpb.lpbNumber,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('PO: ${lpb.poNumber}'),
                                    Text('Invoice: ${lpb.invoiceNumber}'),
                                    Text(
                                      'Amount: Rp ${NumberFormat('#,###').format(lpb.amount)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.blue,
                                      ),
                                    ),
                                    Text(
                                      'Receipt: ${DateFormat('dd MMM yyyy').format(lpb.receiptDate)}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 16),

                      // Total Amount Display
                      if (_selectedLPBIds.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total Payment Amount:',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                  Text(
                                    '${_selectedLPBIds.length} LPB(s) selected',
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                              Text(
                                'Rp ${NumberFormat('#,###').format(_calculateTotalAmount())}',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 24),

                      // STEP 3: Payment Details
                      Text(
                        'Step 3: Payment Details (Optional)',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),

                      // Due Date
                      InkWell(
                        onTap: _selectDueDate,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Due Date (Payment Schedule)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.calendar_today),
                            helperText: 'When this payment should be made',
                          ),
                          child: Text(
                            _selectedDueDate != null
                                ? DateFormat('dd MMMM yyyy').format(_selectedDueDate!)
                                : 'Select due date (optional)',
                            style: TextStyle(
                              color: _selectedDueDate != null ? Colors.black : Colors.grey,
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
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}