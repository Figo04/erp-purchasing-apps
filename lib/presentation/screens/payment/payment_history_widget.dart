import 'package:flutter/material.dart';
import 'package:erp_purchasing_apps/data/models/payment_model.dart';
import 'package:intl/intl.dart';

class PaymentHistoryWidget extends StatelessWidget {
  final PaymentModel payment;

  const PaymentHistoryWidget({
    super.key,
    required this.payment,
  });

  List<Map<String, dynamic>> _extractHistory() {
    final List<Map<String, dynamic>> history = [];

    // 1. Payment Created
    history.add({
      'icon': Icons.add_circle,
      'color': Colors.blue,
      'title': 'Payment Created',
      'date': payment.createdAt,
      'description':
          'Payment ${payment.paymentNumber} created\nAmount: Rp ${NumberFormat('#,###').format(payment.amount)}',
    });

    // 2. Invoice Number (if exists)
    if (payment.invoiceNumber != null && payment.invoiceNumber!.isNotEmpty) {
      history.add({
        'icon': Icons.receipt,
        'color': Colors.orange,
        'title': 'Invoice Recorded',
        'date': payment.createdAt,
        'description': 'Invoice Number: ${payment.invoiceNumber}',
      });
    }

    // 3. Due Date Set (if exists)
    if (payment.dueDate != null) {
      history.add({
        'icon': Icons.calendar_today,
        'color': Colors.purple,
        'title': 'Due Date Set',
        'date': payment.createdAt,
        'description':
            'Payment due: ${DateFormat('dd MMM yyyy').format(payment.dueDate!)}',
      });
    }

    // 4. Verified (if exists) - FIX: Proper null check
    if (payment.verifiedBy != null && payment.verifiedAt != null) {
      history.add({
        'icon': Icons.verified,
        'color': Colors.blue,
        'title': 'Payment Verified',
        'date': payment.verifiedAt!, // Now safe because we checked null
        'description':
            'Verified by: ${payment.verifiedByName ?? 'Unknown'}\nStatus changed to: SCHEDULED',
      });
    }

    // 5. Payment Processed (if paid) - FIX: Proper null check
    if (payment.status == 'paid') {
      final paidDate = payment.paymentDate ?? payment.updatedAt;
      history.add({
        'icon': Icons.check_circle,
        'color': Colors.green,
        'title': 'Payment Processed',
        'date': paidDate,
        'description': 'Paid by: ${payment.paidByName ?? 'Unknown'}\n'
            'Method: ${_formatMethod(payment.method ?? 'N/A')}\n'
            '${payment.referenceNumber != null && payment.referenceNumber!.isNotEmpty ? 'Ref: ${payment.referenceNumber}' : ''}',
      });
    }

    // 6. Payment Cancelled (if cancelled)
    if (payment.status == 'cancelled') {
      history.add({
        'icon': Icons.cancel,
        'color': Colors.red,
        'title': 'Payment Cancelled',
        'date': payment.updatedAt,
        'description': 'Payment has been cancelled',
      });
    }

    // 7. Notes (if exists) - Extract actions from notes
    if (payment.notes != null && payment.notes!.isNotEmpty) {
      final notesLines = payment.notes!.split('\n');
      for (var line in notesLines) {
        if (line.trim().isEmpty) continue;

        if (line.contains('[STATUS CHANGE]')) {
          history.add({
            'icon': Icons.swap_horiz,
            'color': Colors.orange,
            'title': 'Status Changed',
            'date': payment.updatedAt,
            'description': line.replaceAll('[STATUS CHANGE]', '').trim(),
          });
        } else if (line.contains('[UPDATED]')) {
          history.add({
            'icon': Icons.edit,
            'color': Colors.blue,
            'title': 'Payment Updated',
            'date': payment.updatedAt,
            'description': line.replaceAll('[UPDATED]', '').trim(),
          });
        }
      }
    }

    // 8. Last Updated (only if significantly different from created)
    final timeDiff = payment.updatedAt.difference(payment.createdAt).inSeconds;
    if (timeDiff > 5) {
      history.add({
        'icon': Icons.update,
        'color': Colors.grey,
        'title': 'Last Updated',
        'date': payment.updatedAt,
        'description': 'Payment information updated',
      });
    }

    // Sort by date (newest first)
    history.sort((a, b) {
      final dateA = a['date'] as DateTime;
      final dateB = b['date'] as DateTime;
      return dateB.compareTo(dateA);
    });

    return history;
  }

  String _formatMethod(String method) {
    switch (method.toLowerCase()) {
      case 'bank_transfer':
        return 'Bank Transfer';
      case 'cash':
        return 'Cash';
      case 'e_wallet':
        return 'E-Wallet';
      case 'check':
        return 'Check';
      default:
        return method;
    }
  }

  @override
  Widget build(BuildContext context) {
    final history = _extractHistory();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Payment History',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (history.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No history available',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: history.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = history[index];
                  return _buildHistoryItem(
                    icon: item['icon'] as IconData,
                    color: item['color'] as Color,
                    title: item['title'] as String,
                    date: item['date'] as DateTime,
                    description: item['description'] as String,
                    isFirst: index == 0,
                    isLast: index == history.length - 1,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem({
    required IconData icon,
    required Color color,
    required String title,
    required DateTime date,
    required String description,
    required bool isFirst,
    required bool isLast,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline dot & line
        Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 12),

        // Content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('dd MMM yyyy, HH:mm').format(date),
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              if (description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
