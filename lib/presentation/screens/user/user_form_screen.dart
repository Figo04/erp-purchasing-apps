import 'package:erp_purchasing_apps/data/models/user_model.dart';
import 'package:erp_purchasing_apps/data/providers/division_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:erp_purchasing_apps/data/providers/user_provider.dart';

class UserFormDialog extends ConsumerStatefulWidget {
  final UserModel? user;

  const UserFormDialog({super.key, this.user});

  @override
  ConsumerState<UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends ConsumerState<UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _fullNameController;
  String _selectedRole = 'user';
  String? _selectedDivisionId;
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _usernameController =
        TextEditingController(text: widget.user?.username ?? '');
    _emailController = TextEditingController(text: widget.user?.email ?? '');
    _passwordController = TextEditingController();
    _fullNameController =
        TextEditingController(text: widget.user?.fullName ?? '');
    _selectedRole = widget.user?.role ?? 'user';
    _selectedDivisionId = widget.user?.divisionId;
    _isActive = widget.user?.isActive ?? true;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(userRepositoryProvider);

      if (widget.user == null) {
        // Create
        await repo.createUser(
          username: _usernameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          fullName: _fullNameController.text.trim().isEmpty
              ? null
              : _fullNameController.text.trim(),
          role: _selectedRole,
          divisionId: _selectedDivisionId,
        );
      } else {
        // Update
        await repo.updateUser(
          id: widget.user!.id,
          username: _usernameController.text.trim(),
          email: _emailController.text.trim(),
          fullName: _fullNameController.text.trim().isEmpty
              ? null
              : _fullNameController.text.trim(),
          role: _selectedRole,
          divisionId: _selectedDivisionId,
          isActive: _isActive,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.user == null
                  ? 'User created successfully'
                  : 'User updated successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
        ref.invalidate(userListProvider);
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
    final divisionsAsync = ref.watch(activeDivisionListProvider);

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.user == null ? 'Create New User' : 'Edit User',
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
                        // Username
                        TextFormField(
                          controller: _usernameController,
                          decoration: const InputDecoration(
                            labelText: 'Username *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Username is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Email
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.email),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Email is required';
                            }
                            if (!value.contains('@')) {
                              return 'Invalid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Password (only for create)
                        if (widget.user == null)
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Password *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.lock),
                              hintText: 'Min. 6 characters',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Password is required';
                              }
                              if (value.length < 6) {
                                return 'Min. 6 characters';
                              }
                              return null;
                            },
                          ),
                        if (widget.user == null) const SizedBox(height: 16),

                        // Full Name
                        TextFormField(
                          controller: _fullNameController,
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.badge),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Role Dropdown
                        DropdownButtonFormField<String>(
                          value: _selectedRole,
                          decoration: const InputDecoration(
                            labelText: 'Role *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.security),
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: 'admin', child: Text('Administrator')),
                            DropdownMenuItem(
                                value: 'purchasing', child: Text('Purchasing')),
                            DropdownMenuItem(
                                value: 'warehouse', child: Text('Warehouse')),
                            DropdownMenuItem(
                                value: 'finance', child: Text('Finance')),
                            DropdownMenuItem(
                                value: 'kadiv', child: Text('Kepala Divisi')),
                            DropdownMenuItem(
                                value: 'user', child: Text('User')),
                          ],
                          onChanged: (value) {
                            setState(() => _selectedRole = value!);
                          },
                        ),
                        const SizedBox(height: 16),

                        // Division Dropdown
                        divisionsAsync.when(
                          data: (divisions) => DropdownButtonFormField<String>(
                            value: _selectedDivisionId,
                            decoration: const InputDecoration(
                              labelText: 'Division *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.business),
                            ),
                            items: divisions.map((div) {
                              return DropdownMenuItem(
                                value: div.id,
                                child: Text(div.displayName),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => _selectedDivisionId = value);
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Please select division';
                              }
                              return null;
                            },
                          ),
                          loading: () => const LinearProgressIndicator(),
                          error: (_, __) =>
                              const Text('Failed to load divisions'),
                        ),
                        const SizedBox(height: 16),

                        // Active Switch (edit only)
                        if (widget.user != null)
                          SwitchListTile(
                            title: const Text('Active'),
                            value: _isActive,
                            onChanged: (value) =>
                                setState(() => _isActive = value),
                          ),
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
                          : Text(widget.user == null ? 'Create' : 'Update'),
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
