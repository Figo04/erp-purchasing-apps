import 'package:erp_purchasing_apps/data/repositories/po_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:erp_purchasing_apps/data/providers/asset_provider.dart';

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

        scaffoldMessenger.showSnackBar(const SnackBar(
          content: Text('Asset updated successfully'),
          backgroundColor: Colors.white,
        ));
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
      scaffoldMessenger.showSnackBar(SnackBar(
        content: Text('Failed: ${e.toString()}'),
        backgroundColor: Colors.red,
      ));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }
}
