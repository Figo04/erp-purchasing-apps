import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:erp_purchasing_apps/data/providers/po_provider.dart';
import '../../../data/providers/supplier_provider.dart';
import '../../../data/models/purchase_order_model.dart';
import '../../../data/models/supplier_model.dart';

/// PO Form Screen - Create PO with Flexible Mode
class POFormScreen extends ConsumerStatefulWidget {
  const POFormScreen({super.key});

  @override
  ConsumerState<POFormScreen> createState() => _POFormScreenState();
}

class _POFormScreenState extends ConsumerState<POFormScreen> {  
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  DateTime? _expectedDeliveryDate;
  
  // Mode selection
  bool _isGroupMode = true; // true = group by supplier, false = individual PR
  
  // Group mode
  PRGrouping? _selectedGrouping;
  
  // Individual mode
  List<PRGrouping> _allGroupings = [];
  Set<String> _selectedPRIds = {}; // For selecting individual PRs
  String? _manualSupplierId;
  
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
      _selectedGrouping = null;
      _selectedPRIds.clear();
      _manualSupplierId = null;
      _items.clear();
    });
  }

  void _selectGrouping(PRGrouping grouping) {
    setState(() {
      _selectedGrouping = grouping;
      _selectedPRIds.clear();
      _manualSupplierId = null;
      _items.clear();
      
      // Populate items from PR grouping
      for (var item in grouping.items) {
        _items.add(POItemForm(
          productId: item.productId,
          itemNameController: TextEditingController(text: item.itemName),
          quantityController: TextEditingController(
            text: item.totalQuantity.toString(),
          ),
          unitController: TextEditingController(text: item.unit),
          priceController: TextEditingController(
            text: item.estimatedPrice?.toStringAsFixed(0) ?? '',
          ),
        ));
      }
    });
  }

  void _togglePRSelection(String prId, PRGrouping grouping) {
    setState(() {
      if (_selectedPRIds.contains(prId)) {
        _selectedPRIds.remove(prId);
      } else {
        _selectedPRIds.add(prId);
        _manualSupplierId = grouping.supplierId;
      }
      
      // Rebuild items based on selected PRs
      _rebuildItemsFromSelection();
    });
  }

  void _rebuildItemsFromSelection() {
    _items.clear();
    
    if (_selectedPRIds.isEmpty) {
      _manualSupplierId = null;
      return;
    }

    // Aggregate items from selected PRs
    Map<String, POItemForm> itemMap = {};
    
    for (var grouping in _allGroupings) {
      for (var prId in grouping.prIds) {
        if (_selectedPRIds.contains(prId)) {
          for (var item in grouping.items) {
            String key = '${item.productId}_${item.itemName}_${item.unit}';
            
            if (itemMap.containsKey(key)) {
              // Update quantity
              int currentQty = int.parse(itemMap[key]!.quantityController.text);
              itemMap[key]!.quantityController.text = 
                  (currentQty + item.totalQuantity).toString();
            } else {
              itemMap[key] = POItemForm(
                productId: item.productId,
                itemNameController: TextEditingController(text: item.itemName),
                quantityController: TextEditingController(
                  text: item.totalQuantity.toString(),
                ),
                unitController: TextEditingController(text: item.unit),
                priceController: TextEditingController(
                  text: item.estimatedPrice?.toStringAsFixed(0) ?? '',
                ),
              );
            }
          }
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
    
    // Validation
    if (_isGroupMode && _selectedGrouping == null) {
      _showSnackBar('Please select a supplier group', Colors.orange);
      return;
    }
    
    if (!_isGroupMode && _selectedPRIds.isEmpty) {
      _showSnackBar('Please select at least one PR', Colors.orange);
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
        supplierId: _isGroupMode 
            ? _selectedGrouping!.supplierId 
            : _manualSupplierId!,
        expectedDeliveryDate: _expectedDeliveryDate,
        prIds: _isGroupMode 
            ? _selectedGrouping!.prIds 
            : _selectedPRIds.toList(),
        items: items,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      await ref.read(poNotifierProvider.notifier).createPO(request);

      if (mounted) {
        _showSnackBar('PO created successfully', Colors.green);
        context.go('/po');
      }
    } catch (e) {
      if (mounted) {
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
    final prGroupingsAsync = ref.watch(prGroupingsProvider);

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
          // Mode Toggle Button
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: Icon(
                _isGroupMode ? Icons.view_list : Icons.view_module,
                color: const Color(0xFF1ABC9C),
              ),
              tooltip: _isGroupMode ? 'Switch to Individual Mode' : 'Switch to Group Mode',
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
                    _isGroupMode ? Icons.group_work : Icons.article,
                    color: _isGroupMode ? Colors.blue : Colors.purple,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isGroupMode 
                        ? 'Group Mode: Create PO by Supplier' 
                        : 'Individual Mode: Select Specific PRs',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _isGroupMode ? Colors.blue.shade900 : Colors.purple.shade900,
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
                    // Step 1: Selection
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1ABC9C),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      '1',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _isGroupMode 
                                      ? 'Select Supplier Group'
                                      : 'Select Individual PRs',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            prGroupingsAsync.when(
                              data: (groupings) {
                                _allGroupings = groupings;
                                
                                if (groupings.isEmpty) {
                                  return Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.orange.shade200),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.info_outline, color: Colors.orange),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: Text('No approved PRs available for PO creation'),
                                        ),
                                      ],
                                    ),
                                  );
                                }

                                return _isGroupMode 
                                    ? _buildGroupModeSelection(groupings)
                                    : _buildIndividualModeSelection(groupings);
                              },
                              loading: () => const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                              error: (error, _) => Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('Error: $error'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    if ((_isGroupMode && _selectedGrouping != null) ||
                        (!_isGroupMode && _selectedPRIds.isNotEmpty)) ...[
                      const SizedBox(height: 16),

                      // Step 2: Expected Delivery Date
                      _buildDeliveryDateCard(),

                      const SizedBox(height: 16),

                      // Step 3: Items & Pricing
                      _buildItemsCard(),

                      const SizedBox(height: 16),

                      // Step 4: Notes
                      _buildNotesCard(),

                      const SizedBox(height: 16),

                      // Summary Card
                      _buildSummaryCard(),
                    ],
                  ],
                ),
              ),
            ),

            // Bottom Submit Button
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupModeSelection(List<PRGrouping> groupings) {
    return Column(
      children: groupings.map((grouping) {
        final isSelected = _selectedGrouping?.supplierId == grouping.supplierId;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: isSelected ? const Color(0xFF1ABC9C).withOpacity(0.1) : null,
          child: InkWell(
            onTap: () => _selectGrouping(grouping),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Radio<String>(
                    value: grouping.supplierId,
                    groupValue: _selectedGrouping?.supplierId,
                    onChanged: (_) => _selectGrouping(grouping),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          grouping.supplierName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${grouping.prIds.length} PR(s) | ${grouping.items.length} items',
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

  Widget _buildIndividualModeSelection(List<PRGrouping> groupings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: groupings.map((grouping) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Supplier Header
                Row(
                  children: [
                    Icon(Icons.business, size: 20, color: Colors.grey.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        grouping.supplierName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 16),
                
                // PR List
                ...grouping.prIds.map((prId) {
                  final isSelected = _selectedPRIds.contains(prId);
                  
                  return InkWell(
                    onTap: () => _togglePRSelection(prId, grouping),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.purple.shade50 : null,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value: isSelected,
                            onChanged: (_) => _togglePRSelection(prId, grouping),
                            activeColor: Colors.purple,
                          ),
                          Expanded(
                            child: Text(
                              'PR: $prId',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDeliveryDateCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepHeader('2', 'Delivery Information'),
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
                      ? DateFormat('dd MMMM yyyy').format(_expectedDeliveryDate!)
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
            _buildStepHeader('3', 'Items & Pricing'),
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

  Widget _buildNotesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepHeader('4', 'Additional Notes'),
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
    final supplierName = _isGroupMode 
        ? _selectedGrouping?.supplierName 
        : _allGroupings.firstWhere(
            (g) => g.supplierId == _manualSupplierId,
            orElse: () => _allGroupings.first,
          ).supplierName;
    
    final prCount = _isGroupMode 
        ? _selectedGrouping?.prIds.length 
        : _selectedPRIds.length;

    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Supplier:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(supplierName ?? '-'),
              ],
            ),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Related PRs:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Text('$prCount PR(s)'),
              ],
            ),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Items:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Text('${_items.length}'),
              ],
            ),
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

  Widget _buildSubmitButton() {
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
          onPressed: _isLoading || 
              (_isGroupMode && _selectedGrouping == null) ||
              (!_isGroupMode && _selectedPRIds.isEmpty)
              ? null 
              : _handleSubmit,
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

            // Item Name (readonly)
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
                prefixText: 'Rp ',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Required';
                }
                if (double.tryParse(value) == null || double.parse(value) <= 0) {
                  return 'Invalid price';
                }
                return null;
              },
              onChanged: (_) => setState(() {}),
            ),

            // Subtotal
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