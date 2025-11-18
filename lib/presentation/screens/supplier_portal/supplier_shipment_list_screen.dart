// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:go_router/go_router.dart';
// import 'package:intl/intl.dart';
// import 'package:qr_flutter/qr_flutter.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:erp_purchasing_apps/data/models/shipment_model.dart';
// import 'package:erp_purchasing_apps/data/repositories/shipment_repository.dart';

// class SupplierShipmentListScreen extends ConsumerStatefulWidget {
//   const SupplierShipmentListScreen({super.key});

//   @override
//   ConsumerState<SupplierShipmentListScreen> createState() =>
//       _SupplierShipmentListScreenState();
// }

// class _SupplierShipmentListScreenState
//     extends ConsumerState<SupplierShipmentListScreen> {
//   List<ShipmentModel> _shipments = [];
//   bool _isLoading = true;
//   String? _supplierId;
//   String _filterStatus = 'all';

//   @override
//   void initState() {
//     super.initState();

//     // ✅ Pakai addPostFrameCallback
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _loadShipments();
//     });
//   }

//   Future<void> _loadShipments() async {
//     setState(() => _isLoading = true);

//     try {
//       final supabase = Supabase.instance.client;
//       final userEmail = supabase.auth.currentUser?.email;

//       if (userEmail == null) throw Exception('Not logged in');

//       // Get supplier ID
//       final supplierResponse = await supabase
//           .from('suppliers')
//           .select('id')
//           .eq('auth_email', userEmail)
//           .single();

//       _supplierId = supplierResponse['id'];

//       // Get shipments
//       final shipmentRepo = ShipmentRepository();
//       final shipments = await shipmentRepo.getShipmentsBySupplier(_supplierId!);

//       if (mounted) {
//         setState(() {
//           _shipments = shipments;
//           _isLoading = false;
//         });
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error loading shipments: $e')),
//         );
//         setState(() => _isLoading = false);
//       }
//     }
//   }

//   Color _getStatusColor(String status) {
//     switch (status) {
//       case 'pending':
//         return Colors.orange;
//       case 'received':
//         return Colors.green;
//       case 'partial':
//         return Colors.blue;
//       default:
//         return Colors.grey;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final filterefShipments = _filterStatus == 'all'
//         ? _shipments
//         : _shipments.where((s) => s.status == _filterStatus).toList();

//     return Scaffold(
//       appBar: AppBar(
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: () => context.go('/supplier/dashboard'),
//         ),
//         title: const Text('My Shipments'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: _loadShipments,
//           )
//         ],
//       ),
//       body: Column(
//         children: [
//           // Filter Tabs
//           Container(
//             padding: const EdgeInsets.all(8),
//             child: SingleChildScrollView(
//               scrollDirection: Axis.horizontal,
//               child: Row(
//                 children: [
//                   _buildFilterChip('all', 'All', _shipments.length),
//                   const SizedBox(width: 8),
//                   _buildFilterChip(
//                     'pending',
//                     'Pending',
//                     _shipments.where((s) => s.status == 'pending').length,
//                   ),
//                   const SizedBox(width: 8),
//                   _buildFilterChip(
//                     'received',
//                     'Received',
//                     _shipments.where((s) => s.status == 'received').length,
//                   ),
//                   const SizedBox(width: 8),
//                   _buildFilterChip(
//                     'partial',
//                     'Partial',
//                     _shipments.where((s) => s.status == 'partial').length,
//                   ),
//                 ],
//               ),
//             ),
//           ),

//           // Shipment List
//           Expanded(
//             child: _isLoading
//                 ? const Center(child: CircularProgressIndicator())
//                 : filterefShipments.isEmpty
//                     ? Center(
//                         child: Column(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Icon(Icons.local_shipping,
//                                 size: 64, color: Colors.grey.shade400),
//                             const SizedBox(height: 16),
//                             Text(
//                               'No shipments found',
//                               style: TextStyle(
//                                   fontSize: 16, color: Colors.grey.shade600),
//                             ),
//                           ],
//                         ),
//                       )
//                     : ListView.builder(
//                         padding: const EdgeInsets.all(16),
//                         itemCount: filterefShipments.length,
//                         itemBuilder: (context, index) {
//                           final shipment = filterefShipments[index];
//                           final itemCount = shipment.items?.length ?? 0;

