import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:erp_purchasing_apps/data/providers/po_provider.dart';
import '../../../data/providers/supplier_provider.dart';
import '../../../data/models/purchase_order_model.dart';
import '../../../data/models/supplier_model.dart';
import '../../../data/models/purchase_requisition_model.dart';

/// PO Form Screen - Complete Fixed Version
/// Flow: Kategori → PRs → Supplier → Items → Submit
class POFormScreen extends ConsumerStatefulWidget {
  const POFormScreen({super.key});

  @override
  ConsumerState<POFormScreen> createState() => _POFormScreenState();
}

class _POFormScreenState extends ConsumerState<POFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  DateTime? _expectedDeliveryDate;

  // Step 1: Category selection
  String? _selectedCategoryId;
  String? _selectedCategoryName;
  String? _selectedCategoryCode;

  // Step 2: PR selection (multiple or single)
  bool _isGroupMode = true;
  Set<String> _selectedPRIds = {};
  Map<String, PRWithItems> _availablePRs = {}; // prId -> PRWithItems

  // Step 3: Supplier selection
  String? _selectedSupplierId;
  String? _selectedSupplierName;

  // Step 4: Items with pricing
  List<POItemForm> _items = [];

  bool _isLoading = false;

  @override
  void dispose() {
    _notesController.dispose();
    for (var item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _isGroupMode = !_isGroupMode;
      _selectedPRIds.clear();
      _items.clear();
    });
  }

  void _selectCategory(
      String categoryId, String categoryName, String categoryCode) {
    setState(() {
      _selectedCategoryId = categoryId;
      _selectedCategoryName = categoryName;
      _selectedCategoryCode = categoryCode;
      _selectedPRIds.clear();
      _selectedSupplierId = null;
      _selectedSupplierName = null;
      _items.clear();
    });
  }

  void _togglePRSelection(String prId) {
    setState(() {
      if (_isGroupMode) {
        if (_selectedPRIds.contains(prId)) {
          _selectedPRIds.remove(prId);
        } else {
          _selectedPRIds.add(prId);
        }
      } else {
        _selectedPRIds.clear();
        _selectedPRIds.add(prId);
      }
      _rebuildItemsFromSelection();
    });
  }

  void _selectSupplier(String supplierId, String supplierName) {
    setState(() {
      _selectedSupplierId = supplierId;
      _selectedSupplierName = supplierName;
    });
  }

  void _rebuildItemsFromSelection() {
    // Clear existing items
    _items.clear();

    if (_selectedPRIds.isEmpty) return;

    // Aggregate items from selected PRs
    Map<String, POItemForm> itemMap = {};

    for (var prId in _selectedPRIds) {
      final prWithItems = _availablePRs[prId];
      if (prWithItems == null) continue;

      for (var item in prWithItems.items) {
        String key = '${item.productId}_${item.itemName}_${item.unit}';

        if (itemMap.containsKey(key)) {
          // Sum quantities for same items
          int currentQty = int.parse(itemMap[key]!.quantityController.text);
          itemMap[key]!.quantityController.text =
              (currentQty + item.quantity).toString();
        } else {
          itemMap[key] = POItemForm(
            productId: item.productId,
            itemNameController: TextEditingController(text: item.itemName),
            quantityController:
                TextEditingController(text: item.quantity.toString()),
            unitController: TextEditingController(text: item.unit),
            priceController: TextEditingController(
              text: item.estimatedPrice?.toStringAsFixed(0) ?? '',
            ),
          );
        }
      }
    }
    _items = itemMap.values.toList();
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

  Future<void> _selectDeliveryDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _expectedDeliveryDate = date);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSupplierId == null) {
      _showSnackBar('Please select a supplier', Colors.orange);
      return;
    }

    if (_selectedPRIds.isEmpty) {
      _showSnackBar('Please select at least one PR', Colors.orange);
      return;
    }

    if (_items.isEmpty) {
      _showSnackBar('No items to order', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final items = _items.map((item) {
        return CreatePOItemRequest(
          productId: item.productId,
          itemName: item.itemNameController.text.trim(),
          quantity: int.parse(item.quantityController.text),
          unit: item.unitController.text.trim(),
          unitPrice: double.parse(item.priceController.text),
        );
      }).toList();

      final request = CreatePORequest(
        supplierId: _selectedSupplierId!,
        expectedDeliveryDate: _expectedDeliveryDate,
        prIds: _selectedPRIds.toList(),
        items: items,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      await ref.read(poNotifierProvider.notifier).createPO(request);

      if (mounted) {
        // ⭐ FIX: Navigate FIRST before showing snackbar
        context.go('/po');

        // ⭐ FIX: Show snackbar AFTER navigation with delay
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('PO created successfully'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('Failed to create PO: $e', Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prCategoryGroupingsAsync = ref.watch(prCategoryGroupingsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Create Purchase Order',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: Icon(
                _isGroupMode ? Icons.checklist : Icons.radio_button_checked,
                color: const Color(0xFF1ABC9C),
              ),
              tooltip: _isGroupMode
                  ? 'Switch to Single PR Mode'
                  : 'Switch to Multiple PR Mode',
              onPressed: _toggleMode,
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Mode Indicator
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: _isGroupMode ? Colors.blue.shade50 : Colors.purple.shade50,
              child: Row(
                children: [
                  Icon(
                    _isGroupMode ? Icons.checklist : Icons.radio_button_checked,
                    color: _isGroupMode ? Colors.blue : Colors.purple,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isGroupMode
                        ? 'Group Mode: Select Multiple PRs'
                        : 'Individual Mode: Select 1 PR Only',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _isGroupMode
                          ? Colors.blue.shade900
                          : Colors.purple.shade900,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Step 1: Select Category
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildStepHeader('1', 'Select Category'),
                            const SizedBox(height: 16),
                            prCategoryGroupingsAsync.when(
                              data: (groups) {
                                if (groups.isEmpty) {
                                  return _buildEmptyState(
                                      'No approved PRs available');
                                }

                                return Column(
                                  children: groups.map((group) {
                                    final isSelected =
                                        _selectedCategoryId == group.categoryId;

                                    // ⭐ Extract parent name from category code
                                    String parentName = 'Other';
                                    if (group.categoryCode.startsWith('1')) {
                                      parentName = 'Material';
                                    } else if (group.categoryCode
                                        .startsWith('2')) {
                                      parentName = 'Asset';
                                    } else if (group.categoryCode
                                            .startsWith('3') ||
                                        group.categoryCode.startsWith('4')) {
                                      parentName = 'Logistik';
                                    }

                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      color: isSelected
                                          ? Colors.blue.shade50
                                          : null,
                                      child: InkWell(
                                        onTap: () {
                                          _selectCategory(
                                            group.categoryId,
                                            group.categoryName,
                                            group.categoryCode,
                                          );
                                          // Store available PRs for this category
                                          _availablePRs.clear();
                                          for (var prWithItems in group.prs) {
                                            _availablePRs[prWithItems.pr.id] =
                                                prWithItems;
                                          }
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Row(
                                            children: [
                                              Radio<String>(
                                                value: group.categoryId,
                                                groupValue: _selectedCategoryId,
                                                onChanged: (value) {
                                                  if (value != null) {
                                                    _selectCategory(
                                                      group.categoryId,
                                                      group.categoryName,
                                                      group.categoryCode,
                                                    );
                                                    _availablePRs.clear();
                                                    for (var prWithItems
                                                        in group.prs) {
                                                      _availablePRs[prWithItems
                                                          .pr.id] = prWithItems;
                                                    }
                                                  }
                                                },
                                              ),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    // ⭐ DISPLAY FORMAT: Parent > Child
                                                    Text(
                                                      '$parentName > ${group.categoryName}',
                                                      style: TextStyle(
                                                        fontWeight: isSelected
                                                            ? FontWeight.bold
                                                            : FontWeight.normal,
                                                        fontSize: 15,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      '${group.prs.length} PR(s) available',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors
                                                            .grey.shade600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                );
                              },
                              loading: () => const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                              error: (error, _) =>
                                  _buildErrorState('Error: $error'),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Step 2: Select PRs
                    if (_selectedCategoryId != null) ...[
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildStepHeader(
                                '2',
                                _isGroupMode
                                    ? 'Select PRs (Multiple)'
                                    : 'Select PR (Single)',
                              ),
                              const SizedBox(height: 16),
                              _buildPRSelection(),
                            ],
                          ),
                        ),
                      ),
                    ],

                    // Step 3: Select Supplier
                    if (_selectedPRIds.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildStepHeader('3', 'Select Supplier'),
                              const SizedBox(height: 16),
                              _buildSupplierSelection(),
                            ],
                          ),
                        ),
                      ),
                    ],

                    // Step 4-6: Delivery, Items, Notes, Summary
                    if (_selectedSupplierId != null && _items.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildDeliveryDateCard(),
                      const SizedBox(height: 16),
                      _buildItemsCard(),
                      const SizedBox(height: 16),
                      _buildNotesCard(),
                      const SizedBox(height: 16),
                      _buildSummaryCard(),
                    ],
                  ],
                ),
              ),
            ),

            // Submit Button
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildPRSelection() {
    if (_availablePRs.isEmpty) {
      return _buildEmptyState('No PRs available');
    }

    return Column(
      children: _availablePRs.entries.map((entry) {
        final prId = entry.key;
        final prWithItems = entry.value;
        final isSelected = _selectedPRIds.contains(prId);

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: isSelected
              ? (_isGroupMode ? Colors.blue.shade50 : Colors.purple.shade50)
              : null,
          child: InkWell(
            onTap: () => _togglePRSelection(prId),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  if (_isGroupMode)
                    Checkbox(
                      value: isSelected,
                      onChanged: (_) => _togglePRSelection(prId),
                      activeColor: Colors.blue,
                    )
                  else
                    Radio<String>(
                      value: prId,
                      groupValue: _selectedPRIds.firstOrNull,
                      onChanged: (_) => _togglePRSelection(prId),
                      activeColor: Colors.purple,
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PR: ${prWithItems.pr.prNumber}',
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${prWithItems.items.length} item(s)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSupplierSelection() {
    final suppliersAsync = ref.watch(supplierListProvider);

    return suppliersAsync.when(
      data: (suppliers) {
        if (suppliers.isEmpty) {
          return _buildEmptyState('No suppliers available');
        }

        return DropdownButtonFormField<String>(
          value: _selectedSupplierId,
          decoration: const InputDecoration(
            labelText: 'Supplier *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.business),
          ),
          hint: const Text('Select supplier'),
          items: suppliers.map((supplier) {
            return DropdownMenuItem<String>(
              value: supplier.id,
              child: Text(supplier.name),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              final supplier = suppliers.firstWhere((s) => s.id == value);
              _selectSupplier(value, supplier.name);
            }
          },
          validator: (value) {
            if (value == null) return 'Please select a supplier';
            return null;
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _buildErrorState('Error loading suppliers: $error'),
    );
  }

  Widget _buildDeliveryDateCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepHeader('4', 'Delivery Information'),
            const SizedBox(height: 16),
            InkWell(
              onTap: _selectDeliveryDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Expected Delivery Date',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  _expectedDeliveryDate != null
                      ? DateFormat('dd MMMM yyyy')
                          .format(_expectedDeliveryDate!)
                      : 'Select date',
                  style: TextStyle(
                    color: _expectedDeliveryDate != null
                        ? Colors.black
                        : Colors.grey,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepHeader('5', 'Items & Pricing'),
            const SizedBox(height: 16),
            ..._items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return _buildItemCard(index, item);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(int index, POItemForm item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Item ${index + 1}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: item.itemNameController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Item Name',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Color(0xFFF5F7FA),
              ),
            ),
            const SizedBox(height: 12),
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
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Required';
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
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Unit',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Color(0xFFF5F7FA),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: item.priceController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                labelText: 'Unit Price *',
                border: OutlineInputBorder(),
                prefixText: 'Rp ',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Required';
                if (double.tryParse(value) == null ||
                    double.parse(value) <= 0) {
                  return 'Invalid price';
                }
                return null;
              },
              onChanged: (_) => setState(() {}),
            ),
            if (item.priceController.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Subtotal: ',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      'Rp ${NumberFormat('#,###').format((int.tryParse(item.quantityController.text) ?? 0) * (double.tryParse(item.priceController.text) ?? 0))}',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
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

  Widget _buildNotesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepHeader('6', 'Additional Notes'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                border: OutlineInputBorder(),
                hintText: 'Add any special instructions...',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Summary',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 20),
            _buildSummaryRow('Category:', _selectedCategoryName ?? '-'),
            const Divider(height: 16),
            _buildSummaryRow('Supplier:', _selectedSupplierName ?? '-'),
            const Divider(height: 16),
            _buildSummaryRow('Related PRs:', '${_selectedPRIds.length} PR(s)'),
            const Divider(height: 16),
            _buildSummaryRow('Total Items:', '${_items.length}'),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Amount:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Rp ${NumberFormat('#,###').format(_calculateTotal())}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        Text(value),
      ],
    );
  }

  Widget _buildSubmitButton() {
    final canSubmit = _selectedSupplierId != null &&
        _selectedPRIds.isNotEmpty &&
        _items.isNotEmpty;

    return Container(
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
          onPressed: _isLoading || !canSubmit ? null : _handleSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1ABC9C),
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
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  'Create Purchase Order',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildStepHeader(String number, String title) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFF1ABC9C),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.orange),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(message),
    );
  }
}

/// Helper class for PO item form
class POItemForm {
  final String? productId;
  final TextEditingController itemNameController;
  final TextEditingController quantityController;
  final TextEditingController unitController;
  final TextEditingController priceController;

  POItemForm({
    this.productId,
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
