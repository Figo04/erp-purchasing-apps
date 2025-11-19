import 'package:erp_purchasing_apps/data/models/lpb_model.dart';
import 'package:erp_purchasing_apps/presentation/screens/qr/qr_scanner_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:erp_purchasing_apps/data/providers/lpb_provider.dart';
import 'package:erp_purchasing_apps/presentation/screens/lpb/lpb_detail_screen.dart';

/// LPB List Screen with Modern DataTable Design
/// Displays all LPB (Laporan Penerimaan Barang) in table format
class LPBListScreen extends ConsumerStatefulWidget {
  const LPBListScreen({super.key});

  @override
  ConsumerState<LPBListScreen> createState() => _LPBListScreenState();
}

class _LPBListScreenState extends ConsumerState<LPBListScreen> {
  final _searchController = TextEditingController();
  String? _selectedStatusFilter;

  @override
  void initState() {
    super.initState();
    // Auto-load LPBs on init
    Future.microtask(() {
      ref.read(lpbListProvider.notifier).loadLPBs();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================
  // NAVIGATION METHODS
  // ============================================

  void _navigateToQRScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const QRScannerScreen(),
      ),
    ).then((_) {
      ref.read(lpbListProvider.notifier).refresh();
    });
  }

  void _showLPBDetail(LPBModel lpb) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LPBDetailScreen(lpb: lpb),
      ),
    ).then((_) {
      ref.read(lpbListProvider.notifier).refresh();
    });
  }

  // ============================================
  // ACTION METHODS
  // ============================================

  Future<void> _completeLPB(String lpbId, String lpbNumber) async {
    final confirmed = await _showConfirmDialog(
      title: 'Complete LPB',
      content: 'Are you sure you want to complete $lpbNumber?',
      confirmText: 'Complete',
      confirmColor: Colors.green,
    );

    if (confirmed == true && mounted) {
      try {
        final success =
            await ref.read(lpbListProvider.notifier).completeLPB(lpbId);

        if (mounted && success) {
          _showSuccessSnackBar('$lpbNumber completed successfully');
        }
      } catch (e) {
        if (mounted) {
          _showErrorSnackBar('Error completing LPB: $e');
        }
      }
    }
  }

  Future<void> _deleteLPB(String lpbId, String lpbNumber) async {
    final confirmed = await _showConfirmDialog(
      title: 'Delete LPB',
      content: 'Are you sure you want to delete $lpbNumber?',
      confirmText: 'Delete',
      confirmColor: Colors.red,
    );

    if (confirmed == true && mounted) {
      try {
        final success =
            await ref.read(lpbListProvider.notifier).deleteLPB(lpbId);

        if (mounted && success) {
          _showSuccessSnackBar('$lpbNumber deleted successfully');
        }
      } catch (e) {
        if (mounted) {
          _showErrorSnackBar('Error deleting LPB: $e');
        }
      }
    }
  }

  // ============================================
  // DIALOG & SNACKBAR HELPERS
  // ============================================

  Future<bool?> _showConfirmDialog({
    required String title,
    required String content,
    required String confirmText,
    required Color confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: confirmColor),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
      ),
    );
  }

  // ============================================
  // STATUS COLOR HELPERS
  // ============================================

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getPaymentStatusColor(String paymentStatus) {
    switch (paymentStatus.toLowerCase()) {
      case 'unpaid':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      case 'paid':
        return Colors.green;
      case 'partial':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  // ============================================
  // FILTER LOGIC
  // ============================================

  List<LPBModel> _applyFilters(List<LPBModel> lpbs) {
    var filtered = lpbs;

    // Apply search filter
    final searchQuery = _searchController.text.toLowerCase();
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((lpb) {
        return lpb.lpbNumber.toLowerCase().contains(searchQuery) ||
            (lpb.poNumber?.toLowerCase().contains(searchQuery) ?? false);
      }).toList();
    }

    // Apply status filter
    if (_selectedStatusFilter != null && _selectedStatusFilter != 'all') {
      if (_selectedStatusFilter == 'unpaid') {
        // Special case: filter by payment status
        filtered = filtered
            .where((lpb) => lpb.paymentStatus.toLowerCase() == 'unpaid')
            .toList();
      } else {
        filtered = filtered
            .where((lpb) => lpb.status.toLowerCase() == _selectedStatusFilter)
            .toList();
      }
    }

    return filtered;
  }

  // ============================================
  // BUILD METHOD
  // ============================================

  @override
  Widget build(BuildContext context) {
    final lpbState = ref.watch(lpbListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: _buildAppBar(lpbState),
      body: Column(
        children: [
          _buildFilterSection(lpbState),
          const Divider(height: 1),
          Expanded(
            child: _buildTableContent(lpbState),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  // ============================================
  // UI COMPONENT BUILDERS
  // ============================================

  PreferredSizeWidget _buildAppBar(LPBListState lpbState) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black87),
        onPressed: () => context.go('/dashboard'),
      ),
      title: const Text(
        'LPB List',
        style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
      ),
      actions: [
        // Loading indicator
        if (lpbState.isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black87),
                ),
              ),
            ),
          ),
        // Refresh button
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.black87),
          onPressed: () {
            ref.read(lpbListProvider.notifier).refresh();
          },
        ),
      ],
    );
  }

  Widget _buildFilterSection(LPBListState lpbState) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search Bar & Scan Button
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search LPB or PO number...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
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
                              setState(() {
                                _searchController.clear();
                              });
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _navigateToQRScanner,
                icon: const Icon(Icons.qr_code_scanner, size: 20),
                label: const Text('Scan QR'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1ABC9C),
                  foregroundColor: Colors.white,
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
                _buildFilterChip(
                  'all',
                  'All',
                  lpbState.lpbs.length,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'draft',
                  'Draft',
                  ref.watch(draftLPBsCountProvider),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'completed',
                  'Completed',
                  ref.watch(completedLPBsCountProvider),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'unpaid',
                  'Unpaid',
                  ref.watch(unpaidLPBsCountProvider),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, int count) {
    final isSelected = _selectedStatusFilter == value;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : const Color(0xFF1ABC9C),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected ? const Color(0xFF1ABC9C) : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedStatusFilter = value;
        });
      },
      selectedColor: const Color(0xFF1ABC9C).withOpacity(0.2),
    );
  }

  Widget _buildTableContent(LPBListState lpbState) {
    // Handle loading state
    if (lpbState.isLoading && lpbState.lpbs.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Handle error state
    if (lpbState.error != null) {
      return _buildErrorState(lpbState.error!);
    }

    // Apply filters
    final filteredLPBs = _applyFilters(lpbState.lpbs);

    // Handle empty state
    if (filteredLPBs.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(lpbListProvider.notifier).refresh();
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
                    'LPB NUMBER',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'PO NUMBER',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'RECEIPT DATE',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'ITEMS',
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
                    'PAYMENT',
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
              rows: filteredLPBs.map((lpb) {
                return _buildDataRow(lpb);
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  DataRow _buildDataRow(LPBModel lpb) {
    final itemCount = lpb.items?.length ?? 0;
    final canComplete = lpb.status.toLowerCase() == 'draft';
    final canDelete = lpb.status.toLowerCase() == 'draft';
    final isCompleted = lpb.status.toLowerCase() == 'completed';

    return DataRow(
      cells: [
        // LPB Number
        DataCell(
          InkWell(
            onTap: () => _showLPBDetail(lpb),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF1ABC9C).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                lpb.lpbNumber,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: Color(0xFF1ABC9C),
                ),
              ),
            ),
          ),
        ),

        // PO Number
        DataCell(
          Text(
            lpb.poNumber ?? '-',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        // Receipt Date
        DataCell(
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(
                DateFormat('dd MMM yyyy').format(lpb.receiptDate),
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),

        // Items Count
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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inventory_2, size: 14, color: Colors.blue.shade700),
                const SizedBox(width: 4),
                Text(
                  '$itemCount items',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
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
              color: _getStatusColor(lpb.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  lpb.status.toLowerCase() == 'completed'
                      ? Icons.check_circle
                      : Icons.edit_note,
                  size: 14,
                  color: _getStatusColor(lpb.status),
                ),
                const SizedBox(width: 4),
                Text(
                  lpb.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(lpb.status),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Payment Status
        DataCell(
          isCompleted
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getPaymentStatusColor(lpb.paymentStatus)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        lpb.paymentStatus.toLowerCase() == 'paid'
                            ? Icons.check_circle
                            : lpb.paymentStatus.toLowerCase() == 'unpaid'
                                ? Icons.cancel
                                : Icons.pending,
                        size: 14,
                        color: _getPaymentStatusColor(lpb.paymentStatus),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        lpb.paymentStatus.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _getPaymentStatusColor(lpb.paymentStatus),
                        ),
                      ),
                    ],
                  ),
                )
              : const Text(
                  '-',
                  style: TextStyle(color: Colors.grey),
                ),
        ),

        // Actions
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // View Button
              IconButton(
                icon: const Icon(Icons.visibility_outlined, size: 20),
                color: Colors.blue.shade600,
                tooltip: 'View Details',
                onPressed: () => _showLPBDetail(lpb),
              ),

              // Complete Button
              if (canComplete)
                IconButton(
                  icon: const Icon(Icons.check_circle_outline, size: 20),
                  color: Colors.green.shade600,
                  tooltip: 'Complete',
                  onPressed: () => _completeLPB(lpb.id, lpb.lpbNumber),
                ),

              // Delete Button
              if (canDelete)
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: Colors.red.shade600,
                  tooltip: 'Delete',
                  onPressed: () => _deleteLPB(lpb.id, lpb.lpbNumber),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
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
            'No LPB found',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Scan QR code to create new LPB',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('Error: $error'),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              ref.read(lpbListProvider.notifier).refresh();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _navigateToQRScanner,
      icon: const Icon(Icons.qr_code_scanner),
      label: const Text('Scan QR'),
      backgroundColor: const Color(0xFF1ABC9C),
    );
  }
}
