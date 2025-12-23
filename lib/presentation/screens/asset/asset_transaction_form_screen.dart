import 'package:erp_purchasing_apps/presentation/screens/asset/beacukai_widget.dart';
import 'package:erp_purchasing_apps/presentation/screens/asset/selection_asset_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:erp_purchasing_apps/data/providers/asset_provider.dart';
import 'package:erp_purchasing_apps/data/providers/division_provider.dart';
import 'package:erp_purchasing_apps/data/providers/category_provider.dart';
import 'package:erp_purchasing_apps/data/models/asset_model.dart';

/// Form untuk transaksi asset (IN, OUT, Disposed)
/// Supports 3 modes dengan UI yang berbeda
class AssetTransactionFormScreen extends ConsumerStatefulWidget {
  final String transactionType; // 'in', 'out', 'disposed'

  const AssetTransactionFormScreen({
    super.key,
    required this.transactionType,
  });

  @override
  ConsumerState<AssetTransactionFormScreen> createState() =>
      _AssetTransactionFormScreenState();
}

class _AssetTransactionFormScreenState
    extends ConsumerState<AssetTransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _companyNameController = TextEditingController();
  final _companyAddressController = TextEditingController();
  final _receiptNumberController = TextEditingController();
  final _productNameController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _priceController = TextEditingController();
  final _beacukaiDocController = TextEditingController();
  final _beacukaiNoController = TextEditingController();
  final _beacukaiNoAjuController = TextEditingController();
  final _notesController = TextEditingController();
  final _reasonController = TextEditingController();

  DateTime? _selectedBeacukaiDate;
  String? _transactionSubtype;
  String _assetType = 'mesin';
  String? _selectedDivisionId;
  String? _selectedCategoryId;
  AssetModel? _selectedAsset;

  @override
  void initState() {
    super.initState();
    if (widget.transactionType == 'in') {
      _transactionSubtype = 'purchase';
    } else if (widget.transactionType == 'out') {
      _transactionSubtype = 'sale';
    }
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _companyAddressController.dispose();
    _receiptNumberController.dispose();
    _productNameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _beacukaiDocController.dispose();
    _beacukaiNoController.dispose();
    _beacukaiNoAjuController.dispose();
    _notesController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  bool get isTransactionIn => widget.transactionType == 'in';
  bool get isTransactionOut => widget.transactionType == 'out';
  bool get isTransactionDisposed => widget.transactionType == 'disposed';
  bool get needsCompanyInfo => isTransactionIn || isTransactionOut;
  bool get needsAssetSelection => isTransactionOut || isTransactionDisposed;
  bool get beacukaiRequired => isTransactionOut || isTransactionDisposed;

  String get formTitle {
    switch (widget.transactionType) {
      case 'in':
        return 'Asset Transaction IN';
      case 'out':
        return 'Asset Transaction OUT';
      case 'disposed':
        return 'Dispose Asset';
      default:
        return 'Asset Transaction';
    }
  }

  String get formSubtitle {
    switch (widget.transactionType) {
      case 'in':
        return 'Purchase or Loan In from external company';
      case 'out':
        return 'Sale or Loan Out to external company';
      case 'disposed':
        return 'Mark asset as disposed with reason';
      default:
        return '';
    }
  }

  Color get headerColor {
    switch (widget.transactionType) {
      case 'in':
        return Colors.green;
      case 'out':
        return Colors.orange;
      case 'disposed':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  List<DropdownMenuItem<String>> _getTransactionSubtypeItems() {
    if (isTransactionIn) {
      return const [
        DropdownMenuItem(value: 'purchase', child: Text('Purchase (Dibeli)')),
        DropdownMenuItem(
            value: 'loan_in', child: Text('Loan In (Dipinjam dari luar)')),
      ];
    } else if (isTransactionOut) {
      return const [
        DropdownMenuItem(value: 'sale', child: Text('Sale (Dijual)')),
        DropdownMenuItem(
            value: 'loan_out', child: Text('Loan Out (Dipinjamkan ke luar)')),
      ];
    }
    return [];
  }

  String _getSectionNumber(int baseNumber) {
    if (needsCompanyInfo) return baseNumber.toString();
    return (baseNumber - 1).toString();
  }

  String _getSubmitButtonText() {
    switch (widget.transactionType) {
      case 'in':
        return 'Create Asset Transaction IN';
      case 'out':
        return 'Create Asset Transaction OUT';
      case 'disposed':
        return 'Mark as Disposed';
      default:
        return 'Submit';
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (isTransactionIn && _selectedCategoryId == null) {
      _showError('Please select a category');
      return;
    }

    if (needsAssetSelection && _selectedAsset == null) {
      _showError('Please select an asset');
      return;
    }

    if (beacukaiRequired) {
      if (_beacukaiDocController.text.isEmpty ||
          _beacukaiNoController.text.isEmpty ||
          _selectedBeacukaiDate == null) {
        _showError('Beacukai information is required for this transaction');
        return;
      }
    }

    _showLoading('Processing transaction...');

    try {
      if (isTransactionIn) {
        await _submitTransactionIn();
      } else if (isTransactionOut) {
        await _submitTransactionOut();
      } else if (isTransactionDisposed) {
        await _submitTransactionDisposed();
      }

      if (!mounted) return;
      Navigator.pop(context);
      Navigator.pop(context);
      ref.invalidate(filteredAssetListProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '✓ Transaction ${widget.transactionType.toUpperCase()} completed successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showError(e.toString());
    }
  }

  Future<void> _submitTransactionIn() async {
    final quantity = int.parse(_quantityController.text);
    final unitPrice = _priceController.text.isNotEmpty
        ? double.tryParse(_priceController.text)
        : null;

    final body = {
      'transaction_subtype': _transactionSubtype,
      'company_name': _companyNameController.text,
      if (_companyAddressController.text.isNotEmpty)
        'company_address': _companyAddressController.text,
      if (_receiptNumberController.text.isNotEmpty)
        'receipt_number': _receiptNumberController.text,
      'item_name': _productNameController.text,
      'category_id': _selectedCategoryId!,
      'asset_type': _assetType,
      if (_selectedDivisionId != null) 'division_id': _selectedDivisionId,
      'quantity': quantity,
      if (unitPrice != null) 'unit_price': unitPrice,
      if (_beacukaiDocController.text.isNotEmpty)
        'beacukai_doc': _beacukaiDocController.text,
      if (_selectedBeacukaiDate != null)
        'beacukai_tgl': _selectedBeacukaiDate!.toUtc().toIso8601String(),
      if (_beacukaiNoController.text.isNotEmpty)
        'beacukai_no': _beacukaiNoController.text,
      if (_beacukaiNoAjuController.text.isNotEmpty)
        'beacukai_no_aju': _beacukaiNoAjuController.text,
      if (_notesController.text.isNotEmpty) 'notes': _notesController.text,
    };

    await ref.read(assetRepositoryProvider).createTransactionIn(body);
  }

  Future<void> _submitTransactionOut() async {
    final quantity = int.parse(_quantityController.text);
    final unitPrice = _priceController.text.isNotEmpty
        ? double.tryParse(_priceController.text)
        : null;

    final body = {
      'asset_id': _selectedAsset!.id,
      'transaction_subtype': _transactionSubtype,
      'company_name': _companyNameController.text,
      if (_companyAddressController.text.isNotEmpty)
        'company_address': _companyAddressController.text,
      if (_receiptNumberController.text.isNotEmpty)
        'receipt_number': _receiptNumberController.text,
      'quantity': quantity,
      if (unitPrice != null) 'unit_price': unitPrice,
      'beacukai_doc': _beacukaiDocController.text,
      'beacukai_tgl': _selectedBeacukaiDate!.toUtc().toIso8601String(),
      'beacukai_no': _beacukaiNoController.text,
      if (_beacukaiNoAjuController.text.isNotEmpty)
        'beacukai_no_aju': _beacukaiNoAjuController.text,
      if (_notesController.text.isNotEmpty) 'notes': _notesController.text,
    };

    await ref.read(assetRepositoryProvider).createTransactionOut(body);
  }

  Future<void> _submitTransactionDisposed() async {
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
        title: Text(formTitle),
        backgroundColor: headerColor,
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
            Card(
              color: headerColor.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: headerColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(formSubtitle,
                          style: const TextStyle(fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (needsCompanyInfo) ...[
              Text('1. Company Information',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _transactionSubtype,
                decoration: const InputDecoration(
                  labelText: 'Transaction Type *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.swap_horiz),
                ),
                items: _getTransactionSubtypeItems(),
                onChanged: (value) =>
                    setState(() => _transactionSubtype = value),
                validator: (value) {
                  if (value == null) return 'Please select transaction type';
                  return null;
                },
              ),
              const SizedBox(height: 16),
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
            ],
            Text('${needsCompanyInfo ? '2' : '1'}. Product Information',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (needsAssetSelection) ...[
              AssetSelectionDropdown(
                selectedAsset: _selectedAsset,
                onAssetSelected: (asset) {
                  setState(() {
                    _selectedAsset = asset;
                    if (asset != null) _quantityController.text = '1';
                  });
                },
                forDisposal: isTransactionDisposed,
              ),
              const SizedBox(height: 16),
            ],
            if (isTransactionIn) ...[
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
                    onChanged: (value) =>
                        setState(() => _selectedCategoryId = value),
                    validator: (value) {
                      if (value == null) return 'Please select a category';
                      return null;
                    },
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (error, _) => Text('Error: $error'),
              ),
              const SizedBox(height: 16),
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
                    onChanged: (value) =>
                        setState(() => _selectedDivisionId = value),
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (error, _) => Text('Error: $error'),
              ),
              const SizedBox(height: 24),
            ],
            Text(
                '${needsCompanyInfo ? '3' : '2'}. Quantity ${isTransactionIn ? '& Price' : ''}',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _quantityController,
                    decoration: InputDecoration(
                      labelText: 'Quantity *',
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
                      if (_selectedAsset != null &&
                          qty > _selectedAsset!.quantity) {
                        return 'Max ${_selectedAsset!.quantity}';
                      }
                      return null;
                    },
                  ),
                ),
                if (isTransactionIn) ...[
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
              ],
            ),
            const SizedBox(height: 24),
            Text(
                '${_getSectionNumber(4)}. Beacukai Information ${beacukaiRequired ? '*' : ''}',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            BeacukaiInputFields(
              beacukaiDocController: _beacukaiDocController,
              beacukaiNoController: _beacukaiNoController,
              beacukaiNoAjuController: _beacukaiNoAjuController,
              selectedBeacukaiDate: _selectedBeacukaiDate,
              onDateChanged: (date) =>
                  setState(() => _selectedBeacukaiDate = date),
              isRequired: beacukaiRequired,
            ),
            const SizedBox(height: 24),
            Text(
                '${_getSectionNumber(5)}. ${isTransactionDisposed ? 'Disposal Reason' : 'Additional Notes'}',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextFormField(
              controller:
                  isTransactionDisposed ? _reasonController : _notesController,
              decoration: InputDecoration(
                labelText:
                    isTransactionDisposed ? 'Reason for Disposal *' : 'Notes',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.note),
                hintText: isTransactionDisposed
                    ? 'e.g., Damaged beyond repair'
                    : 'Additional information...',
              ),
              maxLines: 4,
              validator: isTransactionDisposed
                  ? (value) {
                      if (value == null || value.isEmpty) {
                        return 'Disposal reason is required';
                      }
                      return null;
                    }
                  : null,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _submitForm,
              icon: const Icon(Icons.save),
              label: Text(_getSubmitButtonText()),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: headerColor,
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
