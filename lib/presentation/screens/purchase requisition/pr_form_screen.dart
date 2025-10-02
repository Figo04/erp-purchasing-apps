// ===================================
// FILE: lib/presentation/screens/pr/pr_form_screen.dart
// ===================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/providers/pr_provider.dart';
import 'package:erp_purchasing_apps/data/providers/auth_providers.dart';
import 'package:intl/intl.dart';

class PRFormScreen extends ConsumerStatefulWidget {
  final String? prId;

  const PRFormScreen({super.key, this.prId});

  @override
  ConsumerState<PRFormScreen> createState() => _PRFormScreenState();
}

class _PRFormScreenState extends ConsumerState<PRFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final List<PRItemForm> _items = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.prId != null) {
      _loadPR();
    } else {
      // Add one empty item by default
      _addItem();
    }
  }

  Future<void> _loadPR() async {
    try {
      final repo = ref.read(prRepositoryProvider);
      final pr = await repo.getPRById(widget.prId!);

      if (pr != null && mounted) {
        setState(() {
          _notesController.text = pr.notes ?? '';
          _items.clear();
          if (pr.items != null && pr.items!.isNotEmpty) {
            for (var item in pr.items!) {
              _items.add(PRItemForm(
                itemNameController: TextEditingController(text: item.itemName),
                quantityController: TextEditingController(text: item.quantity.toString()),
                unitController: TextEditingController(text: item.unit),
                priceController: TextEditingController(
                  text: item.estimatedPrice?.toString() ?? '',
                ),
                notesController: TextEditingController(text: item.notes ?? ''),
              ));
            }
          } else {
            _addItem();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading PR: $e')),
        );
      }
    }
  }

  void _addItem() {
    setState(() {
      _items.add(PRItemForm(
        itemNameController: TextEditingController(),
        quantityController: TextEditingController(text: '1'),
        unitController: TextEditingController(text: 'pcs'),
        priceController: TextEditingController(),
        notesController: TextEditingController(),
      ));
    });
  }

  void _removeItem(int index) {
    if (_items.length > 1) {
      setState(() {
        _items[index].dispose();
        _items.removeAt(index);
      });
    }
  }

  double _calculateTotal() {
    double total = 0;
    for (var item in _items) {
      final qty = int.tryParse(item.quantityController.text) ?? 0;
      final price = double.tryParse(item.priceController.text) ?? 0;
      total += qty * price;
    }
    return total;
  }

  Future<void> _handleSubmit({bool isDraft = true}) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(prRepositoryProvider);
      final currentUser = ref.read(currentUserProvider);

      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      // Prepare items data
      final itemsData = _items.map((item) {
        return {
          'item_name': item.itemNameController.text.trim(),
          'quantity': int.parse(item.quantityController.text),
          'unit': item.unitController.text.trim(),
          'estimated_price': item.priceController.text.isNotEmpty
              ? double.parse(item.priceController.text)
              : null,
          'notes': item.notesController.text.trim().isNotEmpty
              ? item.notesController.text.trim()
              : null,
        };
      }).toList();

      if (widget.prId == null) {
        // Create new PR
        final pr = await repo.createPR(
          requesterId: currentUser.id,
          items: itemsData,
          notes: _notesController.text.trim().isNotEmpty
              ? _notesController.text.trim()
              : null,
        );

        // Submit if not draft
        if (!isDraft) {
          await repo.submitPR(pr.id);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isDraft ? 'PR saved as draft' : 'PR submitted successfully'),
            ),
          );
          Navigator.pop(context);
        }
      } else {
        // Update existing PR
        await repo.updatePR(
          id: widget.prId!,
          items: itemsData,
          notes: _notesController.text.trim().isNotEmpty
              ? _notesController.text.trim()
              : null,
        );

        // Submit if not draft
        if (!isDraft) {
          await repo.submitPR(widget.prId!);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isDraft ? 'PR updated' : 'PR submitted successfully'),
            ),
          );
          Navigator.pop(context);
        }
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
        title: Text(widget.prId == null ? 'Create PR' : 'Edit PR'),
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
                    // Notes
                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Notes (Optional)',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Items Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Items',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        ElevatedButton.icon(
                          onPressed: _addItem,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add Item'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Items List
                    ..._items.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      return _buildItemCard(index, item);
                    }),

                    const SizedBox(height: 16),

                    // Total
                    Card(
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Estimated:',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              'Rp ${NumberFormat('#,###').format(_calculateTotal())}',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade900,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Buttons
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
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => _handleSubmit(isDraft: true),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save as Draft'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () => _handleSubmit(isDraft: false),
                      child: const Text('Submit PR'),
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

  Widget _buildItemCard(int index, PRItemForm item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Item ${index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (_items.length > 1)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeItem(index),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Item Name
            TextFormField(
              controller: item.itemNameController,
              decoration: const InputDecoration(
                labelText: 'Item Name *',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter item name';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Quantity and Unit
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: item.quantityController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Quantity *',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      if (int.tryParse(value) == null || int.parse(value) <= 0) {
                        return 'Invalid';
                      }
                      return null;
                    },
                    onChanged: (_) => setState(() {}), // Recalculate total
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: item.unitController,
                    decoration: const InputDecoration(
                      labelText: 'Unit *',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Price
            TextFormField(
              controller: item.priceController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                labelText: 'Estimated Price',
                border: OutlineInputBorder(),
                isDense: true,
                prefixText: 'Rp ',
              ),
              onChanged: (_) => setState(() {}), // Recalculate total
            ),
            const SizedBox(height: 12),

            // Item Notes
            TextFormField(
              controller: item.notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                border: OutlineInputBorder(),
                isDense: true,
                alignLabelWithHint: true,
              ),
            ),

            // Subtotal
            if (item.priceController.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Subtotal: Rp ${NumberFormat('#,###').format((int.tryParse(item.quantityController.text) ?? 0) * (double.tryParse(item.priceController.text) ?? 0))}',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Helper class to manage item form controllers
class PRItemForm {
  final TextEditingController itemNameController;
  final TextEditingController quantityController;
  final TextEditingController unitController;
  final TextEditingController priceController;
  final TextEditingController notesController;

  PRItemForm({
    required this.itemNameController,
    required this.quantityController,
    required this.unitController,
    required this.priceController,
    required this.notesController,
  });

  void dispose() {
    itemNameController.dispose();
    quantityController.dispose();
    unitController.dispose();
    priceController.dispose();
    notesController.dispose();
  }
}