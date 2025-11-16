import 'package:erp_purchasing_apps/data/models/user_model.dart';
import 'package:erp_purchasing_apps/data/providers/division_provider.dart';
import 'package:erp_purchasing_apps/presentation/screens/user/user_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:erp_purchasing_apps/data/providers/user_provider.dart';
import 'package:erp_purchasing_apps/data/providers/auth_providers.dart';

/// User Management Screen (Admin Only)
/// Untuk create, edit, delete users
class UserListScreen extends ConsumerStatefulWidget {
  const UserListScreen({super.key});

  @override
  ConsumerState<UserListScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserListScreen> {
  final _searchController = TextEditingController();
  String? _selectedRoleFilter;
  bool _showInactiveOnly = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showCreateDialog() {
    showDialog(
      context: context,
      builder: (context) => const UserFormDialog(),
    );
  }

  void _showEditDialog(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => UserFormDialog(user: user),
    );
  }

  void _showDetailDialog(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: const Color(0xFF1ABC9C),
                      child: Text(
                        user.username.substring(0, 2).toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.fullName ?? user.username,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '@${user.username}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 32),
                _buildDetailRow('Email', user.email),
                _buildDetailRow('Role', _getRoleDisplayName(user.role)),
                _buildDetailRow('Division', user.divisionId ?? '-'),
                _buildDetailRow(
                    'Status', user.isActive ? 'Active' : 'Inactive'),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'admin':
        return 'Administrator';
      case 'purchasing':
        return 'Purchasing';
      case 'warehouse':
        return 'Warehouse';
      case 'finance':
        return 'Finance';
      case 'kadiv':
        return 'Kepala Divisi';
      case 'user':
        return 'User';
      default:
        return role;
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.red;
      case 'purchasing':
        return Colors.blue;
      case 'warehouse':
        return Colors.orange;
      case 'finance':
        return Colors.green;
      case 'kadiv':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Future<void> _deleteUser(UserModel user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deactivate User'),
        content:
            Text('Are you sure you want to deactivate "${user.username}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final repo = ref.read(userRepositoryProvider);
        await repo.deleteUser(user.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('User ${user.username} deactivated'),
              backgroundColor: Colors.orange,
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
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(userListProvider);
    final currentUser = ref.watch(currentUserProvider);
    final divisionsAsync = ref.watch(activeDivisionListProvider);

    // Check admin permission
    if (currentUser?.role != 'admin') {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Access Denied'),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.block, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Admin access required',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

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
          'User Management',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
            onPressed: () {
              ref.invalidate(userListProvider);
            },
          ),
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
                          hintText: 'Search users...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 20),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {});
                                  },
                                )
                              : null,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _showCreateDialog,
                      icon: const Icon(Icons.person_add, size: 20),
                      label: const Text('Add User'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1ABC9C),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('All Roles'),
                        selected: _selectedRoleFilter == null,
                        onSelected: (selected) {
                          setState(() => _selectedRoleFilter = null);
                        },
                      ),
                      const SizedBox(width: 8),
                      ...[
                        'admin',
                        'purchasing',
                        'warehouse',
                        'finance',
                        'kadiv',
                        'user'
                      ].map((role) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(_getRoleDisplayName(role)),
                            selected: _selectedRoleFilter == role,
                            onSelected: (selected) {
                              setState(() {
                                _selectedRoleFilter = selected ? role : null;
                              });
                            },
                          ),
                        );
                      }),
                      FilterChip(
                        label: const Text('Inactive Only'),
                        selected: _showInactiveOnly,
                        onSelected: (selected) {
                          setState(() => _showInactiveOnly = selected);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // User Table
          Expanded(
            child: usersAsync.when(
              data: (users) {
                // Apply filters
                var filteredUsers = users;

                // Search filter
                if (_searchController.text.isNotEmpty) {
                  final query = _searchController.text.toLowerCase();
                  filteredUsers = filteredUsers.where((user) {
                    return user.username.toLowerCase().contains(query) ||
                        user.email.toLowerCase().contains(query) ||
                        (user.fullName?.toLowerCase().contains(query) ?? false);
                  }).toList();
                }

                // Role filter
                if (_selectedRoleFilter != null) {
                  filteredUsers = filteredUsers
                      .where((user) => user.role == _selectedRoleFilter)
                      .toList();
                }

                // Status filter
                if (_showInactiveOnly) {
                  filteredUsers =
                      filteredUsers.where((user) => !user.isActive).toList();
                }

                if (filteredUsers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline,
                            size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'No users found',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(userListProvider);
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
                            const Color(0xFFF8F9FA),
                          ),
                          columns: const [
                            DataColumn(
                              label: Text(
                                'USER',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'EMAIL',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'ROLE',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'DIVISION',
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
                          rows: filteredUsers.map((user) {
                            final isCurrentUser = user.id == currentUser?.id;

                            return DataRow(
                              cells: [
                                DataCell(
                                  InkWell(
                                    onTap: () => _showDetailDialog(user),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor:
                                              _getRoleColor(user.role)
                                                  .withOpacity(0.1),
                                          child: Text(
                                            user.username
                                                .substring(0, 2)
                                                .toUpperCase(),
                                            style: TextStyle(
                                              color: _getRoleColor(user.role),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              user.fullName ?? user.username,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                            Text(
                                              '@${user.username}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    user.email,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getRoleColor(user.role)
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      _getRoleDisplayName(user.role),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: _getRoleColor(user.role),
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  divisionsAsync.when(
                                    data: (divisions) {
                                      final division = divisions
                                          .where((d) => d.id == user.divisionId)
                                          .firstOrNull;

                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.purple.shade50,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          division?.displayName ??
                                              'No Division',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.purple.shade700,
                                          ),
                                        ),
                                      );
                                    },
                                    loading: () => const Text('-'),
                                    error: (_, __) => const Text('-'),
                                  ),
                                ),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: user.isActive
                                          ? Colors.green.shade50
                                          : Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          user.isActive
                                              ? Icons.check_circle
                                              : Icons.cancel,
                                          size: 14,
                                          color: user.isActive
                                              ? Colors.green.shade700
                                              : Colors.red.shade700,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          user.isActive ? 'Active' : 'Inactive',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: user.isActive
                                                ? Colors.green.shade700
                                                : Colors.red.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                            Icons.visibility_outlined,
                                            size: 20),
                                        color: Colors.grey.shade600,
                                        tooltip: 'View',
                                        onPressed: () =>
                                            _showDetailDialog(user),
                                      ),
                                      if (!isCurrentUser) ...[
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined,
                                              size: 20),
                                          color: Colors.blue.shade600,
                                          tooltip: 'Edit',
                                          onPressed: () =>
                                              _showEditDialog(user),
                                        ),
                                        IconButton(
                                          icon:
                                              const Icon(Icons.block, size: 20),
                                          color: Colors.red.shade600,
                                          tooltip: 'Deactivate',
                                          onPressed: () => _deleteUser(user),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
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
                        ref.invalidate(userListProvider);
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
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
