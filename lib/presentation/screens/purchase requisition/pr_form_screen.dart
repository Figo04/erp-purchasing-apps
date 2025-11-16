import 'package:erp_purchasing_apps/data/models/division_model.dart';
import 'package:erp_purchasing_apps/data/providers/division_provider.dart';
import 'package:erp_purchasing_apps/data/providers/product_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:erp_purchasing_apps/data/providers/pr_provider.dart';
import 'package:erp_purchasing_apps/data/models/purchase_requisition_model.dart';

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

  String? _selectedDivisionId;
  String _selectedProcessingType = 'material';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.prId != null) {
      _loadPR();
    } else {
      _addItem();
    }
  }

  Future<void> _loadPR() async {
    try {
      final repo = ref.read(prRepositoryProvider);
      final pr = await repo.getPRById(widget.prId!);

      if (pr != null && mounted) {
        setState(() {
          _selectedDivisionId = pr.divisionId;
          _selectedProcessingType = pr.processingType;
          _notesController.text = pr.notes ?? '';
          _items.clear();

          if (pr.items != null && pr.items!.isNotEmpty) {
            for (var item in pr.items!) {
              _items.add(PRItemForm(
                productId: item.productId,
                productName: item.itemName,
                itemNameController: TextEditingController(text: item.itemName),
                quantityController:
                    TextEditingController(text: item.quantity.toString()),
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

    if (_selectedDivisionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select division'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(prNotifierProvider.notifier);

      final items = _items.map((item) {
        return CreatePRItemRequest(
          productId: item.productId!,
          itemName: item.itemNameController.text.trim(),
          quantity: int.parse(item.quantityController.text),
          unit: item.unitController.text.trim(),
          estimatedPrice: item.priceController.text.isNotEmpty
              ? double.parse(item.priceController.text)
              : null,
          notes: item.notesController.text.trim().isEmpty
              ? null
              : item.notesController.text.trim(),
        );
      }).toList();

      if (widget.prId == null) {
        final request = CreatePRRequest(
          divisionId: _selectedDivisionId!,
          processingType: _selectedProcessingType,
          items: items,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );

        await notifier.createPR(request);
      } else {
        final request = UpdatePRRequest(
          items: items
              .map((item) => UpdatePRItemRequest(
                    productId: item.productId,
                    itemName: item.itemName,
                    quantity: item.quantity,
                    unit: item.unit,
                    estimatedPrice: item.estimatedPrice,
                    notes: item.notes,
                  ))
              .toList(),
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );

        await notifier.updatePR(widget.prId!, request);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.prId == null
                  ? 'PR created successfully'
                  : 'PR updated successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
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
    final divisionsAsync = ref.watch(activeDivisionListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.prId == null ? 'Create PR' : 'Edit PR',
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: divisionsAsync.when(
        data: (divisions) => _buildFormContent(divisions),
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading divisions...'),
            ],
          ),
        ),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Error loading divisions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  ref.invalidate(activeDivisionListProvider);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1ABC9C),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormContent(List<DivisionModel> divisions) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // PR Information Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'PR Information',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Division Dropdown
                          DropdownButtonFormField<String>(
                            value: _selectedDivisionId,
                            decoration: const InputDecoration(
                              labelText: 'Division *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.business),
                            ),
                            items: divisions.map((div) {
                              return DropdownMenuItem(
                                value: div.id,
                                child: Text(div.displayName),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => _selectedDivisionId = value);
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Please select division';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Processing Type Dropdown
                          DropdownButtonFormField<String>(
                            value: _selectedProcessingType,
                            decoration: const InputDecoration(
                              labelText: 'Processing Type *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.category),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'material',
                                child: Text('Material (Bahan Produksi)'),
                              ),
                              DropdownMenuItem(
                                value: 'aset',
                                child: Text('Aset (Fix Asset)'),
                              ),
                              DropdownMenuItem(
                                value: 'logistik',
                                child: Text('Logistik (Bahan Penolong)'),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() => _selectedProcessingType = value!);
                            },
                          ),
                          const SizedBox(height: 16),

                          // Notes Field
                          TextFormField(
                            controller: _notesController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Notes (Optional)',
                              border: OutlineInputBorder(),
                              alignLabelWithHint: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Items Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Items',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: _addItem,
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Add Item'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1ABC9C),
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ..._items.asMap().entries.map((entry) {
                            final index = entry.key;
                            final item = entry.value;
                            return _buildItemCard(index, item);
                          }),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Total Estimated
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

          // Bottom Submit Button
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
              height: 50,
              child: ElevatedButton(
                onPressed:
                    _isLoading ? null : () => _handleSubmit(isDraft: false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1ABC9C),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        widget.prId == null ? 'Create PR' : 'Update PR',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(int index, PRItemForm item) {
    final productsAsync = ref.watch(productListProvider);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item Header
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

            // Product Picker
            productsAsync.when(
              data: (products) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: item.productId,
                    decoration: const InputDecoration(
                      labelText: 'Select Product *',
                      border: OutlineInputBorder(),
                      isDense: true,
                      prefixIcon: Icon(Icons.inventory_2),
                      hintText: 'Choose from product list',
                    ),
                    items: products.map((product) {
                      return DropdownMenuItem(
                        value: product.id,
                        child: Text(
                          '${product.name} (${product.productCode})', // ← Single line
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: const TextStyle(fontSize: 14),
                        ),
                      );
                    }).toList(),
                    onChanged: (productId) {
                      setState(() {
                        final selectedProduct = products.firstWhere(
                          (p) => p.id == productId,
                        );

                        item.productId = productId;
                        item.productName = selectedProduct.name;
                        item.itemNameController.text = selectedProduct.name;

                        if (selectedProduct.unit != true) {
                          item.unitController.text = selectedProduct.unit;
                        }
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a product';
                      }
                      return null;
                    },
                  ),

                  // Selected Product Indicator
                  if (item.productId != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle,
                                size: 16, color: Colors.green.shade700),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Product selected: ${item.productName}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              loading: () => const SizedBox(
                height: 60,
                child: Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (err, _) => Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Failed to load products: $err',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade900,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => ref.invalidate(productListProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Item Name (read-only, auto-filled)
            TextFormField(
              controller: item.itemNameController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Item Name',
                border: const OutlineInputBorder(),
                isDense: true,
                filled: true,
                fillColor: Colors.grey.shade100,
                suffixIcon: const Icon(Icons.lock_outline, size: 16),
              ),
            ),
            const SizedBox(height: 12),

            // Quantity and Unit Row
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

            // Estimated Price
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
              onChanged: (_) => setState(() {}),
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

            // Subtotal Display
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

/// Helper class to manage item form controllers
class PRItemForm {
  String? productId;
  String? productName;
  final TextEditingController itemNameController;
  final TextEditingController quantityController;
  final TextEditingController unitController;
  final TextEditingController priceController;
  final TextEditingController notesController;

  PRItemForm({
    this.productId,
    this.productName,
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
