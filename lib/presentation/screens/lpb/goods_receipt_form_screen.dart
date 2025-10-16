import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:erp_purchasing_apps/data/providers/goods_receipt_provider.dart';
import 'package:erp_purchasing_apps/data/providers/po_provider.dart';
import 'package:erp_purchasing_apps/data/providers/auth_providers.dart';
import 'package:erp_purchasing_apps/data/models/purchase_order_model.dart';
import 'package:erp_purchasing_apps/data/models/goods_receipt_model.dart';

class GoodsReceiptFormScreen extends ConsumerStatefulWidget {
  final String? poId;

  const GoodsReceiptFormScreen({super.key, this.poId});

  @override
  ConsumerState<GoodsReceiptFormScreen> createState() =>
      _GoodsReceiptFormScreenState();
}

class _GoodsReceiptFormScreenState
    extends ConsumerState<GoodsReceiptFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();

  String? _selectedPOId;
  PurchaseOrderModel? _selectedPO;
  DateTime _receiptDate = DateTime.now();
  bool _isLoading = false;

  List<ReceiptItemForm> _items = [];
  Map<String, POItemReceiptSummary> _summaryMap = {};

  @override
  void initState() {
    super.initState();
    if (widget.poId != null) {
      _selectedPOId = widget.poId;
      _loadPOData();
    }
  }

  Future<void> _loadPOData() async {
    if (_selectedPOId == null) return;

    setState(() => _isLoading = true);

    try {
      // Load PO details
      final poRepo = ref.read(poRepositoryProvider);
      final po = await poRepo.getPOById(_selectedPOId!);

      // Load receipt summary (what's already received)
      final grRepo = ref.read(goodsReceiptRepositoryProvider);
      final summaries = await grRepo.getPOReceiptSummary(_selectedPOId!);

      if (po != null && mounted) {
        setState(() {
          _selectedPO = po;
          _items.clear();
          _summaryMap.clear();

          // Build summary map for quick lookup
          for (var summary in summaries) {
            _summaryMap[summary.poItemId] = summary;
          }

          // Create form items
          if (po.items != null) {
            for (var poItem in po.items!) {
              final summary = _summaryMap[poItem.id];
              final remaining = summary?.remainingQuantity ?? poItem.quantity;

              // Only add items that still have remaining quantity
              if (remaining > 0) {
                _items.add(ReceiptItemForm(
                  poItemId: poItem.id,
                  itemName: poItem.itemName,
                  quantityOrdered: poItem.quantity,
                  totalReceived: summary?.totalReceived ?? 0,
                  remainingQuantity: remaining,
                  unit: poItem.unit,
                  quantityController:
                      TextEditingController(text: remaining.toString()),
                  notesController: TextEditingController(),
                ));
              }
            }
          }

          // if items are fully received
          if (_items.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('This PO is fully received. No items to receive.'),
              backgroundColor: Colors.orange,
            ));
            Navigator.pop(context);
          }
        });
      }
    } catch (e) {
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

    // try {
    //   final repo = ref.read(goodsReceiptRepositoryProvider);
    //   final currentUser = ref.read(currentUserProvider);

    //   if (currentUser == null) {
    //     throw Exception('User not logged in');
    //   }

    //   // Prepare items data
    //   final itemsData = _items.map((item) {
    //     return {
    //       'po_item_id': item.poItemId,
    //       'item_name': item.itemName,
    //       'quantity_ordered': item.quantityOrdered,
    //       'quantity_received': int.parse(item.quantityController.text),
    //       'unit': item.unit,
    //       'notes': item.notesController.text.trim().isNotEmpty ? item.notesController.text.trim() : null,
    //     };
    //   }).toList();

    //   // Create receipt
    //   await repo.createReceipt(
    //     poId: _selectedPOId!,
    //     recivedBy: currentUser.id,
    //     items: itemsData,
    //     reciptDate: _receiptDate,
    //     notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
    //   );
    // }
  }

  Widget build(BuildContext build) {
    return Scaffold();
  }
}

// Helper class for item form
class ReceiptItemForm {
  final String poItemId;
  final String itemName;
  final int quantityOrdered;
  final int totalReceived;
  final int remainingQuantity;
  final String unit;
  final TextEditingController quantityController;
  final TextEditingController notesController;

  ReceiptItemForm({
    required this.poItemId,
    required this.itemName,
    required this.quantityOrdered,
    required this.totalReceived,
    required this.remainingQuantity,
    required this.unit,
    required this.quantityController,
    required this.notesController,
  });

  void dispose() {
    quantityController.dispose();
    notesController.dispose();
  }
}
