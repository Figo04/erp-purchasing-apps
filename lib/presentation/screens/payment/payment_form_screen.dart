import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:erp_purchasing_apps/data/providers/payment_provider.dart';
import 'package:erp_purchasing_apps/data/providers/goods_receipt_provider.dart';
import 'package:erp_purchasing_apps/data/repositories/po_repository.dart';
import 'package:intl/intl.dart';

class PaymentFormScreen extends ConsumerStatefulWidget {
  final String? receiptId; // 🔄 Changed from poId

  const PaymentFormScreen({
    super.key,
    this.receiptId, // 🔄 Changed parameter name
  });

  @override
  ConsumerState<PaymentFormScreen> createState() => _PaymentFormScreenState();
}

class _PaymentFormScreenState extends ConsumerState<PaymentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _invoiceNumberController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedReceiptId; // 🔄 Changed from _selectedPoId
  DateTime? _selectedDueDate;
  bool _isLoading = false;
  List<Map<String, dynamic>> _completedReceipts =
      []; // 🔄 Changed from _receivedPOs

  @override
  void initState() {
    super.initState();
    _selectedReceiptId = widget.receiptId; // 🔄
    _loadCompletedReceipts(); // 🔄 Changed function name
  }

  @override
  void dispose() {
    _invoiceNumberController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // 🔄 MODIFIED: Load completed receipts instead of POs
  Future<void> _loadCompletedReceipts() async {
    setState(() => _isLoading = true);

    try {
      final grRepo = ref.read(goodsReceiptRepositoryProvider);
      final receipts = await grRepo.getAllReceipts();

      final paymentRepo = ref.read(paymentRepositoryProvider);
      final List<Map<String, dynamic>> availableReceipts = [];

      for (var receipt in receipts) {
        if (receipt.status == 'completed') {
          final existingPayment =
              await paymentRepo.getPaymentByReceiptId(receipt.id);

          if (existingPayment == null) {
            // poId sudah String, langsung pakai
            final poRepo = PoRepository();
            final po =
                await poRepo.getPOById(receipt.poId); // ✅ Langsung String

            if (po != null) {
              availableReceipts.add({
                'id': receipt.id,
                'receipt_number': receipt.receiptNumber,
                'po_number': receipt.poNumber ?? po.poNumber,
                'supplier_name': po.supplierName ?? 'N/A',
                'total_amount': po.totalAmount,
                'receipt_date': receipt.receiptDate,
              });
            }
          }
        }
      }

      setState(() {
        _completedReceipts = availableReceipts;
        if (_selectedReceiptId != null) {
          _loadReceiptData();
        }
      });
    } catch (e) {
      print('🔴 Error details: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading receipts: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 🔄 MODIFIED: Load receipt data instead of PO data
  void _loadReceiptData() {
    if (_selectedReceiptId == null) return;

    final receipt = _completedReceipts.firstWhere(
      (r) => r['id'] == _selectedReceiptId,
      orElse: () => {},
    );

    if (receipt.isNotEmpty) {
      _amountController.text = receipt['total_amount'].toStringAsFixed(0);
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

    if (_selectedReceiptId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a Goods Receipt (LPB)'),
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

      // 🔄 CHANGED: Pass receiptId instead of poId
      await repository.createPayment(
        receiptId: _selectedReceiptId!, // 🔄 Changed parameter
        amount: amount,
        invoiceNumber: invoiceNumber.isEmpty ? null : invoiceNumber,
        dueDate: _selectedDueDate,
        notes: notes.isEmpty ? null : notes,
      );

      scaffoldMessenger.showSnackBar(const SnackBar(
        content: Text('Payment created successfully'),
        backgroundColor: Colors.green,
      ));
      ref.invalidate(paymentStreamProvider);
      navigator.pop();
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
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
                    // Info Card - 🔄 UPDATED text
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
                                'Create payment from completed Goods Receipt (LPB). Invoice from supplier must be received first.',
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

                    // 🔄 MODIFIED: Select Goods Receipt instead of PO
                    DropdownButtonFormField<String>(
                      value: _selectedReceiptId,
                      decoration: const InputDecoration(
                        labelText: 'Select Goods Receipt (LPB) *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.inventory_2),
                        helperText:
                            'Select completed LPB that has no payment yet',
                      ),
                      isExpanded: true, // ✅ TAMBAHKAN INI
                      items: _completedReceipts.map((receipt) {
                        return DropdownMenuItem<String>(
                          value: receipt['id'],
                          child: Text(
                            '${receipt['receipt_number']} - ${receipt['supplier_name']} - Rp ${NumberFormat('#,###').format(receipt['total_amount'])}',
                            overflow:
                                TextOverflow.ellipsis, // ✅ Handle text panjang
                            maxLines: 1, // ✅ Batasi 1 baris
                            style: const TextStyle(fontSize: 14),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedReceiptId = value;
                          _loadReceiptData();
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a Goods Receipt';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // 🔄 UPDATED: Invoice Number field with better description
                    TextFormField(
                      controller: _invoiceNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Invoice Number (from Supplier) *',
                        hintText: 'e.g., INV-2024-001',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.receipt),
                        helperText: 'Invoice number received from supplier',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Invoice number is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Amount Field
                    TextFormField(
                      controller: _amountController,
                      decoration: const InputDecoration(
                        labelText: 'Payment Amount *',
                        hintText: 'e.g., 15000000',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                        prefixText: 'Rp ',
                        helperText: 'Amount must match invoice from supplier',
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
                          helperText: 'When this payment should be made',
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

                    // Info Note - 🔄 UPDATED text
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
                              'Payment will be created with "Pending" status. Finance team will verify the invoice and process the payment later.',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.orange.shade700),
                            ),
                          )
                        ],
                      ),
                    ),

                    // 🆕 NEW: Show warning if no receipts available
                    if (_completedReceipts.isEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning, color: Colors.red.shade700),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'No completed Goods Receipts (LPB) available. Please complete LPB first before creating payment.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.red.shade700,
                                ),
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
    );
  }
}
