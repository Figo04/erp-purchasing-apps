import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:erp_purchasing_apps/data/providers/payment_provider.dart';
import 'package:erp_purchasing_apps/presentation/screens/payment/payment_form_screen.dart';

class UnpaidLPBsScreen extends ConsumerWidget {
  const UnpaidLPBsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unpaidGroupedAsync = ref.watch(unpaidLPBsGroupedProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Unpaid LPBs by Supplier'),
      ),
      body: unpaidGroupedAsync.when(
        data: (summaries) {
          if (summaries.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 64, color: Colors.green),
                  SizedBox(height: 16),
                  Text(
                    'All invoices have been paid!',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: summaries.length,
            itemBuilder: (context, index) {
              final summary = summaries[index];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange.shade100,
                    child: Text(
                      summary.lpbCount.toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                  title: Text(
                    summary.supplierName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${summary.lpbCount} unpaid LPB(s)'),
                      Text(
                        'Total: Rp ${NumberFormat('#,###').format(summary.totalAmount)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  trailing: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PaymentFormScreen(
                            supplierId: summary.supplierId,
                          ),
                        ),
                      ).then((_) {
                        ref.invalidate(unpaidLPBsGroupedProvider);
                      });
                    },
                    icon: const Icon(Icons.payment, size: 18),
                    label: const Text('Create Payment'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  children: [
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'LPB Details:',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),
                          ...summary.lpbs.map((lpb) {
                            return Card(
                              color: Colors.grey.shade50,
                              child: ListTile(
                                dense: true,
                                leading: const Icon(Icons.receipt, size: 20),
                                title: Text(
                                  lpb.lpbNumber,
                                  style: const TextStyle(fontSize: 13),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'PO: ${lpb.poNumber}',
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                    Text(
                                      'Invoice: ${lpb.invoiceNumber}',
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                    Text(
                                      'Rp ${NumberFormat('#,###').format(lpb.amount)}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Text(
                                  DateFormat('dd/MM/yy').format(lpb.receiptDate),
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(unpaidLPBsGroupedProvider);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}