import 'package:erp_purchasing_apps/data/models/product_assessment_model.dart';
import 'package:erp_purchasing_apps/data/providers/auth_providers.dart';
import 'package:erp_purchasing_apps/data/providers/product_assessment_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:erp_purchasing_apps/data/providers/product_provider.dart';
import 'package:erp_purchasing_apps/data/providers/category_provider.dart';
import 'package:erp_purchasing_apps/data/models/product_model.dart';

/// Product Form Dialog (Create/Edit)
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
  String? _selectedCategoryId;
  String _selectedUnit = 'pcs';
  bool _isActive = true;
  bool _isLoading = false;

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
    _selectedCategoryId = widget.product?.categoryId;
    _selectedUnit = widget.product?.unit ?? 'pcs';
    _isActive = widget.product?.isActive ?? true;
  }

  @override
  void dispose() {
    _productCodeController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _specificationsController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentUser = ref.read(currentUserProvider);
      final canDirectCreate = currentUser?.role == 'admin';

      if (widget.product == null) {
        // CREATE MODE
        if (canDirectCreate) {
          // Admin: Langsung create ke master (PERLU PRODUCT CODE)
          final notifier = ref.read(productNotifierProvider.notifier);
          await notifier.createProduct(
            CreateProductRequest(
              productCode: _productCodeController.text.trim(),
              name: _nameController.text.trim(),
              categoryId: _selectedCategoryId!,
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
          // User biasa: Create assessment request (TIDAK PERLU PRODUCT CODE)
          final assessmentNotifier =
              ref.read(productAssessmentNotifierProvider.notifier);
          await assessmentNotifier.createAssessment(
            CreateProductAssessmentRequest(
              productName: _nameController.text.trim(),
              categoryId: _selectedCategoryId!,
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                canDirectCreate
                    ? 'Product created successfully'
                    : 'Product assessment request submitted. Waiting for approval.',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // UPDATE MODE (unchanged)
        final notifier = ref.read(productNotifierProvider.notifier);
        await notifier.updateProduct(
          widget.product!.id,
          UpdateProductRequest(
            productCode: _productCodeController.text.trim(),
            name: _nameController.text.trim(),
            categoryId: _selectedCategoryId!,
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Product updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
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
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryListProvider);
    final currentUser = ref.watch(currentUserProvider);
    final isAdmin = currentUser?.role == 'admin';
    final isCreateMode = widget.product == null;

    // Show product code field only for:
    // 1. Admin creating new product (direct to master)
    // 2. Editing existing product (update mode)
    final showProductCodeField = !isCreateMode || isAdmin;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
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
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Info banner for non-admin
                  if (isCreateMode && !isAdmin) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 20,
                            color: Colors.blue.shade700,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Product code will be auto-generated after approval',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Product Code (conditional)
                  if (showProductCodeField) ...[
                    TextFormField(
                      controller: _productCodeController,
                      decoration: const InputDecoration(
                        labelText: 'Product Code *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.qr_code),
                        helperText:
                            'Format: PROD-{CATEGORY}-{SEQ} (e.g., PROD-2.3-001)',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Product code is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Name
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Product Name *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.inventory_2),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Product name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Category Dropdown (FILTER: Only Sub-Categories)
                  categoriesAsync.when(
                    data: (categories) {
                      // Filter: Hanya tampilkan sub-category (yang punya parent_id)
                      final subCategories = categories
                          .where((cat) => cat.parentId != null)
                          .toList();

                      return DropdownButtonFormField<String>(
                        value: _selectedCategoryId,
                        decoration: const InputDecoration(
                          labelText: 'Category *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category),
                          helperText:
                              'Select specific sub-category (e.g., 1.1, 2.3)',
                        ),
                        items: subCategories.map((category) {
                          return DropdownMenuItem(
                            value: category.id,
                            child: Text(category.getFullPath()),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedCategoryId = value);
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select a sub-category';
                          }
                          return null;
                        },
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (_, __) => const Text('Failed to load categories'),
                  ),
                  const SizedBox(height: 16),

                  // Unit Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedUnit,
                    decoration: const InputDecoration(
                      labelText: 'Unit *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.straighten),
                    ),
                    items: ProductUnits.all.map((unit) {
                      return DropdownMenuItem(
                        value: unit,
                        child: Text(unit.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedUnit = value!);
                    },
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
                    maxLines: 3,
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
                    maxLines: 3,
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
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                widget.product == null ? 'Create' : 'Update',
                              ),
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
