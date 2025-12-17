import 'package:erp_purchasing_apps/data/models/product_assessment_model.dart';
import 'package:erp_purchasing_apps/data/models/division_model.dart';
import 'package:erp_purchasing_apps/data/providers/auth_providers.dart';
import 'package:erp_purchasing_apps/data/providers/product_assessment_provider.dart';
import 'package:erp_purchasing_apps/data/providers/supplier_provider.dart';
import 'package:erp_purchasing_apps/data/providers/division_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:erp_purchasing_apps/data/providers/product_provider.dart';
import 'package:erp_purchasing_apps/data/providers/category_provider.dart';
import 'package:erp_purchasing_apps/data/models/product_model.dart';

/// Product Form Dialog - WITH AUTO PRODUCT CODE
class ProductFormDialog extends ConsumerStatefulWidget {
  final ProductModel? product;

  const ProductFormDialog({super.key, this.product});

  @override
  ConsumerState<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends ConsumerState<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _productCodeController;
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _specificationsController;
  late TextEditingController _priceController;

  String? _selectedCategoryId;
  String? _selectedSupplierId;
  String? _selectedDivisionId;
  String _selectedUnit = 'pcs';
  bool _isActive = true;
  bool _isLoading = false;

  // Duplicate check states
  bool _isNameChecked = false;
  bool _isCheckingName = false;
  bool _nameExists = false;
  ProductModel? _existingProduct;

  // NEW: Auto-generate code states
  bool _isGeneratingCode = false;
  bool _isCodeGenerated = false;

