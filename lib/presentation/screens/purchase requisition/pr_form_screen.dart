import 'package:erp_purchasing_apps/data/models/division_model.dart';
import 'package:erp_purchasing_apps/data/models/product_model.dart';
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
  String? _selectedSupplierId; // ✅ NEW: Track supplier
  String? _selectedSupplierName;
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
          _notesController.text = pr.notes ?? '';
          _items.clear();

          if (pr.items != null && pr.items!.isNotEmpty) {
            // ✅ Set supplier dari item pertama
            _selectedSupplierId = pr.items!.first.supplierId;
            _selectedSupplierName = pr.items!.first.supplierName;

            for (var item in pr.items!) {
              _items.add(PRItemForm(
                productId: item.productId,
                productName: item.itemName,
                supplierName: item.supplierName,
                unitPrice: item.unitPrice,
                unit: item.unit,
                quantityController: TextEditingController(text: item.quantity.toString()),
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
        quantityController: TextEditingController(text: '1'),
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
      final price = item.unitPrice ?? 0;
      total += qty * price;
    }
    return total;
  }

  /// ✅ NEW: Validate all items from same supplier
  bool _validateSameSupplier() {
    if (_items.isEmpty) return true;
    
    String? firstSupplier;
    for (var item in _items) {
      if (item.productId == null) continue;
      
      if (firstSupplier == null) {
        firstSupplier = item.supplierId;
      } else if (item.supplierId != firstSupplier) {
        return false;
      }
    }
    return true;
  }

  Future<void> _handleSubmit() async {
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

    // ✅ Validate: All items must have product selected
    if (_items.any((item) => item.productId == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select product for all items'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // ✅ Validate: All items must be from same supplier
    if (!_validateSameSupplier()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All items must be from the same supplier!'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(prNotifierProvider.notifier);

      // ✅ SIMPLIFIED: Only send product_id & quantity
      final items = _items.map((item) {
        return CreatePRItemRequest(
          productId: item.productId!,
          quantity: int.parse(item.quantityController.text),
          notes: item.notesController.text.trim().isEmpty
              ? null
              : item.notesController.text.trim(),
        );
      }).toList();

      if (widget.prId == null) {
        final request = CreatePRRequest(
          divisionId: _selectedDivisionId!,
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
                    productId: item.productId!,
                    quantity: item.quantity,
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

                          // ✅ NEW: Supplier Info Display (Read-only)
                          if (_selectedSupplierName != null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.store, color: Colors.blue.shade700),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Supplier',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        Text(
                                          _selectedSupplierName!,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'All items must be from this supplier',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.blue.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
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
                onPressed: _isLoading ? null : _handleSubmit,
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
              data: (products) {
                // ✅ Filter products by selected supplier (if any)
                final filteredProducts = _selectedSupplierId != null
                    ? products.where((p) => p.supplierId == _selectedSupplierId).toList()
                    : products;

                return Column(
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
                      items: filteredProducts.map((product) {
                        return DropdownMenuItem(
                          value: product.id,
                          child: Text(
                            '${product.name} (${product.productCode})',
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

                          // ✅ Set supplier dari product pertama yang dipilih
                          if (_selectedSupplierId == null) {
                            _selectedSupplierId = selectedProduct.supplierId;
                            _selectedSupplierName = selectedProduct.supplierName;
                          }

                          item.productId = productId;
                          item.productName = selectedProduct.name;
                          item.supplierId = selectedProduct.supplierId;
                          item.supplierName = selectedProduct.supplierName;
                          item.unitPrice = selectedProduct.unitPrice;
                          item.unit = selectedProduct.unit;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a product';
                        }
                        return null;
                      },
                    ),

                    // ✅ Selected Product Info
                    if (item.productId != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.check_circle,
                                      size: 16, color: Colors.green.shade700),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      item.productName ?? '',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green.shade900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Supplier: ${item.supplierName}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              Text(
                                'Unit Price: Rp ${NumberFormat('#,###').format(item.unitPrice)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
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

            // Quantity Field
            Row(
              children: [
                Expanded(
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
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                // ✅ Unit (Read-only, auto from product)
                Expanded(
                  child: TextFormField(
                    initialValue: item.unit ?? 'pcs',
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Unit',
                      border: const OutlineInputBorder(),
                      isDense: true,
                      filled: true,
                      fillColor: Colors.grey.shade100,
                    ),
                  ),
                ),
              ],
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

            // ✅ Subtotal Display
            if (item.productId != null && item.unitPrice != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Subtotal:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'Rp ${NumberFormat('#,###').format((int.tryParse(item.quantityController.text) ?? 0) * (item.unitPrice ?? 0))}',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// ✅ UPDATED: Helper class to manage item form
class PRItemForm {
  String? productId;
  String? productName;
  String? supplierId;     // ✅ NEW
  String? supplierName;   // ✅ NEW
  double? unitPrice;      // ✅ NEW (auto from product)
  String? unit;           // ✅ NEW (auto from product)
  final TextEditingController quantityController;
  final TextEditingController notesController;

  PRItemForm({
    this.productId,
    this.productName,
    this.supplierId,
    this.supplierName,
    this.unitPrice,
    this.unit,
    required this.quantityController,
    required this.notesController,
  });

  void dispose() {
    quantityController.dispose();
    notesController.dispose();
  }
}