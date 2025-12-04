import 'package:erp_purchasing_apps/data/providers/lpb_provider.dart';
import 'package:erp_purchasing_apps/data/providers/shipment_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:erp_purchasing_apps/data/models/shipment_model.dart';

/// Shipment Verification Screen with Beacukai Form
class ShipmentVerificationScreen extends ConsumerStatefulWidget {
  final ShipmentModel shipment;

  const ShipmentVerificationScreen({
    super.key,
    required this.shipment,
  });

  @override
  ConsumerState<ShipmentVerificationScreen> createState() =>
      _ShipmentVerificationScreenState();
}

class _ShipmentVerificationScreenState
    extends ConsumerState<ShipmentVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  
  // ✅ BEACUKAI CONTROLLERS
  final _beacukaiDocController = TextEditingController();
  final _beacukaiNoController = TextEditingController();
  final _beacukaiNoAjuController = TextEditingController();

  DateTime _receiptDate = DateTime.now();
  DateTime? _beacukaiTgl;
  bool _isLoading = false;
  List<VerificationItemForm> _items = [];

  @override
  void initState() {
    super.initState();
    _initializeItems();
    _initializeBeacukai();
  }

  void _initializeItems() {
    if (widget.shipment.items == null || widget.shipment.items!.isEmpty) {
      return;
    }

    _items = widget.shipment.items!.map((item) {
      return VerificationItemForm(
        id: item.id,
        poItemId: item.poItemId,
        itemName: item.itemName,
        quantityOrdered: item.quantityOrdered,
        quantityShipped: item.quantityShipped,
        quantityReceivedController: TextEditingController(
          text: item.quantityShipped.toString(),
        ),
        unit: item.unit,
        notesController: TextEditingController(),
        productCode: item.productCode,
        categoryName: item.categoryName,
      );
    }).toList();
  }

  // ✅ INITIALIZE BEACUKAI dari shipment (jika ada)
  void _initializeBeacukai() {
    if (widget.shipment.hasBeacukai) {
      _beacukaiDocController.text = widget.shipment.beacukaiDoc ?? '';
      _beacukaiNoController.text = widget.shipment.beacukaiNo ?? '';
      _beacukaiNoAjuController.text = widget.shipment.beacukaiNoAju ?? '';
      _beacukaiTgl = widget.shipment.beacukaiTgl;
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final itemsData = _items.map((item) {
        return {
          'po_item_id': item.poItemId,
          'quantity_received': int.parse(item.quantityReceivedController.text),
          'notes': item.notesController.text.trim().isNotEmpty
              ? item.notesController.text.trim()
              : null,
        };
      }).toList();

      bool isFullyReceived = true;
      for (var item in _items) {
        if (int.parse(item.quantityReceivedController.text) !=
            item.quantityShipped) {
          isFullyReceived = false;
          break;
        }
      }

      // ✅ CREATE LPB WITH BEACUKAI
      final lpb = await ref.read(lpbDetailProvider.notifier).createLPB(
            poId: widget.shipment.poId,
            shipmentId: widget.shipment.id,
            receiptDate: DateTime(
              _receiptDate.year,
              _receiptDate.month,
              _receiptDate.day,
              DateTime.now().hour,
              DateTime.now().minute,
              DateTime.now().second,
            ),
            invoiceNumber: widget.shipment.invoiceNumber,
            invoiceAmount: widget.shipment.invoiceAmount,
            // ✅ BEACUKAI DATA
            beacukaiDoc: _beacukaiDocController.text.trim().isEmpty
                ? null
                : _beacukaiDocController.text.trim(),
            beacukaiTgl: _beacukaiTgl,
            beacukaiNo: _beacukaiNoController.text.trim().isEmpty
                ? null
                : _beacukaiNoController.text.trim(),
            beacukaiNoAju: _beacukaiNoAjuController.text.trim().isEmpty
                ? null
                : _beacukaiNoAjuController.text.trim(),
            notes: _notesController.text.trim().isNotEmpty
                ? _notesController.text.trim()
                : null,
            items: itemsData,
          );

      if (lpb == null) {
        throw Exception('Failed to create LPB');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isFullyReceived
                  ? 'LPB Created Successfully - All items received'
                  : 'LPB Created - Partial receipt (differences noted)',
            ),
            backgroundColor: isFullyReceived ? Colors.green : Colors.orange,
          ),
        );

        ref.invalidate(shipmentListProvider);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating LPB: $e'),
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
    _beacukaiDocController.dispose();
    _beacukaiNoController.dispose();
    _beacukaiNoAjuController.dispose();
    for (var item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Shipment & Create LPB'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Shipment Info Card
                        _buildShipmentInfoCard(),
                        const SizedBox(height: 24),

                        // ✅ BEACUKAI INFORMATION CARD (NEW)
                        _buildBeacukaiCard(),
                        const SizedBox(height: 24),

                        // Receipt Date & Notes
                        _buildReceiptDateAndNotes(),
                        const SizedBox(height: 32),

                        // Items Section
                        _buildItemsSection(),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Bottom Action Bar
            _buildBottomActionBar(),
          ],
        ),
      ),
    );
  }

  // ============================================
  // UI COMPONENTS
  // ============================================

  Widget _buildShipmentInfoCard() {
    return Card(
      color: Colors.green.shade50,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade700, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Shipment Verified Successfully',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            const Divider(height: 32),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _buildInfoRow('Shipment Number', widget.shipment.shipmentNumber),
                      _buildInfoRow('PO Number', widget.shipment.poNumber ?? '-'),
                      _buildInfoRow('Delivery Note', widget.shipment.deliveryNoteNumber),
                    ],
                  ),
                ),
                const SizedBox(width: 32),
                Expanded(
                  child: Column(
                    children: [
                      _buildInfoRow('Supplier', widget.shipment.supplierName ?? '-'),
                      _buildInfoRow('Shipment Date',
                          DateFormat('dd MMM yyyy').format(widget.shipment.shipmentDate)),
                      _buildInfoRow('Status', widget.shipment.status.toUpperCase()),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ✅ BEACUKAI CARD (NEW)
  Widget _buildBeacukaiCard() {
    return Card(
      color: Colors.blue.shade50,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.description, color: Colors.blue.shade700, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'BEACUKAI INFORMATION',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Spacer(),
                Text(
                  '(Optional - Leave blank if not applicable)',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // ✅ 2 COLUMN LAYOUT (Desktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // LEFT COLUMN
                Expanded(
                  child: Column(
                    children: [
                      // Beacukai Doc
                      TextFormField(
                        controller: _beacukaiDocController,
                        decoration: const InputDecoration(
                          labelText: 'Beacukai Document',
                          hintText: 'e.g., BC 2.0, BC 4.0',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.folder_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Beacukai No
                      TextFormField(
                        controller: _beacukaiNoController,
                        decoration: const InputDecoration(
                          labelText: 'Beacukai Number',
                          hintText: 'Document number',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.numbers),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                
                // RIGHT COLUMN
                Expanded(
                  child: Column(
                    children: [
                      // Beacukai Date
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _beacukaiTgl ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setState(() => _beacukaiTgl = date);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Beacukai Date',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.calendar_today),
                            suffixIcon: Icon(Icons.arrow_drop_down),
                          ),
                          child: Text(
                            _beacukaiTgl != null
                                ? DateFormat('dd MMMM yyyy').format(_beacukaiTgl!)
                                : 'Select date',
                            style: TextStyle(
                              fontSize: 16,
                              color: _beacukaiTgl != null ? Colors.black : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Beacukai No Aju
                      TextFormField(
                        controller: _beacukaiNoAjuController,
                        decoration: const InputDecoration(
                          labelText: 'Beacukai No. Aju',
                          hintText: 'Submission number',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.assignment_outlined),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            // Info hint
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Beacukai data can be filled now or added later. Domestic items don\'t require beacukai.',
                      style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptDateAndNotes() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Card(
            child: ListTile(
              leading: const Icon(Icons.calendar_today, color: Colors.blue),
              title: const Text('Receipt Date',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
              subtitle: Text(DateFormat('dd MMMM yyyy').format(_receiptDate),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                    setState(() => _receiptDate = date);
                  }
                },
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'LPB Notes (Optional)',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                  helperText: 'Any discrepancies or special notes',
                  isDense: true,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('Verify Items',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  for (var item in _items) {
                    item.quantityReceivedController.text =
                        item.quantityShipped.toString();
                  }
                });
              },
              icon: const Icon(Icons.done_all, size: 18),
              label: const Text('Accept All Quantities'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text('Review each item and confirm the received quantity.',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
        const SizedBox(height: 24),
        ..._items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return _buildItemCard(index, item);
        }),
      ],
    );
  }

  Widget _buildItemCard(int index, VerificationItemForm item) {
    final qtyShipped = item.quantityShipped;
    final qtyReceived = int.tryParse(item.quantityReceivedController.text) ?? 0;
    final hasDifference = qtyReceived != qtyShipped;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: hasDifference ? Colors.orange.shade50 : Colors.white,
      elevation: hasDifference ? 4 : 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text('${index + 1}',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.itemName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      if (item.productCode != null) ...[
                        const SizedBox(height: 4),
                        Text('Code: ${item.productCode}',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600)),
                      ],
                    ],
                  ),
                ),
                if (hasDifference)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text('DIFFERENCE',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildQuantityBox(
                      'ORDERED', item.quantityOrdered, item.unit, Colors.grey),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(Icons.arrow_forward, color: Colors.grey.shade400),
                ),
                Expanded(
                  child: _buildQuantityBox(
                      'SHIPPED', qtyShipped, item.unit, Colors.blue),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(Icons.arrow_forward, color: Colors.grey.shade400),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: hasDifference
                          ? Colors.orange.shade100
                          : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: hasDifference
                            ? Colors.orange.shade300
                            : Colors.green.shade200,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('RECEIVED',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: hasDifference
                                    ? Colors.orange.shade700
                                    : Colors.green.shade700)),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: item.quantityReceivedController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: hasDifference
                                  ? Colors.orange.shade700
                                  : Colors.green.shade700),
                          decoration: InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            suffixText: item.unit,
                            suffixStyle: TextStyle(
                                fontSize: 14,
                                color: hasDifference
                                    ? Colors.orange.shade700
                                    : Colors.green.shade700),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Required';
                            final qty = int.tryParse(value);
                            if (qty == null || qty < 0) return 'Invalid';
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
            if (hasDifference) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 20, color: Colors.orange.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Difference: ${qtyReceived - qtyShipped} ${item.unit} (${qtyReceived > qtyShipped ? 'MORE' : 'LESS'} than shipped)',
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: item.notesController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Item Notes (Optional)',
                border: const OutlineInputBorder(),
                isDense: true,
                alignLabelWithHint: true,
                hintText: hasDifference
                    ? 'Please explain the difference...'
                    : 'Any additional notes...',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityBox(
      String label, int quantity, String unit, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: color.shade700)),
          const SizedBox(height: 4),
          Text('$quantity $unit',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color.shade700)),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar() {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Creating LPB...',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 8,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_hasDiscrepancy()) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber,
                          color: Colors.orange.shade700, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Quantity mismatch detected. This will be recorded in the LPB.',
                          style: TextStyle(
                              fontSize: 14,
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _handleSubmit,
                  icon: const Icon(Icons.check_circle, size: 24),
                  label: const Text('Create LPB (Confirm Receipt)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text('$label:',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                    fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  bool _hasDiscrepancy() {
    for (var item in _items) {
      final qtyReceived =
          int.tryParse(item.quantityReceivedController.text) ?? 0;
      if (qtyReceived != item.quantityShipped) {
        return true;
      }
    }
    return false;
  }
}

class VerificationItemForm {
  final String id;
  final String poItemId;
  final String itemName;
  final int quantityOrdered;
  final int quantityShipped;
  final TextEditingController quantityReceivedController;
  final String unit;
  final TextEditingController notesController;
  final String? productCode;
  final String? categoryName;

  VerificationItemForm({
    required this.id,
    required this.poItemId,
    required this.itemName,
    required this.quantityOrdered,
    required this.quantityShipped,
    required this.quantityReceivedController,
    required this.unit,
    required this.notesController,
    this.productCode,
    this.categoryName,
  });

  void dispose() {
    quantityReceivedController.dispose();
    notesController.dispose();
  }
}