// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:intl/intl.dart';
// import 'package:erp_purchasing_apps/data/providers/goods_receipt_provider.dart';
// import 'package:erp_purchasing_apps/data/providers/po_provider.dart';
// import 'package:erp_purchasing_apps/data/providers/auth_providers.dart';
// import 'package:erp_purchasing_apps/data/models/purchase_order_model.dart';
// import 'package:erp_purchasing_apps/data/models/goods_receipt_model.dart';

// class GoodsReceiptFormScreen extends ConsumerStatefulWidget {
//   final String? poId;

//   const GoodsReceiptFormScreen({super.key, this.poId});

//   @override
//   ConsumerState<GoodsReceiptFormScreen> createState() =>
//       _GoodsReceiptFormScreenState();
// }

// class _GoodsReceiptFormScreenState
//     extends ConsumerState<GoodsReceiptFormScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _notesController = TextEditingController();

//   String? _selectedPOId;
//   PurchaseOrderModel? _selectedPO;
//   DateTime _receiptDate = DateTime.now();
//   bool _isLoading = false;

//   final List<ReceiptItemForm> _items = [];
//   final Map<String, POItemReceiptSummary> _summaryMap = {};

//   @override
//   void initState() {
//     super.initState();
//     if (widget.poId != null) {
//       _selectedPOId = widget.poId;
//       _loadPOData();
//     }
//   }

//   Future<void> _loadPOData() async {
//     if (_selectedPOId == null) return;

//     setState(() => _isLoading = true);

//     try {
//       // Load PO details
//       final poRepo = ref.read(poRepositoryProvider);
//       final po = await poRepo.getPOById(_selectedPOId!);

//       // Load receipt summary (what's already received)
//       final grRepo = ref.read(goodsReceiptRepositoryProvider);
//       final summaries = await grRepo.getPOReceiptSummary(_selectedPOId!);

//       if (po != null && mounted) {
//         setState(() {
//           _selectedPO = po;
//           _items.clear();
//           _summaryMap.clear();

//           // Build summary map for quick lookup
//           for (var summary in summaries) {
//             _summaryMap[summary.poItemId] = summary;
//           }

//           // Create form items
//           if (po.items != null) {
//             for (var poItem in po.items!) {
//               final summary = _summaryMap[poItem.id];
//               final remaining = summary?.remainingQuantity ?? poItem.quantity;

//               // Only add items that still have remaining quantity
//               if (remaining > 0) {
//                 _items.add(ReceiptItemForm(
//                   poItemId: poItem.id,
//                   itemName: poItem.itemName,
//                   quantityOrdered: poItem.quantity,
//                   totalReceived: summary?.totalReceived ?? 0,
//                   remainingQuantity: remaining,
//                   unit: poItem.unit,
//                   quantityController:
//                       TextEditingController(text: remaining.toString()),
//                   notesController: TextEditingController(),
//                 ));
//               }
//             }
//           }

//           // if items are fully received
//           if (_items.isEmpty) {
//             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
//               content: Text('This PO is fully received. No items to receive.'),
//               backgroundColor: Colors.orange,
//             ));
//             Navigator.pop(context);
//           }
//         });
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error loading PO: $e')),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() => _isLoading = false);
//       }
//     }
//   }

//   Future<void> _handleSubmit() async {
//     if (!_formKey.currentState!.validate()) return;

//     if (_selectedPOId == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Please select a PO'),
//           backgroundColor: Colors.red,
//         ),
//       );
//       return;
//     }

//     setState(() => _isLoading = true);

//     try {
//       final repo = ref.read(goodsReceiptRepositoryProvider);
//       final currentUser = ref.read(currentUserProvider);

//       if (currentUser == null) {
//         throw Exception('User not logged in');
//       }

