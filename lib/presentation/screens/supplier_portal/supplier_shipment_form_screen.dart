// import 'package:erp_purchasing_apps/core/utils/print_qr_helper.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:go_router/go_router.dart';
// import 'package:intl/intl.dart';
// import 'package:qr_flutter/qr_flutter.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:erp_purchasing_apps/data/models/purchase_order_model.dart';
// import 'package:erp_purchasing_apps/data/repositories/po_repository.dart';
// import 'package:erp_purchasing_apps/data/repositories/shipment_repository.dart';
// import 'package:erp_purchasing_apps/data/models/shipment_model.dart';

// class SupplierShipmentFormScreen extends ConsumerStatefulWidget {
//   final String? poId;

//   const SupplierShipmentFormScreen({super.key, this.poId});

//   @override
//   ConsumerState<SupplierShipmentFormScreen> createState() =>
//       _SupplierShipmentFormScreenState();
// }

// class _SupplierShipmentFormScreenState
//     extends ConsumerState<SupplierShipmentFormScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _deliveryNoteController = TextEditingController();
//   final _notesController = TextEditingController();

//   String? _selectedPOId;
//   PurchaseOrderModel? _selectedPO;
//   DateTime _shipmentDate = DateTime.now();
//   bool _isLoading = false;
//   String? _supplierId;

//   final List<ShipmentItemForm> _items = [];
//   ShipmentModel? _createdShipment;

//   @override
//   void initState() {
//     super.initState();

//     // ✅ Pakai addPostFrameCallback
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _loadSupplierInfo();
//       if (widget.poId != null) {
//         _selectedPOId = widget.poId;
//         _loadPOData();
//       }
//     });
//   }

//   Future<void> _loadSupplierInfo() async {
//     try {
//       final supabase = Supabase.instance.client;
//       final userEmail = supabase.auth.currentUser?.email;

//       if (userEmail == null) throw Exception('Not logged in');

//       final supplierResponse = await supabase
//           .from('suppliers')
//           .select('id')
//           .eq('auth_email', userEmail)
//           .single();

//       setState(() {
//         _supplierId = supplierResponse['id'];
//       });
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error loading supplier info: $e')),
//         );
//       }
//     }
//   }

//   Future<void> _loadPOData() async {
//     if (_selectedPOId == null) return;

//     setState(() => _isLoading = true);

//     try {
//       final poRepo = PoRepository();
//       final po = await poRepo.getPOById(_selectedPOId!);

//       if (po != null && mounted) {
//         setState(() {
//           _selectedPO = po;
//           _items.clear();

//           if (po.items != null) {
//             for (var poItem in po.items!) {
//               _items.add(ShipmentItemForm(
//                 poItemId: poItem.id,
//                 itemName: poItem.itemName,
//                 quantityOrdered: poItem.quantity,
//                 unit: poItem.unit,
//                 quantityController:
//                     TextEditingController(text: poItem.quantity.toString()),
//                 notesController: TextEditingController(),
//               ));
//             }
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

//     if (_selectedPOId == null || _supplierId == null) {
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
//       final repo = ShipmentRepository();

//       // Prepare items data
//       final itemsData = _items.map((item) {
//         return {
//           'po_item_id': item.poItemId,
//           'item_name': item.itemName,
//           'quantity_shipped': int.parse(item.quantityController.text),
//           'unit': item.unit,
//           'notes': item.notesController.text.trim().isNotEmpty
//               ? item.notesController.text.trim()
//               : null,
//         };
//       }).toList();

//       // Create shipment
//       final shipment = await repo.createShipment(
//           poId: _selectedPOId!,
//           supplierId: _supplierId!,
//           deliveryNoteNumber: _deliveryNoteController.text.trim(),
//           items: itemsData,
//           shipmentDate: _shipmentDate,
//           notes: _notesController.text.trim().isNotEmpty
//               ? _notesController.text.trim()
//               : null);

//       if (mounted) {
//         setState(() {
//           _createdShipment = shipment;
//         });

//         // Show success dialog with QR
//         _showSuccessDialog(shipment);
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

//   void _showSuccessDialog(ShipmentModel shipment) {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => Dialog(
//         child: ConstrainedBox(
//           constraints: const BoxConstraints(maxWidth: 500),
//           child: Padding(
//             padding: const EdgeInsets.all(24),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 // Success Icon
//                 Container(
//                   padding: const EdgeInsets.all(16),
//                   decoration: BoxDecoration(
//                     color: Colors.green.shade100,
//                     shape: BoxShape.circle,
//                   ),
//                   child: Icon(
//                     Icons.check_circle,
//                     size: 64,
//                     color: Colors.green.shade700,
//                   ),
//                 ),
//                 const SizedBox(height: 24),

