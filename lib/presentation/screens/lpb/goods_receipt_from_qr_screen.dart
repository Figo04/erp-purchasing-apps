import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:erp_purchasing_apps/data/models/shipment_model.dart';
import 'package:erp_purchasing_apps/data/repositories/goods_receipt_repository.dart';
import 'package:erp_purchasing_apps/data/repositories/shipment_repository.dart';
import 'package:erp_purchasing_apps/data/providers/auth_providers.dart';

class GoodsReceiptFromQRScreen extends ConsumerStatefulWidget {
  final ShipmentQRData qrData;

  const GoodsReceiptFromQRScreen({super.key, required this.qrData});

  @override
  ConsumerState<GoodsReceiptFromQRScreen> createState() => _GoodsReceiptFromQRScreenState();
}

class _GoodsReceiptFromQRScreenState extends ConsumerState<GoodsReceiptFromQRScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  
  DateTime _receiptDate = DateTime.now();
  bool _isLoading = false;
  List<ReceiveItemForm> _items = [];

  @override
  void initState() {
    super.initState();
    _initializeItems();
  }

  void _initializeItems() {
    _items = widget.qrData.items.map((item) {
      return ReceiveItemForm(
        poItemId: item.poItemId,
        itemName: item.name,
        quantityShipped: item.qty,
        quantityReceivedController: TextEditingController(text: item.qty.toString()),
        unit: item.unit,
        notesController: TextEditingController(),
      );
    }).toList();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final grRepo = GoodsReceiptRepository();
      final shipmentRepo = ShipmentRepository();
      final currentUser = ref.read(currentUserProvider);

      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      // Prepare items data
      final itemsData = _items.map((item) {
        final qtyShipped = item.quantityShipped;
        final qtyReceived = int.parse(item.quantityReceivedController.text);

        return {
          'po_item_id': item.poItemId,
          'item_name': item.itemName,
          'quantity_ordered': qtyShipped, // From shipment
          'quantity_received': qtyReceived,
          'unit': item.unit,
          'notes': item.notesController.text.trim().isNotEmpty
              ? item.notesController.text.trim()
              : null,
        };
      }).toList();

      // Create goods receipt
      await grRepo.createReceipt(
        poId: widget.qrData.poId,
        receivedBy: currentUser.id,
        items: itemsData,
        receiptDate: _receiptDate,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );

      // Check if all items match (fully received)
      bool isFullyReceived = true;
      for (var item in _items) {
        if (int.parse(item.quantityReceivedController.text) != item.quantityShipped) {
          isFullyReceived = false;
          break;
        }
      }

      // Update shipment status
      await shipmentRepo.updateShipmentStatus(
        widget.qrData.shipmentId,
        isFullyReceived ? 'received' : 'partial',
      );

      // Update PO status if fully received
      await grRepo.updatePOStatusIfFullyReceived(widget.qrData.poId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isFullyReceived
                  ? 'Receipt created - All items received'
                  : 'Receipt created - Partial receipt (differences noted)',
            ),
            backgroundColor: isFullyReceived ? Colors.green : Colors.orange,
          ),
        );
        Navigator.pop(context); // Back to scanner or home
      }
    } catch (e) {
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

  @override
  void dispose() {
    _notesController.dispose();
    for (var item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify & Receive Goods'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
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
                    // Shipment Info Card
                    Card(
                      color: Colors.green.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.green.shade700),
                                const SizedBox(width: 12),
                                const Text(
                                  'QR Scanned Successfully',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            _buildInfoRow('Shipment', widget.qrData.shipmentNumber),
                            _buildInfoRow('PO Number', widget.qrData.poNumber),
                            _buildInfoRow('Delivery Note', widget.qrData.deliveryNoteNumber),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Receipt Date
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today),
                      title: Text(
                        'Receipt Date: ${DateFormat('dd MMM yyyy').format(_receiptDate)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit_calendar),
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _receiptDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 7)),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setState(() {
                              _receiptDate = date;
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
                        labelText: 'Receipt Notes (Optional)',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                        helperText: 'Any discrepancies or special notes',
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Items Header
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Verify Items',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            // Auto-fill all items with shipped quantity
                            setState(() {
                              for (var item in _items) {
                                item.quantityReceivedController.text =
                                    item.quantityShipped.toString();
                              }
                            });
                          },
                          icon: const Icon(Icons.done_all, size: 16),
                          label: const Text('Accept All'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Verify each item quantity. Edit if different from shipment.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Items List
                    ..._items.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      return _buildItemCard(index, item);
                    }),
                  ],
                ),
              ),
            ),

            // Bottom Action
            if (!_isLoading)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade300,
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Warning if discrepancy
                    if (_hasDiscrepancy()) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber, color: Colors.orange.shade700),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Quantity mismatch detected. This will be recorded.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _handleSubmit,
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Confirm Receipt'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Loading
            if (_isLoading)
              Container(
                padding: const EdgeInsets.all(24),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Creating receipt...'),
                  ],
                ),
              ),
          ],
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
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
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

  Widget _buildItemCard(int index, ReceiveItemForm item) {
    final qtyShipped = item.quantityShipped;
    final qtyReceived = int.tryParse(item.quantityReceivedController.text) ?? 0;
    final hasDifference = qtyReceived != qtyShipped;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: hasDifference ? Colors.orange.shade50 : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.itemName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (hasDifference)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'DIFF',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Comparison
            Row(
              children: [
                // Shipped
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SHIPPED',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$qtyShipped ${item.unit}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    Icons.arrow_forward,
                    color: Colors.grey.shade400,
                  ),
                ),
                // Received
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: hasDifference ? Colors.orange.shade100 : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: hasDifference ? Colors.orange.shade300 : Colors.green.shade200,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'RECEIVED',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: hasDifference ? Colors.orange.shade700 : Colors.green.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: item.quantityReceivedController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: hasDifference ? Colors.orange.shade700 : Colors.green.shade700,
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            suffixText: item.unit,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            final qty = int.tryParse(value);
                            if (qty == null || qty < 0) {
                              return 'Invalid';
                            }
                            return null;
                          },
                          onChanged: (_) => setState(() {}),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Difference indicator
            if (hasDifference) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Difference: ${qtyReceived - qtyShipped} ${item.unit} (${qtyReceived > qtyShipped ? 'more' : 'less'} than shipped)',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Item notes
            TextFormField(
              controller: item.notesController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Item Notes (Optional)',
                border: const OutlineInputBorder(),
                isDense: true,
                alignLabelWithHint: true,
                hintText: hasDifference ? 'Explain the difference...' : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _hasDiscrepancy() {
    for (var item in _items) {
      final qtyReceived = int.tryParse(item.quantityReceivedController.text) ?? 0;
      if (qtyReceived != item.quantityShipped) {
        return true;
      }
    }
    return false;
  }
}

class ReceiveItemForm {
  final String poItemId;
  final String itemName;
  final int quantityShipped;
  final TextEditingController quantityReceivedController;
  final String unit;
  final TextEditingController notesController;

  ReceiveItemForm({
    required this.poItemId,
    required this.itemName,
    required this.quantityShipped,
    required this.quantityReceivedController,
    required this.unit,
    required this.notesController,
  });

  void dispose() {
    quantityReceivedController.dispose();
    notesController.dispose();
  }
}