//       // Prepare items data
//       final itemsData = _items.map((item) {
//         return {
//           'po_item_id': item.poItemId,
//           'item_name': item.itemName,
//           'quantity_ordered': item.quantityOrdered,
//           'quantity_received': int.parse(item.quantityController.text),
//           'unit': item.unit,
//           'notes': item.notesController.text.trim().isNotEmpty
//               ? item.notesController.text.trim()
//               : null,
//         };
//       }).toList();

//       // Create receipt
//       await repo.createReceipt(
//         poId: _selectedPOId!,
//         receivedBy: currentUser.id,
//         items: itemsData,
//         receiptDate: _receiptDate,
//         notes: _notesController.text.trim().isNotEmpty
//             ? _notesController.text.trim()
//             : null,
//       );

//       // Update PO status fully recceived
//       await repo.updatePOStatusIfFullyReceived(_selectedPOId!);

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Receipt created successfully')),
//         );
//         Navigator.pop(context);
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() => _isLoading = false);
//       }
//     }
//   }

//   @override
//   void dispose() {
//     _notesController.dispose();
//     for (var item in _items) {
//       item.dispose();
//     }
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext build) {
//     final poStream = ref.watch(poStreamProvider);

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Create Goods Receipt (LPB)'),
//       ),
//       body: Form(
//         key: _formKey,
//         child: Column(
//           children: [
//             Expanded(
//               child: SingleChildScrollView(
//                 padding: const EdgeInsets.all(16),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.stretch,
//                   children: [
//                     // PO Selector
//                     if (_selectedPOId == null)
//                       poStream.when(
//                         data: (pos) {
//                           // Filter only approved POs
//                           final approvedPOs = pos
//                               .where((po) =>
//                                   po.status == 'approved' ||
//                                   po.status == 'received')
//                               .toList();

//                           if (approvedPOs.isEmpty) {
//                             return const Card(
//                               child: Padding(
//                                 padding: EdgeInsets.all(16),
//                                 child: Text(
//                                   'No approved POs available.',
//                                   style: TextStyle(color: Colors.red),
//                                 ),
//                               ),
//                             );
//                           }

//                           return DropdownButtonFormField<String>(
//                             decoration: const InputDecoration(
//                               labelText: 'Select PO *',
//                               border: OutlineInputBorder(),
//                               prefixIcon: Icon(Icons.shopping_bag),
//                             ),
//                             items: approvedPOs.map((po) {
//                               return DropdownMenuItem(
//                                 value: po.id,
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   mainAxisSize: MainAxisSize.min,
//                                   children: [
//                                     Text(
//                                       po.poNumber,
//                                       style: const TextStyle(
//                                           fontWeight: FontWeight.bold),
//                                     ),
//                                     Text(
//                                       'Total: Rp ${NumberFormat('#,###').format(po.totalAmount)}',
//                                       style: const TextStyle(fontSize: 12),
//                                     )
//                                   ],
//                                 ),
//                               );
//                             }).toList(),
//                             onChanged: (value) {
//                               setState(() {
//                                 _selectedPOId = value;
//                               });
//                               _loadPOData();
//                             },
//                             validator: (value) {
//                               if (value == null) {
//                                 return 'Please Select a PO';
//                               }
//                               return null;
//                             },
//                           );
//                         },
//                         loading: () =>
//                             const Center(child: CircularProgressIndicator()),
//                         error: (error, stackTrace) =>
//                             Text('Error loading POs: $error'),
//                       )
//                     else
//                       Card(
//                         color: Colors.blue.shade50,
//                         child: Padding(
//                           padding: const EdgeInsets.all(16),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Row(
//                                 mainAxisAlignment:
//                                     MainAxisAlignment.spaceBetween,
//                                 children: [
//                                   const Text(
//                                     'Selected PO:',
//                                     style:
//                                         TextStyle(fontWeight: FontWeight.bold),
//                                   ),
//                                   if (_selectedPO != null)
//                                     Chip(
//                                       label: Text(
//                                           _selectedPO!.status.toUpperCase()),
//                                       backgroundColor: Colors.blue.shade100,
//                                     )
//                                 ],
//                               ),
//                               if (_selectedPO != null) ...[
//                                 const SizedBox(height: 8),
//                                 Text(
//                                   _selectedPO!.poNumber,
//                                   style: const TextStyle(
//                                     fontSize: 18,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                                 Text(
//                                     'Total: rp ${NumberFormat('#,###').format(_selectedPO!.totalAmount)}'),
//                                 Text(
//                                     'Order Date: ${DateFormat('dd MMM yyyy').format(_selectedPO!.orderDate)}'),
//                               ]
//                             ],
//                           ),
//                         ),
//                       ),
//                     const SizedBox(height: 16),

//                     // Receipt Datet
//                     ListTile(
//                       contentPadding: EdgeInsets.zero,
//                       leading: const Icon(Icons.calendar_today),
//                       title: Text(
//                         'Receipt Date: ${DateFormat('dd MMM yyyy').format(_receiptDate)}',
//                         style: const TextStyle(fontWeight: FontWeight.w600),
//                       ),
//                       trailing: IconButton(
//                         icon: const Icon(Icons.edit_calendar),
//                         onPressed: () async {
//                           final date = await showDatePicker(
//                             context: context,
//                             initialDate: _receiptDate,
//                             firstDate: DateTime.now()
//                                 .subtract(const Duration(days: 30)),
//                             lastDate: DateTime.now(),
//                           );
//                           if (date != null) {
//                             setState(() {
//                               _receiptDate = date;
//                             });
//                           }
//                         },
//                       ),
//                     ),
//                     const SizedBox(height: 16),

//                     // Notes
//                     TextFormField(
//                       controller: _notesController,
//                       maxLines: 3,
//                       decoration: const InputDecoration(
//                         labelText: 'Notes (Optional)',
//                         border: OutlineInputBorder(),
//                         alignLabelWithHint: true,
//                       ),
//                     ),
//                     const SizedBox(height: 24),

//                     // Items Section
//                     if (_items.isNotEmpty) ...[
//                       Text(
//                         'Items to Receive',
//                         style: Theme.of(context).textTheme.titleLarge,
//                       ),
//                       const SizedBox(height: 8),
//                       Text(
//                         'Enter the quantity received for each item. You can receive partial quantities.',
//                         style: TextStyle(
//                           fontSize: 12,
//                           color: Colors.grey.shade700,
//                         ),
//                       ),
//                       const SizedBox(height: 16),

//                       // Items List
//                       ..._items.asMap().entries.map((entry) {
//                         final index = entry.key;
//                         final item = entry.value;
//                         return _buildItemCard(index, item);
//                       }),
//                     ],

//                     if (_isLoading)
//                       const Center(
//                         child: Padding(
//                           padding: EdgeInsets.all(24),
//                           child: CircularProgressIndicator(),
//                         ),
//                       ),
//                   ],
//                 ),
//               ),
//             ),

//             // Bottom Button
//             if (!_isLoading && _items.isNotEmpty)
//               Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.grey.shade300,
//                       blurRadius: 4,
//                       offset: const Offset(0, -2),
//                     ),
//                   ],
//                 ),
//                 child: SizedBox(
//                   width: double.infinity,
//                   height: 48,
//                   child: ElevatedButton(
//                     onPressed: _isLoading ? null : _handleSubmit,
//                     child: const Text('Create Receipt'),
//                   ),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildItemCard(int index, ReceiptItemForm item) {
//     final receivedPercentage =
//         (item.totalReceived / item.quantityOrdered * 100).toStringAsFixed(1);

//     return Card(
//       margin: const EdgeInsets.only(bottom: 16),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Item Header
//             Row(
//               children: [
//                 Expanded(
//                   child: Text(
//                     item.itemName,
//                     style: const TextStyle(
//                       fontWeight: FontWeight.bold,
//                       fontSize: 16,
//                     ),
//                   ),
//                 ),
//                 if (item.totalReceived > 0)
//                   Container(
//                     padding:
//                         const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                     decoration: BoxDecoration(
//                       color: Colors.orange.shade100,
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: Text(
//                       'Partial: $receivedPercentage%',
//                       style: TextStyle(
//                         fontSize: 10,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.orange.shade900,
//                       ),
//                     ),
//                   ),
//               ],
//             ),
//             const SizedBox(height: 12),

//             // Progress Info
//             Container(
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: Colors.grey.shade100,
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Column(
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(
//                         'Ordered:',
//                         style: TextStyle(color: Colors.grey.shade700),
//                       ),
//                       Text(
//                         '${item.quantityOrdered} ${item.unit}',
//                         style: const TextStyle(fontWeight: FontWeight.bold),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 4),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(
//                         'Already Received:',
//                         style: TextStyle(color: Colors.grey.shade700),
//                       ),
//                       Text(
//                         '${item.totalReceived} ${item.unit}',
//                         style: TextStyle(
//                           fontWeight: FontWeight.bold,
//                           color: item.totalReceived > 0
//                               ? Colors.blue
//                               : Colors.grey,
//                         ),
//                       ),
//                     ],
//                   ),
//                   const Divider(height: 16),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(
//                         'Remaining:',
//                         style: TextStyle(
//                           color: Colors.grey.shade700,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       Text(
//                         '${item.remainingQuantity} ${item.unit}',
//                         style: const TextStyle(
//                           fontWeight: FontWeight.bold,
//                           color: Colors.green,
//                           fontSize: 16,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 16),

//             // Receive Quantity Input
//             Row(
//               children: [
//                 Expanded(
//                   child: TextFormField(
//                     controller: item.quantityController,
//                     keyboardType: TextInputType.number,
//                     inputFormatters: [FilteringTextInputFormatter.digitsOnly],
//                     decoration: InputDecoration(
//                       labelText: 'Receive Now *',
//                       border: const OutlineInputBorder(),
//                       isDense: true,
//                       suffixText: item.unit,
//                       helperText: 'Max: ${item.remainingQuantity}',
//                     ),
//                     validator: (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Required';
//                       }
//                       final qty = int.tryParse(value);
//                       if (qty == null || qty <= 0) {
//                         return 'Invalid quantity';
//                       }
//                       if (qty > item.remainingQuantity) {
//                         return 'Max ${item.remainingQuantity}';
//                       }
//                       return null;
//                     },
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 ElevatedButton(
//                   onPressed: () {
//                     setState(() {
//                       item.quantityController.text =
//                           item.remainingQuantity.toString();
//                     });
//                   },
//                   style: ElevatedButton.styleFrom(
//                     padding: const EdgeInsets.symmetric(
//                         horizontal: 12, vertical: 16),
//                   ),
//                   child: const Text('Full'),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),

//             // Item Notes
//             TextFormField(
//               controller: item.notesController,
//               maxLines: 2,
//               decoration: const InputDecoration(
//                 labelText: 'Item Notes (Optional)',
//                 border: OutlineInputBorder(),
//                 isDense: true,
//                 alignLabelWithHint: true,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // Helper class for item form
// class ReceiptItemForm {
//   final String poItemId;
//   final String itemName;
//   final int quantityOrdered;
//   final int totalReceived;
//   final int remainingQuantity;
//   final String unit;
//   final TextEditingController quantityController;
//   final TextEditingController notesController;

//   ReceiptItemForm({
//     required this.poItemId,
//     required this.itemName,
//     required this.quantityOrdered,
//     required this.totalReceived,
//     required this.remainingQuantity,
//     required this.unit,
//     required this.quantityController,
//     required this.notesController,
//   });

//   void dispose() {
//     quantityController.dispose();
//     notesController.dispose();
//   }
// }