//                 // Tittle
//                 Text(
//                   'Shipment Created Successfully!',
//                   style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                         fontWeight: FontWeight.bold,
//                       ),
//                   textAlign: TextAlign.center,
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   shipment.shipmentNumber,
//                   style: TextStyle(
//                       fontSize: 16,
//                       color: Colors.grey.shade700,
//                       fontWeight: FontWeight.w600),
//                 ),
//                 const SizedBox(height: 24),

//                 // QR Code
//                 Container(
//                   padding: const EdgeInsets.all(16),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     border: Border.all(color: Colors.grey.shade300, width: 2),
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Column(
//                     children: [
//                       Text(
//                         'Scan this QR on delivery',
//                         style: TextStyle(
//                           fontSize: 12,
//                           color: Colors.grey.shade600,
//                         ),
//                       ),
//                       const SizedBox(height: 12),
//                       QrImageView(
//                         data: shipment.qrCodeData ?? '',
//                         version: QrVersions.auto,
//                         size: 200.0,
//                         backgroundColor: Colors.white,
//                       ),
//                       const SizedBox(height: 12),
//                       Text(
//                         'Delivery Note: ${shipment.deliveryNoteNumber}',
//                         style: const TextStyle(
//                           fontSize: 12,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(height: 24),

//                 // Info
//                 Container(
//                   padding: const EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: Colors.blue.shade50,
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Row(
//                     children: [
//                       Icon(Icons.info_outline,
//                           color: Colors.blue.shade700, size: 20),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: Text(
//                           'Print this QR code and attach it to the delivery note. Warehouse will scan it on arrival.',
//                           style: TextStyle(
//                             fontSize: 11,
//                             color: Colors.blue.shade700,
//                           ),
//                         ),
//                       )
//                     ],
//                   ),
//                 ),
//                 const SizedBox(height: 24),

//                 // Buttons
//                 Row(children: [
//                   Expanded(
//                     child: OutlinedButton.icon(
//                       onPressed: () async {
//                         await PrintQRHelper.printShipmentQR(context, shipment);
//                       },
//                       icon: const Icon(Icons.print, size: 18),
//                       label: const Text('Print'),
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: ElevatedButton.icon(
//                       onPressed: () {
//                         Navigator.pop(context);
//                         context.go('/supplier/shipments');
//                       },
//                       icon: const Icon(Icons.check, size: 18),
//                       label: const Text('Done'),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.green,
//                         foregroundColor: Colors.white,
//                       ),
//                     ),
//                   )
//                 ])
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: () => context.go('/supplier/dashboard'),
//         ),
//         title: const Text('Create Shipment'),
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
//                     // Selected PO Info
//                     if (_selectedPO != null)
//                       Card(
//                         color: Colors.blue.shade50,
//                         child: Padding(
//                           padding: const EdgeInsets.all(16),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.end,
//                             children: [
//                               Row(
//                                 children: [
//                                   Icon(Icons.shopping_cart,
//                                       color: Colors.blue.shade700),
//                                   const SizedBox(width: 12),
//                                   Expanded(
//                                     child: Column(
//                                       crossAxisAlignment:
//                                           CrossAxisAlignment.start,
//                                       children: [
//                                         const Text(
//                                           'Purchase Order',
//                                           style: TextStyle(
//                                             fontSize: 12,
//                                             fontWeight: FontWeight.w500,
//                                           ),
//                                         ),
//                                         Text(
//                                           _selectedPO!.poNumber,
//                                           style: const TextStyle(
//                                             fontSize: 18,
//                                             fontWeight: FontWeight.bold,
//                                           ),
//                                         )
//                                       ],
//                                     ),
//                                   )
//                                 ],
//                               ),
//                               const Divider(height: 24),
//                               Text(
//                                   'Total: Rp ${NumberFormat('#,###').format(_selectedPO!.totalAmount)}'),
//                               Text(
//                                   'Order Date: ${DateFormat('dd MMM yyyy').format(_selectedPO!.orderDate)}'),
//                             ],
//                           ),
//                         ),
//                       )
//                     else
//                       Card(
//                         child: Padding(
//                           padding: const EdgeInsets.all(16),
//                           child: Text(
//                             'Please select a PO from dashboard',
//                             style: TextStyle(color: Colors.grey.shade600),
//                           ),
//                         ),
//                       ),
//                     const SizedBox(height: 16),

//                     // Delivery Note Number
//                     TextFormField(
//                       controller: _deliveryNoteController,
//                       decoration: const InputDecoration(
//                         labelText: 'Delivery Note Number *',
//                         border: OutlineInputBorder(),
//                         prefixIcon: Icon(Icons.description),
//                         helperText: 'Your internal delivery/invoice number',
//                       ),
//                       validator: (value) {
//                         if (value == null || value.trim().isEmpty) {
//                           return 'Please enter delivery note number';
//                         }
//                         return null;
//                       },
//                     ),
//                     const SizedBox(height: 16),

//                     // Shipment Date
//                     ListTile(
//                       contentPadding: EdgeInsets.zero,
//                       leading: const Icon(Icons.calendar_today),
//                       title: Text(
//                         'Shipment Date: ${DateFormat('dd MMM yyyy').format(_shipmentDate)}',
//                         style: const TextStyle(fontWeight: FontWeight.w600),
//                       ),
//                       trailing: IconButton(
//                         icon: const Icon(Icons.edit_calendar),
//                         onPressed: () async {
//                           final date = await showDatePicker(
//                             context: context,
//                             initialDate: _shipmentDate,
//                             firstDate: DateTime.now()
//                                 .subtract(const Duration(days: 7)),
//                             lastDate:
//                                 DateTime.now().add(const Duration(days: 30)),
//                           );
//                           if (date != null) {
//                             setState(() {
//                               _shipmentDate = date;
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
//                         'Items to Ship',
//                         style: Theme.of(context).textTheme.titleLarge,
//                       ),
//                       const SizedBox(height: 8),
//                       Text(
//                         'Enter the quantity you are shipping for each item',
//                         style: TextStyle(
//                           fontSize: 12,
//                           color: Colors.grey.shade700,
//                         ),
//                       ),
//                       const SizedBox(height: 16),
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
//                       )
//                   ],
//                 ),
//               ),
//             ),

//             // Bottom Button
//             if (!_isLoading && _items.isNotEmpty)
//               Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(color: Colors.white, boxShadow: [
//                   BoxShadow(
//                       color: Colors.grey.shade300,
//                       blurRadius: 4,
//                       offset: const Offset(0, -2))
//                 ]),
//                 child: SizedBox(
//                   width: double.infinity,
//                   height: 48,
//                   child: ElevatedButton.icon(
//                     onPressed: _isLoading ? null : _handleSubmit,
//                     icon: const Icon(Icons.qr_code),
//                     label: const Text('Create Shipment & Generate QR'),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.green,
//                       foregroundColor: Colors.white,
//                     ),
//                   ),
//                 ),
//               )
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildItemCard(int index, ShipmentItemForm item) {
//     return Card(
//       margin: const EdgeInsets.only(bottom: 16),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               item.itemName,
//               style: const TextStyle(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 16,
//               ),
//             ),
//             const SizedBox(height: 12),
//             Row(
//               children: [
//                 Expanded(
//                   child: Container(
//                     padding: const EdgeInsets.all(12),
//                     decoration: BoxDecoration(
//                       color: Colors.grey.shade100,
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           'Ordered',
//                           style: TextStyle(
//                               fontSize: 11, color: Colors.grey.shade600),
//                         ),
//                         Text(
//                           '${item.quantityOrdered} ${item.unit}',
//                           style: const TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         )
//                       ],
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 16),
//                 Expanded(
//                   flex: 2,
//                   child: TextFormField(
//                     controller: item.quantityController,
//                     keyboardType: TextInputType.number,
//                     inputFormatters: [FilteringTextInputFormatter.digitsOnly],
//                     decoration: InputDecoration(
//                       labelText: 'Shipping *',
//                       border: const OutlineInputBorder(),
//                       isDense: true,
//                       suffixText: item.unit,
//                     ),
//                     validator: (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Required';
//                       }
//                       final qty = int.tryParse(value);
//                       if (qty == null || qty <= 0) {
//                         return 'Invalid';
//                       }
//                       if (qty > item.quantityOrdered) {
//                         return 'Max ${item.quantityOrdered}';
//                       }
//                       return null;
//                     },
//                   ),
//                 )
//               ],
//             ),
//             const SizedBox(height: 12),
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

// class ShipmentItemForm {
//   final String poItemId;
//   final String itemName;
//   final int quantityOrdered;
//   final String unit;
//   final TextEditingController quantityController;
//   final TextEditingController notesController;

//   ShipmentItemForm({
//     required this.poItemId,
//     required this.itemName,
//     required this.quantityOrdered,
//     required this.unit,
//     required this.quantityController,
//     required this.notesController,
//   });

//   void dispose() {
//     quantityController.dispose();
//     notesController.dispose();
//   }
// }
