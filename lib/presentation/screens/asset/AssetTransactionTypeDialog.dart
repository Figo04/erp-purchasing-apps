import 'package:flutter/material.dart';

/// Dialog untuk memilih tipe transaksi asset
/// Digunakan sebelum membuka form transaksi
class AssetTransactionTypeDialog extends StatelessWidget {
  final Function(String transactionType) onTypeSelected;

  const AssetTransactionTypeDialog({
    super.key,
    required this.onTypeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.swap_horiz, color: Colors.blue),
          SizedBox(width: 8),
          Text('Select Transaction Type'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Barang MASUK (IN)
            _TransactionTypeCard(
              icon: Icons.input,
              iconColor: Colors.green,
              title: '📥 Barang Masuk (IN)',
              subtitle: 'Purchase or Loan In from external company',
              transactionType: 'in',
              onTap: () {
                Navigator.pop(context);
                onTypeSelected('in');
              },
            ),
            const SizedBox(height: 12),

            // Barang KELUAR (OUT)
            _TransactionTypeCard(
              icon: Icons.output,
              iconColor: Colors.orange,
              title: '📤 Barang Keluar (OUT)',
              subtitle: 'Sale or Loan Out to external company',
              transactionType: 'out',
              onTap: () {
                Navigator.pop(context);
                onTypeSelected('out');
              },
            ),
            const SizedBox(height: 12),

            // DISPOSED
            _TransactionTypeCard(
              icon: Icons.delete_forever,
              iconColor: Colors.red,
              title: '🗑️ Disposed',
              subtitle: 'Mark existing asset as disposed',
              transactionType: 'disposed',
              onTap: () {
                Navigator.pop(context);
                onTypeSelected('disposed');
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

/// Card untuk setiap tipe transaksi
class _TransactionTypeCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String transactionType;
  final VoidCallback onTap;

  const _TransactionTypeCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.transactionType,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),

              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Helper function untuk show dialog
void showAssetTransactionTypeDialog({
  required BuildContext context,
  required Function(String transactionType) onTypeSelected,
}) {
  showDialog(
    context: context,
    builder: (ctx) => AssetTransactionTypeDialog(
      onTypeSelected: onTypeSelected,
    ),
  );
}