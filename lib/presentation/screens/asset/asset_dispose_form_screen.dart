import 'package:erp_purchasing_apps/presentation/screens/asset/beacukai_widget.dart';
import 'package:erp_purchasing_apps/presentation/screens/asset/selection_asset_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:erp_purchasing_apps/data/providers/asset_provider.dart';
import 'package:erp_purchasing_apps/data/models/asset_model.dart';

/// ✅ NEW: Form sederhana untuk dispose asset
class AssetDisposeFormScreen extends ConsumerStatefulWidget {
  const AssetDisposeFormScreen({super.key});

  @override
  ConsumerState<AssetDisposeFormScreen> createState() =>
      _AssetDisposeFormScreenState();
}

class _AssetDisposeFormScreenState
    extends ConsumerState<AssetDisposeFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _quantityController = TextEditingController(text: '1');
  final _reasonController = TextEditingController();
  final _receiptNumberController = TextEditingController();
  final _beacukaiDocController = TextEditingController();
  final _beacukaiNoController = TextEditingController();
  final _beacukaiNoAjuController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime? _selectedBeacukaiDate;
  AssetModel? _selectedAsset;

  @override
  void dispose() {
    _quantityController.dispose();
    _reasonController.dispose();
    _receiptNumberController.dispose();
    _beacukaiDocController.dispose();
    _beacukaiNoController.dispose();
    _beacukaiNoAjuController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedAsset == null) {
      _showError('Please select an asset');
      return;
    }

    // ✅ Beacukai REQUIRED untuk disposed
    if (_beacukaiDocController.text.isEmpty ||
        _beacukaiNoController.text.isEmpty ||
        _selectedBeacukaiDate == null) {
      _showError('Beacukai information is required for disposal');
      return;
    }

    _showLoading('Processing disposal...');

    try {
      final quantity = int.parse(_quantityController.text);

      final body = {
        'asset_id': _selectedAsset!.id,
        'quantity': quantity,
        'reason': _reasonController.text,
        if (_receiptNumberController.text.isNotEmpty)
          'receipt_number': _receiptNumberController.text,
        'beacukai_doc': _beacukaiDocController.text,
        'beacukai_tgl': _selectedBeacukaiDate!.toUtc().toIso8601String(),
        'beacukai_no': _beacukaiNoController.text,
        if (_beacukaiNoAjuController.text.isNotEmpty)
          'beacukai_no_aju': _beacukaiNoAjuController.text,
        if (_notesController.text.isNotEmpty) 'notes': _notesController.text,
      };

      await ref.read(assetRepositoryProvider).createTransactionDisposed(body);

      if (!mounted) return;
      Navigator.pop(context); // Close loading
      Navigator.pop(context); // Close form
      ref.invalidate(filteredAssetListProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Asset disposed successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dispose Asset'),
        backgroundColor: Colors.red,
        actions: [
          TextButton.icon(
            onPressed: _submitForm,
            icon: const Icon(Icons.save, color: Colors.white),
            label: const Text(
              'SAVE',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
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
              color: Colors.red.shade50,
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Mark asset as disposed with reason',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 1. Select Asset
            Text(
              '1. Select Asset to Dispose',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            AssetSelectionDropdown(
              selectedAsset: _selectedAsset,
              onAssetSelected: (asset) {
                setState(() {
                  _selectedAsset = asset;
                  if (asset != null) _quantityController.text = '1';
                });
              },
            ),
            const SizedBox(height: 24),

            // 2. Quantity & Reason
            Text(
              '2. Disposal Details',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Quantity
            TextFormField(
              controller: _quantityController,
              decoration: InputDecoration(
                labelText: 'Quantity to Dispose *',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.pin),
                suffixText: _selectedAsset != null
                    ? 'Max: ${_selectedAsset!.quantity}'
                    : null,
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Required';
                final qty = int.tryParse(value);
                if (qty == null || qty <= 0) return 'Invalid';
                if (_selectedAsset != null && qty > _selectedAsset!.quantity) {
                  return 'Max ${_selectedAsset!.quantity}';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Reason
            TextFormField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for Disposal *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
                hintText: 'e.g., Damaged beyond repair, obsolete, etc.',
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Disposal reason is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Receipt Number
            TextFormField(
              controller: _receiptNumberController,
              decoration: const InputDecoration(
                labelText: 'Receipt/Document Number',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.receipt),
                hintText: 'Optional disposal document reference',
              ),
            ),
            const SizedBox(height: 24),

            // 3. Beacukai OUT (REQUIRED)
            Text(
              '3. Beacukai OUT Information *',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            BeacukaiInputFields(
              beacukaiDocController: _beacukaiDocController,
              beacukaiNoController: _beacukaiNoController,
              beacukaiNoAjuController: _beacukaiNoAjuController,
              selectedBeacukaiDate: _selectedBeacukaiDate,
              onDateChanged: (date) =>
                  setState(() => _selectedBeacukaiDate = date),
              isRequired: true, // ✅ Required
            ),
            const SizedBox(height: 24),

            // 4. Additional Notes
            Text(
              '4. Additional Notes',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
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
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Submit Button
            ElevatedButton.icon(
              onPressed: _submitForm,
              icon: const Icon(Icons.delete_forever),
              label: const Text('Mark as Disposed'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.red,
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