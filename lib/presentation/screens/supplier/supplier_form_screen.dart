import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:erp_purchasing_apps/data/providers/supplier_provider.dart';
import 'package:erp_purchasing_apps/data/models/supplier_model.dart';

class SupplierFormScreen extends ConsumerStatefulWidget {
  final SupplierModel? supplier;

  const SupplierFormScreen({super.key, this.supplier});

  @override
  ConsumerState<SupplierFormScreen> createState() => _SupplierFormScreenState();
}

class _SupplierFormScreenState extends ConsumerState<SupplierFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _supplierCodeController;
  late TextEditingController _nameController;
  late TextEditingController _contactNameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _authEmailController;
  bool _canLogin = false;
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _supplierCodeController = TextEditingController(
      text: widget.supplier?.supplierCode ?? '',
    );
    _nameController = TextEditingController(
      text: widget.supplier?.name ?? '',
    );
    _contactNameController = TextEditingController(
      text: widget.supplier?.contactName ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.supplier?.phone ?? '',
    );
    _emailController = TextEditingController(
      text: widget.supplier?.email ?? '',
    );
    _addressController = TextEditingController(
      text: widget.supplier?.address ?? '',
    );
    _authEmailController = TextEditingController(
      text: widget.supplier?.authEmail ?? '',
    );
    _canLogin = widget.supplier?.canLogin ?? false;
    _isActive = widget.supplier?.isActive ?? true;
  }

  @override
  void dispose() {
    _supplierCodeController.dispose();
    _nameController.dispose();
    _contactNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _authEmailController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(supplierNotifierProvider.notifier);

      if (widget.supplier == null) {
        // Create
        await notifier.createSupplier(
          CreateSupplierRequest(
            supplierCode: _supplierCodeController.text.trim(),
            name: _nameController.text.trim(),
            contactName: _contactNameController.text.trim().isEmpty
                ? null
                : _contactNameController.text.trim(),
            phone: _phoneController.text.trim().isEmpty
                ? null
                : _phoneController.text.trim(),
            email: _emailController.text.trim().isEmpty
                ? null
                : _emailController.text.trim(),
            address: _addressController.text.trim().isEmpty
                ? null
                : _addressController.text.trim(),
            authEmail: _canLogin && _authEmailController.text.trim().isNotEmpty
                ? _authEmailController.text.trim()
                : null,
            canLogin: _canLogin,
          ),
        );
      } else {
        // Update
        await notifier.updateSupplier(
          widget.supplier!.id,
          UpdateSupplierRequest(
            supplierCode: _supplierCodeController.text.trim(),
            name: _nameController.text.trim(),
            contactName: _contactNameController.text.trim().isEmpty
                ? null
                : _contactNameController.text.trim(),
            phone: _phoneController.text.trim().isEmpty
                ? null
                : _phoneController.text.trim(),
            email: _emailController.text.trim().isEmpty
                ? null
                : _emailController.text.trim(),
            address: _addressController.text.trim().isEmpty
                ? null
                : _addressController.text.trim(),
            authEmail: _canLogin && _authEmailController.text.trim().isNotEmpty
                ? _authEmailController.text.trim()
                : null,
            canLogin: _canLogin,
            isActive: _isActive,
          ),
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.supplier == null
                  ? 'Supplier created successfully'
                  : 'Supplier updated successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
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
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.supplier == null ? 'New Supplier' : 'Edit Supplier',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Supplier Code
                        TextFormField(
                          controller: _supplierCodeController,
                          decoration: const InputDecoration(
                            labelText: 'Supplier Code *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.qr_code),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Supplier code is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Name
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Supplier Name *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.business),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Supplier name is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Contact Name
                        TextFormField(
                          controller: _contactNameController,
                          decoration: const InputDecoration(
                            labelText: 'Contact Person',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Phone
                        TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Phone',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.phone),
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),

                        // Email
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.email),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),

                        // Address
                        TextFormField(
                          controller: _addressController,
                          decoration: const InputDecoration(
                            labelText: 'Address',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.location_on),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),

                        // Portal Access Switch
                        SwitchListTile(
                          title: const Text('Allow Portal Access'),
                          subtitle: const Text('Supplier can login and create shipments'),
                          value: _canLogin,
                          onChanged: (value) => setState(() => _canLogin = value),
                        ),

                        // Auth Email (if can login)
                        if (_canLogin) ...[
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _authEmailController,
                            decoration: const InputDecoration(
                              labelText: 'Portal Login Email',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.vpn_key),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (_canLogin && (value == null || value.isEmpty)) {
                                return 'Portal email is required';
                              }
                              if (_canLogin && !value!.contains('@')) {
                                return 'Invalid email format';
                              }
                              return null;
                            },
                          ),
                        ],

                        // Active Switch (edit only)
                        if (widget.supplier != null) ...[
                          const SizedBox(height: 16),
                          SwitchListTile(
                            title: const Text('Active'),
                            value: _isActive,
                            onChanged: (value) => setState(() => _isActive = value),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
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
                              widget.supplier == null ? 'Create' : 'Update',
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}