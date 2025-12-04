import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:erp_purchasing_apps/data/models/lpb_model.dart';
import 'package:erp_purchasing_apps/data/providers/lpb_provider.dart';

/// LPB Detail Screen (Desktop)
/// Shows detailed information of a single LPB
class LPBDetailScreen extends ConsumerWidget {
  final LPBModel lpb;

  const LPBDetailScreen({
    super.key,
    required this.lpb,
  });

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getPaymentStatusColor(String paymentStatus) {
    switch (paymentStatus.toLowerCase()) {
      case 'unpaid':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      case 'paid':
        return Colors.green;
      case 'partial':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Future<void> _completeLPB(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete LPB'),
        content: const Text(
          'Are you sure you want to complete this LPB?\n\n'
          'This will update inventory and cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Complete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final success =
          await ref.read(lpbListProvider.notifier).completeLPB(lpb.id);

      if (context.mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${lpb.lpbNumber} completed successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Back to list
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error completing LPB: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
        appBar: AppBar(
          title: Text('LPB: ${lpb.lpbNumber}'),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Card
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      lpb.lpbNumber,
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (lpb.poNumber != null)
                                      Text(
                                        'PO: ${lpb.poNumber}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    if (lpb.shipmentNumber != null)
                                      Text(
                                        'Shipment: ${lpb.shipmentNumber}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Chip(
                                    label: Text(
                                      lpb.status.toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    backgroundColor: _getStatusColor(lpb.status)
                                        .withOpacity(0.2),
                                    side: BorderSide(
                                      color: _getStatusColor(lpb.status),
                                    ),
                                  ),
                                  if (lpb.status == 'completed') ...[
                                    const SizedBox(height: 8),
                                    Chip(
                                      label: Text(
                                        lpb.paymentStatus.toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      backgroundColor: _getPaymentStatusColor(
                                              lpb.paymentStatus)
                                          .withOpacity(0.2),
                                      side: BorderSide(
                                        color: _getPaymentStatusColor(
                                            lpb.paymentStatus),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                          const Divider(height: 32),

                          // Info Grid
                          Row(
                            children: [
                              Expanded(
                                child: _buildInfoColumn(
                                  'Receipt Date',
                                  DateFormat('dd MMMM yyyy')
                                      .format(lpb.receiptDate),
                                  Icons.calendar_today,
                                ),
                              ),
                              Expanded(
                                child: _buildInfoColumn(
                                  'Received By',
                                  lpb.receivedByName ?? '-',
                                  Icons.person,
                                ),
                              ),
                              Expanded(
                                child: _buildInfoColumn(
                                  'Supplier',
                                  lpb.supplierName ?? '-',
                                  Icons.business,
                                ),
                              ),
                              Expanded(
                                child: _buildInfoColumn(
                                  'Created At',
                                  DateFormat('dd MMM yyyy, HH:mm')
                                      .format(lpb.createdAt),
                                  Icons.access_time,
                                ),
                              ),
                            ],
                          ),

                          // Invoice & Paymnet Info (if exists)
                          if (lpb.invoiceNumber != null ||
                              lpb.invoiceAmount != null) ...[
                            const Divider(height: 32),
                            Row(
                              children: [
                                if (lpb.invoiceNumber != null)
                                  Expanded(
                                    child: _buildInfoColumn(
                                      'Invoice Number',
                                      lpb.invoiceNumber!,
                                      Icons.receipt,
                                    ),
                                  ),
                                if (lpb.invoiceAmount != null)
                                  Expanded(
                                    child: _buildInfoColumn(
                                      'Invoice Amount',
                                      'Rp ${NumberFormat('#,###').format(lpb.invoiceAmount)}',
                                      Icons.payment,
                                    ),
                                  ),
                              ],
                            ),
                          ],

                          // ✅ BEACUKAI INFORMATION (NEW)
                          if (lpb.hasBeacukai) ...[
                            const Divider(height: 32),
                            Row(
                              children: [
                                Icon(Icons.description,
                                    size: 20, color: Colors.blue.shade700),
                                const SizedBox(width: 8),
                                Text(
                                  'BEACUKAI INFORMATION',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.blue.shade200,
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  // First Row
                                  Row(
                                    children: [
                                      if (lpb.beacukaiDoc != null)
                                        Expanded(
                                          child: _buildBeacukaiInfoItem(
                                            'Document',
                                            lpb.beacukaiDoc!,
                                            Icons.folder_outlined,
                                          ),
                                        ),
                                      if (lpb.beacukaiDoc != null &&
                                          lpb.beacukaiTgl != null)
                                        const SizedBox(width: 24),
                                      if (lpb.beacukaiTgl != null)
                                        Expanded(
                                          child: _buildBeacukaiInfoItem(
                                            'Date',
                                            DateFormat('dd MMM yyyy')
                                                .format(lpb.beacukaiTgl!),
                                            Icons.calendar_today,
                                          ),
                                        ),
                                    ],
                                  ),
                                  if (lpb.beacukaiNo != null ||
                                      lpb.beacukaiNoAju != null) ...[
                                    const SizedBox(height: 16),
                                    // Second Row
                                    Row(
                                      children: [
                                        if (lpb.beacukaiNo != null)
                                          Expanded(
                                            child: _buildBeacukaiInfoItem(
                                              'Beacukai Number',
                                              lpb.beacukaiNo!,
                                              Icons.numbers,
                                            ),
                                          ),
                                        if (lpb.beacukaiNo != null &&
                                            lpb.beacukaiNoAju != null)
                                          const SizedBox(width: 24),
                                        if (lpb.beacukaiNoAju != null)
                                          Expanded(
                                            child: _buildBeacukaiInfoItem(
                                              'No. Aju',
                                              lpb.beacukaiNoAju!,
                                              Icons.assignment_outlined,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],

                          // Notes (if exists)
                          if (lpb.notes != null && lpb.notes!.isNotEmpty) ...[
                            const Divider(height: 32),
                            Text(
                              'Notes',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                lpb.notes!,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Items Section
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Items Received',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              Chip(
                                label: Text(
                                  '${lpb.items?.length ?? 0} items',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 32),

                          // Items List
                          if (lpb.items == null || lpb.items!.isEmpty)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32),
                                child: Text('No items'),
                              ),
                            )
                          else
                            ...lpb.items!.asMap().entries.map((entry) {
                              final index = entry.key;
                              final item = entry.value;
                              return _buildItemCard(index + 1, item);
                            }),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  if (lpb.status == 'draft')
                    SizedBox(
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: () => _completeLPB(context, ref),
                        icon: const Icon(Icons.check_circle, size: 24),
                        label: const Text(
                          'Complete LPB',
                          style: TextStyle(fontSize: 18),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ));
  }

  Widget _buildInfoColumn(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildItemCard(int number, LPBItemModel item) {
    final hasDiscrepancy = item.hasDiscrepancy;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: hasDiscrepancy ? Colors.orange.shade50 : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item Header
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
                    child: Text(
                      '$number',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
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
                      if (item.productCode != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Code: ${item.productCode}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                      if (item.categoryName != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Category: ${item.categoryName}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (hasDiscrepancy)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'DISCREPANCY',
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

            // Quantity Info
            Row(
              children: [
                Expanded(
                  child: _buildQuantityBox(
                    label: 'ORDERED',
                    quantity: item.quantityOrdered,
                    unit: item.unit,
                    color: Colors.grey,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward, color: Colors.grey.shade400),
                ),
                Expanded(
                  child: _buildQuantityBox(
                    label: 'RECEIVED',
                    quantity: item.quantityReceived,
                    unit: item.unit,
                    color: hasDiscrepancy ? Colors.orange : Colors.green,
                  ),
                ),
              ],
            ),

            // Discrepancy Info
            if (hasDiscrepancy) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber,
                        size: 20, color: Colors.orange.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Difference: ${item.quantityReceived - item.quantityOrdered} ${item.unit} '
                        '(${item.quantityReceived > item.quantityOrdered ? 'MORE' : 'LESS'} than ordered)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Item Notes
            if (item.notes != null && item.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.note, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.notes!,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityBox({
    required String label,
    required int quantity,
    required String unit,
    required MaterialColor color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.shade200, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$quantity $unit',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBeacukaiInfoItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.blue.shade700),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.blue.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