//                           return Card(
//                             margin: const EdgeInsets.only(bottom: 12),
//                             child: InkWell(
//                               onTap: () => _showShipmentDetail(shipment),
//                               borderRadius: BorderRadius.circular(12),
//                               child: Padding(
//                                 padding: const EdgeInsets.all(16),
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     // Header
//                                     Row(
//                                       mainAxisAlignment:
//                                           MainAxisAlignment.spaceBetween,
//                                       children: [
//                                         Expanded(
//                                           child: Column(
//                                             crossAxisAlignment:
//                                                 CrossAxisAlignment.start,
//                                             children: [
//                                               Text(
//                                                 shipment.shipmentNumber,
//                                                 style: const TextStyle(
//                                                   fontWeight: FontWeight.bold,
//                                                   fontSize: 16,
//                                                 ),
//                                               ),
//                                               const SizedBox(height: 4),
//                                               if (shipment.poNumber != null)
//                                                 Text(
//                                                   'PO: ${shipment.poNumber}',
//                                                   style: TextStyle(
//                                                     fontSize: 12,
//                                                     color: Colors.grey.shade600,
//                                                   ),
//                                                 )
//                                             ],
//                                           ),
//                                         ),
//                                         Chip(
//                                           label: Text(
//                                             shipment.status.toUpperCase(),
//                                             style:
//                                                 const TextStyle(fontSize: 10),
//                                           ),
//                                           backgroundColor:
//                                               _getStatusColor(shipment.status)
//                                                   .withOpacity(0.2),
//                                           side: BorderSide(
//                                               color: _getStatusColor(
//                                                   shipment.status)),
//                                         )
//                                       ],
//                                     ),
//                                     const Divider(height: 24),

//                                     // Details
//                                     Row(
//                                       children: [
//                                         Icon(Icons.description,
//                                             size: 16,
//                                             color: Colors.grey.shade600),
//                                         const SizedBox(width: 8),
//                                         Text(
//                                           'DN: ${shipment.deliveryNoteNumber}',
//                                           style: const TextStyle(fontSize: 12),
//                                         ),
//                                       ],
//                                     ),
//                                     const SizedBox(height: 4),
//                                     Row(
//                                       children: [
//                                         Icon(Icons.calendar_today,
//                                             size: 16,
//                                             color: Colors.grey.shade600),
//                                         const SizedBox(width: 8),
//                                         Text(
//                                           '$itemCount items',
//                                           style: const TextStyle(fontSize: 12),
//                                         ),
//                                       ],
//                                     ),

