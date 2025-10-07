import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/providers/po_provider.dart';
import '../../../data/providers/pr_provider.dart';
import '../../../data/providers/supplier_provider.dart';
import '../../../data/providers/auth_providers.dart';
import '../../../data/models/supplier_model.dart';
import 'package:intl/intl.dart';

class POFormScreen extends ConsumerStatefulWidget {
  final String? poId;
  final String? prId; // If creating from approved PR

  const POFormScreen({super.key, this.poId, this.prId});

  @override
  ConsumerState<POFormScreen> createState() => _POFormScreenState();
}

class _POFormScreenState extends ConsumerState<POFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final List<POItemForm> _items = [];
  String? _selectedSupplierId;
  DateTime? _expectedDeliveryDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.poId != null) {
      _loadPO();
    } else if (widget.prId != null) {
      _loadPRAndPopulate();
    } else {
      _addItem();
    }
  }

  Future<void> _loadPO() async {
    try {
      final repo = ref.read(poRepositoryProvider);
      final po = await repo.getPOById(widget.poId!);

      if (po != null && mounted) {
        setState(() {
          _selectedSupplierId = po.supplierId;
          _expectedDeliveryDate = po.expectedDeliveryDate;
          _notesController.text = po.notes ?? '';
          _items.clear();
          if (po.items != null && po.items!.isNotEmpty) {
            for (var item in po.items!) {
              _items.add(POItemForm(
                itemNameController: TextEditingController(text: item.itemName),
                quantityController:
                    TextEditingController(text: item.quantity.toString()),
                unitController: TextEditingController(text: item.unit),
                priceController:
                    TextEditingController(text: item.unitPrice.toString()),
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
          SnackBar(content: Text('Error loading PO: $e')),
        );
      }
    }
  }

  Future<void> _loadPRAndPopulate() async {
    try {
      final repo = ref.read(prRepositoryProvider);
      final pr = await repo.getPRById(widget.prId!);

      if (pr != null && mounted) {
        setState(() {
          _notesController.text =
              'Created from ${pr.prNumber}${pr.notes != null ? '\n${pr.notes}' : ''}';
          _items.clear();
          if (pr.items != null && pr.items!.isNotEmpty) {
            for (var item in pr.items!) {
              _items.add(POItemForm(
                itemNameController: TextEditingController(text: item.itemName),
                quantityController:
                    TextEditingController(text: item.quantity.toString()),
                unitController: TextEditingController(text: item.unit),
                priceController: TextEditingController(
                  text: item.estimatedPrice?.toString() ?? '',
                ),
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
      _items.add(POItemForm(
        itemNameController: TextEditingController(),
        quantityController: TextEditingController(text: '1'),
        unitController: TextEditingController(text: 'pcs'),
        priceController: TextEditingController(),
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

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSupplierId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a supplier'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(poRepositoryProvider);
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
          'unit_price': double.parse(item.priceController.text),
        };
      }).toList();

      if (widget.poId == null) {
        // Create new PO
        await repo.createPO(
          createdBy: currentUser.id,
          prId: widget.prId,
          supplierId: _selectedSupplierId!,
          items: itemsData,
          expectedDeliveryDate: _expectedDeliveryDate,
          notes: _notesController.text.trim().isNotEmpty
              ? _notesController.text.trim()
              : null,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PO created successfully')),
          );
          Navigator.pop(context);
        }
      } else {
        // Update existing PO
        await repo.updatePO(
          id: widget.poId!,
          supplierId: _selectedSupplierId!,
          items: itemsData,
          expectedDeliveryDate: _expectedDeliveryDate,
          notes: _notesController.text.trim().isNotEmpty
              ? _notesController.text.trim()
              : null,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PO updated successfully')),
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
    final supplierList = ref.watch(activeSupplierListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.poId == null ? 'Create PO' : 'Edit PO'),
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
                    // Supplier Dropdown
                    supplierList.when(
                      data: (suppliers) {
                        if (suppliers.isEmpty) {
                          return const Card(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'No active suppliers. Please add suppliers first.',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          );
                        }

                        return DropdownButtonFormField<String>(
                          value: _selectedSupplierId,
                          decoration: const InputDecoration(
                            labelText: 'Select Supplier *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.business),
                          ),
                          items: suppliers.map((supplier) {
                            return DropdownMenuItem(
                              value: supplier.id,
                              child: FittedBox(
                                alignment: Alignment.centerLeft,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      supplier.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    if (supplier.contactName != null)
                                      Text(
                                        supplier.contactName!,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedSupplierId = value;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Please select a supplier';
                            }
                            return null;
                          },
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, stack) =>
                          Text('Error loading suppliers: $error'),
                    ),
                    const SizedBox(height: 16),

                    // Expected Delivery Date
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today),
                      title: Text(
                        _expectedDeliveryDate == null
                            ? 'Expected Delivery Date (Optional)'
                            : 'Expected: ${DateFormat('dd MMM yyyy').format(_expectedDeliveryDate!)}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_expectedDeliveryDate != null)
                            IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _expectedDeliveryDate = null;
                                });
                              },
                            ),
                          IconButton(
                            icon: const Icon(Icons.edit_calendar),
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate:
                                    _expectedDeliveryDate ?? DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now()
                                    .add(const Duration(days: 365)),
                              );
                              if (date != null) {
                                setState(() {
                                  _expectedDeliveryDate = date;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

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
                              'Total Amount:',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              'Rp ${NumberFormat('#,###').format(_calculateTotal())}',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
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

            // Bottom Button
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
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(widget.poId == null ? 'Create PO' : 'Update PO'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(int index, POItemForm item) {
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
                      if (int.tryParse(value) == null ||
                          int.parse(value) <= 0) {
                        return 'Invalid';
                      }
                      return null;
                    },
                    onChanged: (_) => setState(() {}),
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

            // Unit Price
            TextFormField(
              controller: item.priceController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                labelText: 'Unit Price *',
                border: OutlineInputBorder(),
                isDense: true,
                prefixText: 'Rp ',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Required';
                }
                if (double.tryParse(value) == null ||
                    double.parse(value) <= 0) {
                  return 'Invalid';
                }
                return null;
              },
              onChanged: (_) => setState(() {}),
            ),

            // Subtotal
            if (item.priceController.text.isNotEmpty &&
                item.quantityController.text.isNotEmpty)
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

class POItemForm {
  final TextEditingController itemNameController;
  final TextEditingController quantityController;
  final TextEditingController unitController;
  final TextEditingController priceController;

  POItemForm({
    required this.itemNameController,
    required this.quantityController,
    required this.unitController,
    required this.priceController,
  });

  void dispose() {
    itemNameController.dispose();
    quantityController.dispose();
    unitController.dispose();
    priceController.dispose();
  }
}
