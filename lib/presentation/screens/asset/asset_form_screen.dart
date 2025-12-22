import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:erp_purchasing_apps/data/providers/asset_provider.dart';
import 'package:erp_purchasing_apps/data/providers/division_provider.dart';
import 'package:erp_purchasing_apps/data/providers/category_provider.dart';

class CreateExternalAssetScreen extends ConsumerStatefulWidget {
  const CreateExternalAssetScreen({super.key});

  @override
  ConsumerState<CreateExternalAssetScreen> createState() =>
      _CreateExternalAssetScreenState();
}

class _CreateExternalAssetScreenState
    extends ConsumerState<CreateExternalAssetScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _companyNameController = TextEditingController();
  final _companyAddressController = TextEditingController();
  final _productNameController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _priceController = TextEditingController();
  final _receiptNumberController = TextEditingController();
  final _notesController = TextEditingController();

  // Form state
  String _sourceType = 'purchase'; // purchase or loan
  String _assetType = 'mesin'; // mesin or sparepart
  String? _selectedDivisionId;
  String? _selectedCategoryId;

  @override
  void dispose() {
    _companyNameController.dispose();
    _companyAddressController.dispose();
    _productNameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _receiptNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategoryId == null) {
      _showError('Please select a category');
      return;
    }

    _showLoading('Creating asset...');

    try {
      // Generate asset code
      final now = DateTime.now();
      final assetCode = 'ASSET-EXT-${now.millisecondsSinceEpoch % 100000}';

      // Calculate total
      final quantity = int.parse(_quantityController.text);
      final unitPrice = double.tryParse(_priceController.text);
      final totalAmount = unitPrice != null ? quantity * unitPrice : null;

      // Create external source via repository
      final body = {
        'source_type': _sourceType,
        'company_name': _companyNameController.text,
        'company_address': _companyAddressController.text.isEmpty
            ? null
            : _companyAddressController.text,
        'receipt_number': _receiptNumberController.text.isEmpty
            ? null
            : _receiptNumberController.text,
        'total_amount': totalAmount,
        'transaction_date': DateTime.now().toUtc().toIso8601String(),
        if (_selectedDivisionId != null) 'division_id': _selectedDivisionId,
        'notes': _notesController.text.isEmpty ? null : _notesController.text,
        'items': [
          {
            'item_name': _productNameController.text,
            'category_id': _selectedCategoryId,
            'quantity': quantity,
            'unit': 'pcs',
            if (unitPrice != null) 'unit_price': unitPrice,
            'notes':
                _notesController.text.isEmpty ? null : _notesController.text,
          }
        ],
      };

      // Call API via repository
      await ref.read(assetRepositoryProvider).createExternalSource(body);

      if (!mounted) return;
      Navigator.pop(context); // Close loading
      Navigator.pop(context); // Close form

      // Refresh asset list
      ref.invalidate(filteredAssetListProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Asset created successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading
      _showError(e.toString());
    }
  }

  void _showLoading(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(message),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $message'),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final divisionsAsync = ref.watch(divisionListProvider);
    final categoriesAsync = ref.watch(categoryListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create External Asset'),
        actions: [
          TextButton.icon(
            onPressed: _submitForm,
            icon: const Icon(Icons.save, color: Colors.white),
            label: const Text(
              'SAVE',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Info Card
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Form ini untuk barang yang dibeli/dipinjam BUKAN dari supplier',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // SECTION 1: Company Information
            Text(
              '1. Company Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),

            // Source Type
            DropdownButtonFormField<String>(
              value: _sourceType,
              decoration: const InputDecoration(
                labelText: 'Transaction Type *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business_center),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'purchase',
                  child: Text('Purchase (Dibeli)'),
                ),
                DropdownMenuItem(
                  value: 'loan',
                  child: Text('Loan (Dipinjam)'),
                ),
              ],
              onChanged: (value) => setState(() => _sourceType = value!),
            ),
            const SizedBox(height: 16),

            // Company Name
            TextFormField(
              controller: _companyNameController,
              decoration: const InputDecoration(
                labelText: 'Company Name *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Company name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Company Address
            TextFormField(
              controller: _companyAddressController,
              decoration: const InputDecoration(
                labelText: 'Company Address',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Receipt/Bon Number
            TextFormField(
              controller: _receiptNumberController,
              decoration: const InputDecoration(
                labelText: 'Receipt/Bon Number',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.receipt),
                hintText: 'e.g., INV-2024-001',
              ),
            ),
            const SizedBox(height: 24),

            // SECTION 2: Product Information
            Text(
              '2. Product Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),

            // Product Name
            TextFormField(
              controller: _productNameController,
              decoration: const InputDecoration(
                labelText: 'Product Name *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.inventory),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Product name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Asset Type
            DropdownButtonFormField<String>(
              value: _assetType,
              decoration: const InputDecoration(
                labelText: 'Asset Type *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'mesin',
                  child: Row(
                    children: [
                      Icon(Icons.precision_manufacturing, size: 20),
                      SizedBox(width: 8),
                      Text('Mesin'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'sparepart',
                  child: Row(
                    children: [
                      Icon(Icons.build_circle, size: 20),
                      SizedBox(width: 8),
                      Text('Sparepart'),
                    ],
                  ),
                ),
              ],
              onChanged: (value) => setState(() => _assetType = value!),
            ),
            const SizedBox(height: 16),

            // Asset Category (2.x category from DB)
            categoriesAsync.when(
              data: (categories) {
                final assetCategories =
                    categories.where((c) => c.code.startsWith('2.')).toList();

                return DropdownButtonFormField<String>(
                  value: _selectedCategoryId,
                  decoration: const InputDecoration(
                    labelText: 'Asset Category (2.x) *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.folder),
                  ),
                  items: assetCategories.map((cat) {
                    return DropdownMenuItem(
                      value: cat.id,
                      child: Text('${cat.code} - ${cat.name}'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedCategoryId = value);
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a category';
                    }
                    return null;
                  },
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (error, _) => Text('Error loading categories: $error'),
            ),
            const SizedBox(height: 16),

            // Division
            divisionsAsync.when(
              data: (divisions) {
                final activeDivisions =
                    divisions.where((d) => d.isActive).toList();

                return DropdownButtonFormField<String>(
                  value: _selectedDivisionId,
                  decoration: const InputDecoration(
                    labelText: 'Division',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.business),
                    hintText: 'Select division (optional)',
                  ),
                  items: activeDivisions.map((div) {
                    return DropdownMenuItem(
                      value: div.id,
                      child: Text('${div.divisionCode} - ${div.name}'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedDivisionId = value);
                  },
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (error, _) => Text('Error loading divisions: $error'),
            ),
            const SizedBox(height: 24),

            // SECTION 3: Quantity & Price
            Text(
              '3. Quantity & Price',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Quantity *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.pin),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      final qty = int.tryParse(value);
                      if (qty == null || qty <= 0) {
                        return 'Invalid';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'Unit Price',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                      hintText: '0',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // SECTION 4: Notes
            Text(
              '4. Additional Notes',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
                hintText: 'Additional information...',
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 24),

            // Submit Button
            ElevatedButton.icon(
              onPressed: _submitForm,
              icon: const Icon(Icons.save),
              label: const Text('Create Asset'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}
