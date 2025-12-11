import 'package:erp_purchasing_apps/presentation/screens/master%20data/product/product_form_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:erp_purchasing_apps/data/providers/product_provider.dart';
import 'package:erp_purchasing_apps/data/providers/category_provider.dart';
import 'package:erp_purchasing_apps/data/providers/supplier_provider.dart';
import 'package:erp_purchasing_apps/data/models/product_model.dart';

/// Product List Screen with Modern DataTable
class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  final _searchController = TextEditingController();
  String? _selectedCategoryFilter;
  String? _selectedSupplierFilter;
  bool _showInactiveOnly = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showCreateDialog() {
    showDialog(
      context: context,
      builder: (context) => const ProductFormDialog(),
    );
  }

  void _showEditDialog(ProductModel product) {
    showDialog(
      context: context,
      builder: (context) => ProductFormDialog(product: product),
    );
  }

  Future<void> _deleteProduct(ProductModel product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref
            .read(productNotifierProvider.notifier)
            .deleteProduct(product.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Product deleted successfully'),
                ],
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Failed to delete: $e')),
                ],
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsState = ref.watch(productNotifierProvider);
    final categoriesAsync = ref.watch(categoryListProvider);
    final suppliersAsync = ref.watch(supplierListProvider);
    final searchQuery = ref.watch(productSearchQueryProvider);
    final categoryFilter = ref.watch(productCategoryFilterProvider);
    final supplierFilter = ref.watch(productSupplierFilterProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.go('/dashboard'),
        ),
        title: const Text(
          'Master Product',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
            onPressed: () {
              ref.read(productNotifierProvider.notifier).refresh();
            },
          )
        ],
      ),
      body: Column(
        children: [
          // Filter Section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search & Add Button
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search products...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300)),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 20),
                                  onPressed: () {
                                    _searchController.clear();
                                    ref
                                        .read(
                                            productSearchQueryProvider.notifier)
                                        .state = '';
                                  },
                                )
                              : null,
                        ),
                        onChanged: (value) {
                          ref.read(productSearchQueryProvider.notifier).state =
                              value;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _showCreateDialog,
                      icon: const Icon(Icons.add, size: 20),
                      label: const Text('Add Product'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1ABC9C),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          )),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Category Filters
                      categoriesAsync.when(
                        data: (categories) {
                          return Wrap(
                            spacing: 8,
                            children: [
                              FilterChip(
                                label: const Text('All Categories'),
                                selected: _selectedCategoryFilter == null,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedCategoryFilter = null;
                                    ref
                                        .read(productCategoryFilterProvider
                                            .notifier)
                                        .state = null;
                                  });
                                },
                              ),
                              ...categories
                                  .where((c) => c.isRoot)
                                  .map((category) {
                                return FilterChip(
                                  label: Text(category.name),
                                  selected:
                                      _selectedCategoryFilter == category.id,
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedCategoryFilter =
                                          selected ? category.id : null;
                                      ref
                                              .read(
                                                  productCategoryFilterProvider
                                                      .notifier)
                                              .state =
                                          selected ? category.id : null;
                                    });
                                  },
                                );
                              })
                            ],
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),

                      const SizedBox(width: 8),

                      // Supplier Filters
                      suppliersAsync.when(
                        data: (suppliers) {
                          return Wrap(
                            spacing: 8,
                            children: [
                              FilterChip(
                                label: const Text('All Suppliers'),
                                selected: _selectedSupplierFilter == null,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedSupplierFilter = null;
                                    ref
                                        .read(productSupplierFilterProvider
                                            .notifier)
                                        .state = null;
                                  });
                                },
                              ),
                              ...suppliers.take(5).map((supplier) {
                                return FilterChip(
                                  label: Text(supplier.name),
                                  selected:
                                      _selectedSupplierFilter == supplier.id,
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedSupplierFilter =
                                          selected ? supplier.id : null;
                                      ref
                                              .read(
                                                  productSupplierFilterProvider
                                                      .notifier)
                                              .state =
                                          selected ? supplier.id : null;
                                    });
                                  },
                                );
                              })
                            ],
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),

                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Inactive Only'),
                        selected: _showInactiveOnly,
                        onSelected: (selected) {
                          setState(() => _showInactiveOnly = selected);

                          ref.read(productActiveFilterProvider.notifier).state =
                              selected ? false : true;
                        },
                        avatar: Icon(
                          _showInactiveOnly
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),

          const Divider(height: 1),

          // DataTable Section
          Expanded(
            child: productsState.when(
              data: (products) {
                // Apply filters
                var filteredProducts = products;

                // Apply search
                if (searchQuery.isNotEmpty) {
                  filteredProducts = filteredProducts.where((p) {
                    return p.name
                            .toLowerCase()
                            .contains(searchQuery.toLowerCase()) ||
                        p.productCode
                            .toLowerCase()
                            .contains(searchQuery.toLowerCase()) ||
                        (p.supplierName
                                ?.toLowerCase()
                                .contains(searchQuery.toLowerCase()) ??
                            false);
                  }).toList();
                }

                if (_selectedCategoryFilter != null) {
                  final categories = categoriesAsync.value ?? [];
                  final childCategoryIds = categories
                      .where((c) => c.parentId == _selectedCategoryFilter)
                      .map((c) => c.id)
                      .toList();

                  filteredProducts = filteredProducts.where((p) {
                    return p.categoryId == _selectedCategoryFilter ||
                        childCategoryIds.contains(p.categoryId);
                  }).toList();
                }

                // Filter by supplier
                if (_selectedSupplierFilter != null) {
                  filteredProducts = filteredProducts
                      .where((p) => p.supplierId == _selectedSupplierFilter)
                      .toList();
                }

                if (_showInactiveOnly) {
                  filteredProducts =
                      filteredProducts.where((p) => !p.isActive).toList();
                }

                if (filteredProducts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No products found',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        )
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    await ref.read(productNotifierProvider.notifier).refresh();
                  },
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Container(
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: DataTable(
                          headingRowHeight: 56,
                          dataRowHeight: 72,
                          columnSpacing: 24,
                          horizontalMargin: 24,
                          headingRowColor: MaterialStateProperty.all(
                              const Color(0xFFF8F9FA)),
                          columns: const [
                            DataColumn(
                              label: Text(
                                'CODE',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'PRODUCT NAME',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'CATEGORY',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'SUPPLIER',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'UNIT PRICE',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'UNIT',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'STATUS',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'ACTIONS',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                          rows: filteredProducts.map((product) {
                            return DataRow(
                              cells: [
                                // Code
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1ABC9C)
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      product.productCode,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                        color: Color(0xFF1ABC9C),
                                      ),
                                    ),
                                  ),
                                ),

                                // Product Name
                                DataCell(
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        product.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      if (product.description != null)
                                        Text(
                                          product.description!,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600),
                                        )
                                    ],
                                  ),
                                ),

                                // Category
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      product.categoryName ?? 'N/A',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue.shade700,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),

                                // Supplier
                                DataCell(
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        product.supplierName ?? 'Unknown',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                      if (product.supplierCode != null)
                                        Text(
                                          product.supplierCode!,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),

                                // Unit Price
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      product.formattedPrice,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.green.shade700,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),

                                // Unit
                                DataCell(
                                  Text(
                                    product.unit.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),

                                // Status
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: product.isActive
                                          ? Colors.green.shade50
                                          : Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          product.isActive
                                              ? Icons.check_circle
                                              : Icons.cancel,
                                          size: 14,
                                          color: product.isActive
                                              ? Colors.green.shade700
                                              : Colors.red.shade700,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          product.isActive
                                              ? 'Active'
                                              : 'Inactive',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: product.isActive
                                                ? Colors.green.shade700
                                                : Colors.red.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Actions
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined,
                                            size: 20),
                                        color: Colors.blue.shade600,
                                        tooltip: 'Edit',
                                        onPressed: () =>
                                            _showEditDialog(product),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline,
                                            size: 20),
                                        color: Colors.red.shade600,
                                        tooltip: 'Delete',
                                        onPressed: () =>
                                            _deleteProduct(product),
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        ref.read(productNotifierProvider.notifier).refresh();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
