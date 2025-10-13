import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:erp_purchasing_apps/data/providers/asset_provider.dart';
import 'package:intl/intl.dart';

class AssetFormScreen extends ConsumerStatefulWidget {
  final String? assetId;

  const AssetFormScreen({
    super.key,
    this.assetId,
  });

  @override
  ConsumerState<AssetFormScreen> createState() => _AssetFormScreenState();
}

class _AssetFormScreenState extends ConsumerState<AssetFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedCategory = 'consumable';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.assetId != null) {
      _loadAssetData();
    } else {
      _quantityController.text = '1';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadAssetData() async {
    setState(() => _isLoading = true);

    try {
      final repository = ref.read(assetRepositoryProvider);
      final asset = await repository.getAssetById(widget.assetId!);

      if (asset != null) {
        _nameController.text = asset.name;
        _quantityController.text = asset.quantity.toString();
        if (asset.purchasePrice != null) {
          _priceController.text = asset.purchasePrice!.toStringAsFixed(0);
        }
        _notesController.text = asset.notes ?? '';
        _selectedCategory = asset.category;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading asset: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  double _calculateTotal() {
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    final price =
        double.tryParse(_priceController.text.replaceAll(',', '')) ?? 0;
    return quantity * price;
  }

  Future<void> _saveAsset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final repository = ref.read(assetRepositoryProvider);

    try {
      final name = _nameController.text.trim();
      final quantity = int.parse(_quantityController.text);
      final price = _priceController.text.isNotEmpty
          ? double.parse(_priceController.text.replaceAll(',', ''))
          : null;
      final notes = _notesController.text.trim();

      if (widget.assetId != null) {
        // Update existing asset
        await repository.updateAsset(
          id: widget.assetId!,
          name: name,
          category: _selectedCategory,
          quantity: quantity,
          purchasePrice: price,
          notes: notes.isEmpty ? null : notes,
        );

        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Asset updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Create new asset
        await repository.createAsset(
          name: name,
          category: _selectedCategory,
          quantity: quantity,
          purchasePrice: price,
          notes: notes.isEmpty ? null : notes,
        );

        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Asset created successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }

      ref.invalidate(assetStreamProvider);
      navigator.pop();
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.assetId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Asset' : 'Add New Asset'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Asset Name
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Asset Name *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.label),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter asset name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Category Selection
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'consumable',
                          child: Row(
                            children: [
                              Icon(Icons.inventory_2,
                                  size: 20, color: Colors.blue),
                              SizedBox(width: 8),
                              Text('Consumable'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'loanable',
                          child: Row(
                            children: [
                              Icon(Icons.devices,
                                  size: 20, color: Colors.purple),
                              SizedBox(width: 8),
                              Text('Loanable'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'saleable',
                          child: Row(
                            children: [
                              Icon(Icons.shopping_bag,
                                  size: 20, color: Colors.green),
                              SizedBox(width: 8),
                              Text('Saleable'),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 8),

                    // Category Description
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 20,
                            color: Colors.blue.shade700,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _getCategoryDescription(_selectedCategory),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Quantity
                    TextFormField(
                      controller: _quantityController,
                      decoration: InputDecoration(
                        labelText: _selectedCategory == 'loanable'
                            ? 'Quantity (units) *'
                            : 'Quantity *',
                        hintText: '1',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.numbers),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter quantity';
                        }
                        final qty = int.tryParse(value);
                        if (qty == null || qty < 1) {
                          return 'Quantity must be at least 1';
                        }
                        return null;
                      },
                      onChanged: (_) => setState(() {}), // Recalculate total
                    ),
                    const SizedBox(height: 16),

                    // Purchase Price (Optional)
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Purchase Price (Optional)',
                        hintText: '',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                        prefixText: 'Rp ',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      onChanged: (_) => setState(() {}), // Recalculate total
                    ),
                    const SizedBox(height: 8),

                    // Subtotal Display
                    if (_priceController.text.isNotEmpty &&
                        _quantityController.text.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade700),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.calculate,
                                  size: 20,
                                  color: Colors.blue.shade700,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Total Asset Value:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'Rp ${NumberFormat('#,###').format(_calculateTotal())}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Notes
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes (Optional)',
                        hintText: 'Additional information...',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.note),
                      ),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 24),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _saveAsset,
                        icon: Icon(isEdit ? Icons.save : Icons.add),
                        label: Text(
                          isEdit ? 'Update Asset' : 'Create Asset',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  String _getCategoryDescription(String category) {
    switch (category) {
      case 'consumable':
        return 'Items that get used up (e.g., pens, paper, printer ink)';
      case 'loanable':
        return 'Items that can be borrowed by users (e.g., laptop, camera, tools)';
      case 'saleable':
        return 'Items for sale or distribution (e.g., finished products)';
      default:
        return '';
    }
  }
}
