import 'package:erp_purchasing_apps/core/constants/api_constants.dart';
import 'package:erp_purchasing_apps/core/service/api_service.dart';
import 'package:erp_purchasing_apps/data/models/purchase_order_model.dart';
import 'package:erp_purchasing_apps/data/models/shipment_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

class SupplierShipmentFormScreen extends ConsumerStatefulWidget {
  final String? poId;

  const SupplierShipmentFormScreen({super.key, this.poId});

  @override
  ConsumerState<SupplierShipmentFormScreen> createState() =>
      _SupplierShipmentFormScreenState();
}

class _SupplierShipmentFormScreenState
    extends ConsumerState<SupplierShipmentFormScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _deliveryNoteController = TextEditingController();
  final _notesController = TextEditingController();
  final _invoiceNumberController = TextEditingController();
  // ❌ REMOVED: _invoiceAmountController (auto-calculated by backend)

  String? _selectedPOId;
  PurchaseOrderModel? _selectedPO;
  DateTime _shipmentDate = DateTime.now();
  bool _isLoading = false;

  final List<ShipmentItemForm> _items = [];
  ShipmentModel? _createdShipment;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.poId != null) {
        _selectedPOId = widget.poId;
        _loadPOData();
      }
    });
  }

  Future<void> _loadPOData() async {
    if (_selectedPOId == null) return;

    setState(() => _isLoading = true);

    try {
      final response = await _apiService.get(
        ApiEndpoints.supplierPOById(_selectedPOId!),
      );

      if (response.success && response.data != null) {
        final po =
            PurchaseOrderModel.fromJson(response.data as Map<String, dynamic>);

        if (mounted) {
          setState(() {
            _selectedPO = po;
            _items.clear();

            if (po.items != null) {
              for (var poItem in po.items!) {
                _items.add(ShipmentItemForm(
                  poItemId: poItem.id,
                  itemName: poItem.itemName,
                  quantityOrdered: poItem.quantity,
                  unit: poItem.unit,
                  unitPrice: poItem.unitPrice, // ✅ Store unit price
                  quantityController:
                      TextEditingController(text: poItem.quantity.toString()),
                  notesController: TextEditingController(),
                ));
              }
            }
          });
        }
      }
    } catch (e) {
      print('❌ Error loading PO: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading PO: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ✅ NEW: Calculate total invoice amount (for display only)
  double _calculateTotalAmount() {
    double total = 0.0;
    for (var item in _items) {
      final qty = int.tryParse(item.quantityController.text) ?? 0;
      total += qty * item.unitPrice;
    }
    return total;
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedPOId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a PO'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Prepare items data
      final itemsData = _items.map((item) {
        return {
          'po_item_id': item.poItemId,
          'quantity_shipped': int.parse(item.quantityController.text),
          'notes': item.notesController.text.trim().isNotEmpty
              ? item.notesController.text.trim()
              : null,
        };
      }).toList();

      // ✅ UPDATED: Create shipment WITHOUT invoice_amount (auto-calculated by backend)
      final response = await _apiService.post(
        ApiEndpoints.supplierShipments,
        body: {
          'po_id': _selectedPOId,
          'delivery_note_number': _deliveryNoteController.text.trim(),
          'invoice_number': _invoiceNumberController.text.trim(), // ✅ Required
          // ❌ REMOVED: 'invoice_amount' - backend will auto-calculate
          'shipment_date': _shipmentDate.toIso8601String(),
          'items': itemsData,
          'notes': _notesController.text.trim().isNotEmpty
              ? _notesController.text.trim()
              : null,
        },
      );

      if (response.success && response.data != null) {
        final shipment =
            ShipmentModel.fromJson(response.data as Map<String, dynamic>);

        if (mounted) {
          setState(() {
            _createdShipment = shipment;
          });

          // Show success dialog with QR
          _showSuccessDialog(shipment);
        }
      }
    } catch (e) {
      print('❌ Error creating shipment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
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

  void _showSuccessDialog(ShipmentModel shipment) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Success Icon
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle,
                      size: 64,
                      color: Colors.green.shade700,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title
                  Text(
                    'Shipment Created Successfully!',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    shipment.shipmentNumber,
                    style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),

                  // ✅ NEW: Display auto-calculated invoice amount
                  if (shipment.invoiceAmount != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Invoice Amount (Auto-calculated)',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Rp ${NumberFormat('#,###').format(shipment.invoiceAmount)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),

                  // QR Code
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade300, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Scan this QR on delivery',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        QrImageView(
                          data: shipment.qrCodeData ?? '',
                          version: QrVersions.auto,
                          size: 200.0,
                          backgroundColor: Colors.white,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Delivery Note: ${shipment.deliveryNoteNumber}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (shipment.invoiceNumber != null)
                          Text(
                            'Invoice: ${shipment.invoiceNumber}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: Colors.blue.shade700, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Print this QR code and attach it to the delivery note. Warehouse will scan it on arrival.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Buttons
                  Row(children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Print feature coming soon')),
                          );
                        },
                        icon: const Icon(Icons.print, size: 18),
                        label: const Text('Print'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          context.go('/supplier/shipments');
                        },
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Done'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    )
                  ])
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/supplier/dashboard'),
        ),
        title: const Text('Create Shipment'),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Selected PO Info
                    if (_selectedPO != null)
                      Card(
                        color: Colors.blue.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.shopping_cart,
                                      color: Colors.blue.shade700),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Purchase Order',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          _selectedPO!.poNumber,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      ],
                                    ),
                                  )
                                ],
                              ),
                              const Divider(height: 24),
                              Text(
                                  'Total: Rp ${NumberFormat('#,###').format(_selectedPO!.totalAmount)}'),
                              Text(
                                  'Order Date: ${DateFormat('dd MMM yyyy').format(_selectedPO!.orderDate)}'),
                            ],
                          ),
                        ),
                      )
                    else
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Please select a PO from dashboard',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Delivery Note Number
                    TextFormField(
                      controller: _deliveryNoteController,
                      decoration: const InputDecoration(
                        labelText: 'Delivery Note Number *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                        helperText: 'Your internal delivery/invoice number',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter delivery note number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Invoice Number (REQUIRED)
                    TextFormField(
                      controller: _invoiceNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Invoice Number *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.receipt),
                        helperText: 'Invoice number from your billing system',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter invoice number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // ❌ REMOVED: Invoice Amount Input Field
                    // Backend will auto-calculate based on PO items * quantity_shipped

                    // ✅ NEW: Display estimated invoice amount (read-only)
                    if (_items.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline,
                                    color: Colors.green.shade700, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Estimated Invoice Amount',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Rp ${NumberFormat('#,###').format(_calculateTotalAmount())}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'This amount will be calculated automatically based on shipped quantities',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Shipment Date
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today),
                      title: Text(
                        'Shipment Date: ${DateFormat('dd MMM yyyy').format(_shipmentDate)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit_calendar),
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _shipmentDate,
                            firstDate: DateTime.now()
                                .subtract(const Duration(days: 7)),
                            lastDate:
                                DateTime.now().add(const Duration(days: 30)),
                          );
                          if (date != null) {
                            setState(() {
                              _shipmentDate = date;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Notes
                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Notes (Optional)',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Items Section
                    if (_items.isNotEmpty) ...[
                      Text(
                        'Items to Ship',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enter the quantity you are shipping for each item',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._items.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        return _buildItemCard(index, item);
                      }),
                    ],

                    if (_isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(),
                        ),
                      )
                  ],
                ),
              ),
            ),

            // Bottom Button
            if (!_isLoading && _items.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, boxShadow: [
                  BoxShadow(
                      color: Colors.grey.shade300,
                      blurRadius: 4,
                      offset: const Offset(0, -2))
                ]),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _handleSubmit,
                    icon: const Icon(Icons.qr_code),
                    label: const Text('Create Shipment & Generate QR'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(int index, ShipmentItemForm item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.itemName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            // ✅ NEW: Display unit price
            Text(
              'Unit Price: Rp ${NumberFormat('#,###').format(item.unitPrice)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ordered',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade600),
                        ),
                        Text(
                          '${item.quantityOrdered} ${item.unit}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: item.quantityController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: 'Shipping *',
                      border: const OutlineInputBorder(),
                      isDense: true,
                      suffixText: item.unit,
                    ),
                    onChanged: (value) {
                      // ✅ Trigger rebuild to update estimated amount
                      setState(() {});
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      final qty = int.tryParse(value);
                      if (qty == null || qty <= 0) {
                        return 'Invalid';
                      }
                      if (qty > item.quantityOrdered) {
                        return 'Max ${item.quantityOrdered}';
                      }
                      return null;
                    },
                  ),
                )
              ],
            ),
            const SizedBox(height: 8),
            // ✅ NEW: Display subtotal for this item
            if (item.quantityController.text.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Subtotal:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    Text(
                      'Rp ${NumberFormat('#,###').format((int.tryParse(item.quantityController.text) ?? 0) * item.unitPrice)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            TextFormField(
              controller: item.notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Item Notes (Optional)',
                border: OutlineInputBorder(),
                isDense: true,
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _deliveryNoteController.dispose();
    _notesController.dispose();
    _invoiceNumberController.dispose();
    // ❌ REMOVED: _invoiceAmountController.dispose()
    for (var item in _items) {
      item.dispose();
    }
    super.dispose();
  }
}

// ✅ UPDATED: Add unitPrice to ShipmentItemForm
class ShipmentItemForm {
  final String poItemId;
  final String itemName;
  final int quantityOrdered;
  final String unit;
  final double unitPrice; // ✅ NEW
  final TextEditingController quantityController;
  final TextEditingController notesController;

  ShipmentItemForm({
    required this.poItemId,
    required this.itemName,
    required this.quantityOrdered,
    required this.unit,
    required this.unitPrice, // ✅ NEW
    required this.quantityController,
    required this.notesController,
  });

  void dispose() {
    quantityController.dispose();
    notesController.dispose();
  }
}
