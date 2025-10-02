import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:erp_purchasing_apps/data/providers/supplier_provider.dart';
import 'package:erp_purchasing_apps/presentation/screens/supplier/supplier_form_screen.dart';

class SupplierListScreen extends ConsumerStatefulWidget {
  const SupplierListScreen({super.key});

  @override
  ConsumerState<SupplierListScreen> createState() => _SupplierListScreenState();
}

class _SupplierListScreenState extends ConsumerState<SupplierListScreen> {
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showSupplierForm({String? supplierId}) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SupplierFormScreen(supplierId: supplierId),
        ),
      ),
    ).then((_) {
      // Refresh list after form closes
      ref.invalidate(supplierListProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final supplierList = ref.watch(supplierListProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
        title: const Text('Suppliers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(supplierListProvider);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search suppliers...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),

          // Supplier List
          Expanded(
            child: supplierList.when(
              data: (suppliers) {
                if (suppliers.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.business, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No suppliers yet',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        )
                      ],
                    ),
                  );
                }

                // Filter suppliers berdasarkan pencarian
                final filteredSuppliers = _searchQuery.isEmpty
                    ? suppliers
                    : suppliers.where((supplier) {
                        return supplier.name
                                .toLowerCase()
                                .contains(_searchQuery) ||
                            (supplier.contactName
                                    ?.toLowerCase()
                                    .contains(_searchQuery) ??
                                false);
                      }).toList();

                if (filteredSuppliers.isEmpty) {
                  return const Center(
                    child: Text('No suppliers found'),
                  );
                }

                return ListView.builder(
                  itemCount: filteredSuppliers.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final supplier = filteredSuppliers[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              supplier.isActive ? Colors.green : Colors.grey,
                          child: Text(
                            supplier.name.substring(0, 1).toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          supplier.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (supplier.contactName != null)
                              Text('Contact: ${supplier.contactName}'),
                            if (supplier.phone != null)
                              Text('Phone: ${supplier.phone}'),
                            if (supplier.email != null)
                              Text('Email: ${supplier.email}')
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Chip(
                              label: Text(
                                supplier.isActive ? 'Active' : 'Inactive',
                                style: const TextStyle(fontSize: 12),
                              ),
                              backgroundColor: supplier.isActive
                                  ? Colors.green.shade100
                                  : Colors.grey.shade300,
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                _showSupplierForm(supplierId: supplier.id);
                              },
                            )
                          ],
                        ),
                        onTap: () {
                          _showSupplierForm(supplierId: supplier.id);
                        },
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        ref.invalidate(supplierListProvider);
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSupplierForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