//                                     // View QR Button
//                                     if (shipment.status == 'pending') ...[
//                                       const SizedBox(height: 12),
//                                       SizedBox(
//                                         width: double.infinity,
//                                         child: OutlinedButton.icon(
//                                           onPressed: () =>
//                                               _showQRCode(shipment),
//                                           icon: const Icon(Icons.qr_code,
//                                               size: 18),
//                                           label: const Text('View QR Code'),
//                                         ),
//                                       )
//                                     ]
//                                   ],
//                                 ),
//                               ),
//                             ),
//                           );
//                         },
//                       ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildFilterChip(String value, String label, int count) {
//     final isSelected = _filterStatus == value;
//     return FilterChip(
//       label: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Text(label),
//           if (count > 0) ...[
//             const SizedBox(width: 4),
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//               decoration: BoxDecoration(
//                 color: isSelected ? Colors.white : Colors.blue,
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               child: Text(
//                 count.toString(),
//                 style: TextStyle(
//                   fontSize: 10,
//                   color: isSelected ? Colors.blue : Colors.white,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//           ],
//         ],
//       ),
//       selected: isSelected,
//       onSelected: (selected) {
//         setState(() {
//           _filterStatus = value;
//         });
//       },
//     );
//   }

//   void _showShipmentDetail(ShipmentModel shipment) {
//     showDialog(
//       context: context,
//       builder: (context) => Dialog(
//         child: ConstrainedBox(
//           constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
//           child: Padding(
//             padding: const EdgeInsets.all(24),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text(
//                       'Shipment Detail',
//                       style: Theme.of(context)
//                           .textTheme
//                           .titleLarge
//                           ?.copyWith(fontWeight: FontWeight.bold),
//                     ),
//                     IconButton(
//                       icon: const Icon(Icons.close),
//                       onPressed: () => Navigator.pop(context),
//                     )
//                   ],
//                 ),
//                 const Divider(),
//                 const SizedBox(height: 16),
//                 Text(
//                   shipment.shipmentNumber,
//                   style: const TextStyle(
//                       fontSize: 18, fontWeight: FontWeight.bold),
//                 ),
//                 const SizedBox(height: 8),
//                 Text('Status: ${shipment.status.toUpperCase()}'),
//                 if (shipment.poNumber != null) Text('PO: ${shipment.poNumber}'),
//                 Text('Delivery Note: ${shipment.deliveryNoteNumber}'),
//                 Text(
//                     'Date: ${DateFormat('dd MMM yyyy').format(shipment.shipmentDate)}'),
//                 if (shipment.notes != null && shipment.notes!.isNotEmpty)
//                   Text('Notes: ${shipment.notes}'),
//                 const SizedBox(height: 24),
//                 Text(
//                   'Items:',
//                   style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                         fontWeight: FontWeight.bold,
//                       ),
//                 ),
//                 const SizedBox(height: 12),
//                 Expanded(
//                   child: ListView.builder(
//                     shrinkWrap: true,
//                     itemCount: shipment.items?.length ?? 0,
//                     itemBuilder: (context, index) {
//                       final item = shipment.items![index];
//                       return Card(
//                         margin: const EdgeInsets.only(bottom: 8),
//                         child: Padding(
//                           padding: const EdgeInsets.all(12),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 item.itemName,
//                                 style: const TextStyle(
//                                     fontWeight: FontWeight.bold),
//                               ),
//                               const SizedBox(height: 4),
//                               Text(
//                                   'Shipped: ${item.quantityShipped} ${item.unit}'),
//                               if (item.notes != null && item.notes!.isNotEmpty)
//                                 Text(
//                                   'Notes: ${item.notes}',
//                                   style: TextStyle(
//                                       fontSize: 12,
//                                       color: Colors.grey.shade600),
//                                 )
//                             ],
//                           ),
//                         ),
//                       );
//                     },
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 if (shipment.status == 'pending')
//                   SizedBox(
//                     width: double.infinity,
//                     child: ElevatedButton.icon(
//                       onPressed: () {
//                         Navigator.pop(context);
//                         _showQRCode(shipment);
//                       },
//                       icon: const Icon(Icons.qr_code),
//                       label: const Text('View QR Code'),
//                     ),
//                   )
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   void _showQRCode(ShipmentModel shipment) {
//     showDialog(
//       context: context,
//       builder: (context) => Dialog(
//         child: ConstrainedBox(
//           constraints: const BoxConstraints(maxWidth: 400),
//           child: Padding(
//             padding: const EdgeInsets.all(24),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Text(
//                   'QR Code for Delivery',
//                   style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                         fontWeight: FontWeight.bold,
//                       ),
//                 ),
//                 const SizedBox(height: 24),
//                 Container(
//                   padding: const EdgeInsets.all(16),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     border: Border.all(color: Colors.grey.shade300, width: 2),
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Column(
//                     children: [
//                       QrImageView(
//                         data: shipment.qrCodeData ?? '',
//                         version: QrVersions.auto,
//                         size: 250.0,
//                         backgroundColor: Colors.white,
//                       ),
//                       const SizedBox(height: 12),
//                       Text(
//                         shipment.shipmentNumber,
//                         style: const TextStyle(
//                           fontSize: 14,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       Text(
//                         'DN: ${shipment.deliveryNoteNumber}',
//                         style: TextStyle(
//                             fontSize: 12, color: Colors.grey.shade600),
//                       )
//                     ],
//                   ),
//                 ),
//                 const SizedBox(height: 24),
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
//                           'Attach this QR code to delivery note',
//                           style: TextStyle(
//                               fontSize: 11, color: Colors.blue.shade700),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 Row(
//                   children: [
//                     Expanded(
//                       child: OutlinedButton(
//                         onPressed: () {
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             const SnackBar(
//                                 content: Text('Print feature coming soon')),
//                           );
//                         },
//                         child: const Text('Print'),
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: ElevatedButton(
//                         onPressed: () => Navigator.pop(context),
//                         child: const Text('Close'),
//                       ),
//                     )
//                   ],
//                 )
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