  @override
  void initState() {
    super.initState();
    _productCodeController = TextEditingController(
      text: widget.product?.productCode ?? '',
    );
    _nameController = TextEditingController(
      text: widget.product?.name ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.product?.description ?? '',
    );
    _specificationsController = TextEditingController(
      text: widget.product?.specifications ?? '',
    );
    _priceController = TextEditingController(
      text: widget.product?.unitPrice.toString() ?? '',
    );

    _selectedCategoryId = widget.product?.categoryId;
    _selectedSupplierId = widget.product?.supplierId;
    _selectedDivisionId = widget.product?.divisionId;
    _selectedUnit = widget.product?.unit ?? 'pcs';
    _isActive = widget.product?.isActive ?? true;

    // If editing, name is already checked
    if (widget.product != null) {
      _isNameChecked = true;
      _isCodeGenerated = true;
    }

    // Listen to name changes
    _nameController.addListener(() {
      if (_isNameChecked) {
        setState(() {
          _isNameChecked = false;
          _nameExists = false;
          _existingProduct = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _productCodeController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _specificationsController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  /// Check if product name already exists
  Future<void> _checkProductName() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      _showSnackBar('Please enter product name first', Colors.orange);
      return;
    }

    setState(() {
      _isCheckingName = true;
      _nameExists = false;
      _existingProduct = null;
    });

    try {
      final repo = ref.read(productRepositoryProvider);
      final result = await repo.checkProductNameExists(name);

      setState(() {
        _isCheckingName = false;
        _isNameChecked = true;
        _nameExists = result['exists'] == true;

        if (_nameExists && result['product'] != null) {
          _existingProduct = ProductModel.fromJson(result['product']);
        }
      });

      if (mounted) {
        if (_nameExists) {
          _showDuplicateDialog();
        } else {
          _showSnackBar('Product name is available! ✓', Colors.green);
        }
      }
    } catch (e) {
      setState(() {
        _isCheckingName = false;
      });
      _showSnackBar('Failed to check name: $e', Colors.red);
    }
  }

  /// NEW: Auto-generate product code
  Future<void> _generateProductCode() async {
    if (_selectedCategoryId == null) {
      _showSnackBar('Please select category first', Colors.orange);
      return;
    }

    if (_selectedDivisionId == null) {
      _showSnackBar('Please select division first', Colors.orange);
      return;
    }

    setState(() => _isGeneratingCode = true);

    try {
      final repo = ref.read(productRepositoryProvider);
      final code = await repo.generateProductCode(
        categoryId: _selectedCategoryId!,
        divisionId: _selectedDivisionId!,
      );

      setState(() {
        _productCodeController.text = code;
        _isCodeGenerated = true;
        _isGeneratingCode = false;
      });

      _showSnackBar('Product code generated: $code', Colors.green);
    } catch (e) {
      setState(() => _isGeneratingCode = false);
      _showSnackBar('Failed to generate code: $e', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showDuplicateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Text('Product Already Exists'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Product "${_nameController.text.trim()}" already exists:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Code', _existingProduct?.productCode ?? '-'),
                  _buildInfoRow('Name', _existingProduct?.name ?? '-'),
                  _buildInfoRow(
                      'Category', _existingProduct?.categoryName ?? '-'),
                  _buildInfoRow(
                      'Supplier', _existingProduct?.supplierName ?? '-'),
                  _buildInfoRow(
                      'Price', _existingProduct?.formattedPrice ?? '-'),
                  _buildInfoRow(
                      'Status',
                      _existingProduct?.isActive == true
                          ? 'Active'
                          : 'Inactive'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSubmit() async {
    // Validation
    if (!_isNameChecked && widget.product == null) {
      _showSnackBar(
          'Please check product name availability first!', Colors.orange);
      return;
    }

    if (_nameExists) {
      _showSnackBar(
          'Product name already exists! Use different name.', Colors.red);
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategoryId == null) {
      _showSnackBar('Please select a category', Colors.orange);
      return;
    }

    if (_selectedSupplierId == null) {
      _showSnackBar('Please select a supplier', Colors.orange);
      return;
    }

    if (_selectedDivisionId == null) {
      _showSnackBar('Please select a division', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentUser = ref.read(currentUserProvider);
      final canDirectCreate =
          currentUser?.role == 'admin' || currentUser?.role == 'purchasing';
      final price = double.tryParse(_priceController.text.trim()) ?? 0.0;

      if (widget.product == null) {
        // CREATE MODE
        if (canDirectCreate) {
          final notifier = ref.read(productNotifierProvider.notifier);
          await notifier.createProduct(
            CreateProductRequest(
              productCode: _productCodeController.text.trim(),
              name: _nameController.text.trim(),
              categoryId: _selectedCategoryId!,
              supplierId: _selectedSupplierId!,
              divisionId: _selectedDivisionId,
              unitPrice: price,
              unit: _selectedUnit,
              description: _descriptionController.text.trim().isEmpty
                  ? null
                  : _descriptionController.text.trim(),
              specifications: _specificationsController.text.trim().isEmpty
                  ? null
                  : _specificationsController.text.trim(),
            ),
          );
        } else {
          final assessmentNotifier =
              ref.read(productAssessmentNotifierProvider.notifier);
          await assessmentNotifier.createAssessment(
            CreateProductAssessmentRequest(
              productName: _nameController.text.trim(),
              categoryId: _selectedCategoryId!,
              supplierId: _selectedSupplierId!,
              divisionId: _selectedDivisionId,
              unitPrice: price,
              unit: _selectedUnit,
              description: _descriptionController.text.trim().isEmpty
                  ? null
                  : _descriptionController.text.trim(),
              specifications: _specificationsController.text.trim().isEmpty
                  ? null
                  : _specificationsController.text.trim(),
            ),
          );
        }

        if (mounted) {
          Navigator.pop(context);
          _showSnackBar(
            canDirectCreate
                ? 'Product created successfully'
                : 'Assessment request submitted',
            canDirectCreate ? Colors.green : Colors.blue,
          );
        }
      } else {
        // UPDATE MODE
        final notifier = ref.read(productNotifierProvider.notifier);
        await notifier.updateProduct(
          widget.product!.id,
          UpdateProductRequest(
            name: _nameController.text.trim(),
            categoryId: _selectedCategoryId!,
            supplierId: _selectedSupplierId!,
            divisionId: _selectedDivisionId,
            unitPrice: price,
            unit: _selectedUnit,
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            specifications: _specificationsController.text.trim().isEmpty
                ? null
                : _specificationsController.text.trim(),
            isActive: _isActive,
          ),
        );

        if (mounted) {
          Navigator.pop(context);
          _showSnackBar('Product updated successfully', Colors.green);
        }
      }
    } catch (e) {
      _showSnackBar('Failed: $e', Colors.red);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryListProvider);
    final suppliersAsync = ref.watch(supplierListProvider);
    final divisionsAsync = ref.watch(activeDivisionListProvider);
    final currentUser = ref.watch(currentUserProvider);
    final isAdmin = currentUser?.role == 'admin';
    final isPurchasing = currentUser?.role == 'purchasing';
    final isCreateMode = widget.product == null;
    final showProductCodeField = !isCreateMode || isAdmin || isPurchasing;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product == null ? 'New Product' : 'Edit Product',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),

                  // Info banner for non-admin
                  if (isCreateMode && !isAdmin && !isPurchasing) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              size: 20, color: Colors.blue.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Request will be sent for approval. Code will be auto-generated.',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // STEP 1: Product Name + Check Button
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Product Name *',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.inventory_2),
                            suffixIcon: _isNameChecked
                                ? Icon(
                                    _nameExists
                                        ? Icons.error
                                        : Icons.check_circle,
                                    color:
                                        _nameExists ? Colors.red : Colors.green)
                                : null,
                          ),
                          enabled: !_isCheckingName,
                          validator: (value) {
                            if (value == null || value.isEmpty)
                              return 'Product name is required';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: _isCheckingName ? null : _checkProductName,
                          icon: _isCheckingName
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : Icon(
                                  _isNameChecked
                                      ? (_nameExists
                                          ? Icons.refresh
                                          : Icons.check)
                                      : Icons.search,
                                  size: 20),
                          label: Text(_isCheckingName
                              ? 'Checking...'
                              : _isNameChecked
                                  ? (_nameExists ? 'Recheck' : 'Checked')
                                  : 'Check Name'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isNameChecked
                                ? (_nameExists ? Colors.orange : Colors.green)
                                : const Color(0xFF1ABC9C),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Status indicator
                  const SizedBox(height: 8),
                  if (_isNameChecked)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _nameExists
                            ? Colors.red.shade50
                            : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                            color: _nameExists
                                ? Colors.red.shade200
                                : Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                              _nameExists
                                  ? Icons.error_outline
                                  : Icons.check_circle_outline,
                              size: 16,
                              color: _nameExists
                                  ? Colors.red.shade700
                                  : Colors.green.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _nameExists
                                  ? 'Name exists! Use different name.'
                                  : 'Name is available ✓',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: _nameExists
                                      ? Colors.red.shade700
                                      : Colors.green.shade700,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // STEP 2: Category Dropdown
                  categoriesAsync.when(
                    data: (categories) {
                      final subCategories = categories
                          .where((cat) => cat.parentId != null)
                          .toList();
                      return IgnorePointer(
                        ignoring: !_isNameChecked || _nameExists,
                        child: Opacity(
                          opacity: (!_isNameChecked || _nameExists) ? 0.5 : 1.0,
                          child: DropdownButtonFormField<String>(
                            value: _selectedCategoryId,
                            decoration: InputDecoration(
                              labelText: 'Category *',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.category),
                              helperText: !_isNameChecked
                                  ? 'Check name first'
                                  : 'Select category',
                            ),
                            items: subCategories.map((category) {
                              return DropdownMenuItem(
                                value: category.id,
                                child: Text(category.getFullPath()),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedCategoryId = value;
                                // Reset code when category changes
                                if (_isCodeGenerated) {
                                  _productCodeController.clear();
                                  _isCodeGenerated = false;
                                }
                              });
                            },
                            validator: (value) =>
                                value == null ? 'Select category' : null,
                          ),
                        ),
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (_, __) => const Text('Failed to load categories'),
                  ),

                  const SizedBox(height: 16),

                  // STEP 3: Division Dropdown (NEW!)
                  divisionsAsync.when(
                    data: (divisions) {
                      return IgnorePointer(
                        ignoring: !_isNameChecked ||
                            _nameExists ||
                            _selectedCategoryId == null,
                        child: Opacity(
                          opacity: (!_isNameChecked ||
                                  _nameExists ||
                                  _selectedCategoryId == null)
                              ? 0.5
                              : 1.0,
                          child: DropdownButtonFormField<String>(
                            value: _selectedDivisionId,
                            decoration: InputDecoration(
                              labelText: 'Division *',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.business_center),
                              helperText: _selectedCategoryId == null
                                  ? 'Select category first'
                                  : 'Select division for product code',
                            ),
                            items: divisions.map((division) {
                              return DropdownMenuItem(
                                value: division.id,
                                child: Text(division.displayName),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedDivisionId = value;
                                // Reset code when division changes
                                if (_isCodeGenerated) {
                                  _productCodeController.clear();
                                  _isCodeGenerated = false;
                                }
                              });
                            },
                            validator: (value) =>
                                value == null ? 'Select division' : null,
                          ),
                        ),
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (_, __) => const Text('Failed to load divisions'),
                  ),

                  const SizedBox(height: 16),

                  // STEP 4: Product Code (auto-generate button + editable field)
                  if (showProductCodeField) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _productCodeController,
                            decoration: InputDecoration(
                              labelText: 'Product Code *',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.qr_code),
                              helperText:
                                  'Format: PROD-{category}-{division}-{seq}',
                              suffixIcon: _isCodeGenerated
                                  ? const Icon(Icons.check_circle,
                                      color: Colors.green)
                                  : null,
                            ),
                            enabled: !_isGeneratingCode,
                            validator: (value) {
                              if (value == null || value.isEmpty)
                                return 'Product code required';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: (_selectedCategoryId != null &&
                                    _selectedDivisionId != null &&
                                    !_isGeneratingCode)
                                ? _generateProductCode
                                : null,
                            icon: _isGeneratingCode
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.auto_awesome, size: 20),
                            label: Text(_isGeneratingCode
                                ? 'Generating...'
                                : 'Generate'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1ABC9C),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // STEP 5: Supplier, Price, Unit, etc (disabled until code generated)
                  suppliersAsync.when(
                    data: (suppliers) {
                      return IgnorePointer(
                        ignoring: !_isCodeGenerated && showProductCodeField,
                        child: Opacity(
                          opacity: (!_isCodeGenerated && showProductCodeField)
                              ? 0.5
                              : 1.0,
                          child: DropdownButtonFormField<String>(
                            value: _selectedSupplierId,
                            decoration: InputDecoration(
                              labelText: 'Supplier *',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.business),
                              helperText:
                                  showProductCodeField && !_isCodeGenerated
                                      ? 'Generate code first'
                                      : null,
                            ),
                            items: suppliers.map((supplier) {
                              return DropdownMenuItem(
                                value: supplier.id,
                                child: Text(
                                    '${supplier.name} (${supplier.supplierCode})'),
                              );
                            }).toList(),
                            onChanged: (value) =>
                                setState(() => _selectedSupplierId = value),
                            validator: (value) =>
                                value == null ? 'Select supplier' : null,
                          ),
                        ),
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (_, __) => const Text('Failed to load suppliers'),
                  ),

                  const SizedBox(height: 16),

                  // Unit Price
                  TextFormField(
                    controller: _priceController,
                    enabled: _isCodeGenerated || !showProductCodeField,
                    decoration: InputDecoration(
                      labelText: 'Unit Price *',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.attach_money),
                      prefixText: 'Rp ',
                      helperText: showProductCodeField && !_isCodeGenerated
                          ? 'Generate code first'
                          : null,
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}'))
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Price required';
                      final price = double.tryParse(value);
                      if (price == null || price <= 0)
                        return 'Enter valid price';
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Unit
                  DropdownButtonFormField<String>(
                    value: _selectedUnit,
                    decoration: const InputDecoration(
                      labelText: 'Unit *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.straighten),
                    ),
                    items: ProductUnits.all.map((unit) {
                      return DropdownMenuItem(
                          value: unit, child: Text(unit.toUpperCase()));
                    }).toList(),
                    onChanged: (value) =>
                        setState(() => _selectedUnit = value!),
                  ),

                  const SizedBox(height: 16),

                  // Description
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 2,
                  ),

                  const SizedBox(height: 16),

                  // Specifications
                  TextFormField(
                    controller: _specificationsController,
                    decoration: const InputDecoration(
                      labelText: 'Specifications',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.notes),
                    ),
                    maxLines: 2,
                  ),

                  const SizedBox(height: 16),

                  // Active Switch (Edit mode only)
                  if (widget.product != null)
                    SwitchListTile(
                      title: const Text('Active'),
                      value: _isActive,
                      onChanged: (value) => setState(() => _isActive = value),
                    ),

                  const SizedBox(height: 24),

                  // Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed:
                            _isLoading ? null : () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1ABC9C),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : Text(
                                widget.product == null ? 'Create' : 'Update'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
