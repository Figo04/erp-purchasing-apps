import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:erp_purchasing_apps/data/models/asset_model.dart';
import 'package:erp_purchasing_apps/data/providers/asset_provider.dart';

/// Widget untuk memilih asset yang sudah ada
/// Digunakan untuk transaksi OUT dan Disposed
class AssetSelectionDropdown extends ConsumerWidget {
  final AssetModel? selectedAsset;
  final Function(AssetModel?) onAssetSelected;
  final bool forDisposal; // true jika untuk disposed

  const AssetSelectionDropdown({
    super.key,
    required this.selectedAsset,
    required this.onAssetSelected,
    this.forDisposal = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Filter: hanya asset yang available (atau sesuai kebutuhan)
    final assetFilter = forDisposal
        ? const AssetFilter(
            // Untuk disposal: hanya yang available & bukan disposed
            status: 'available',
          )
        : const AssetFilter(
            // Untuk OUT: hanya yang available
            status: 'available',
          );

    final assetsAsync = ref.watch(assetListProvider(assetFilter));

    return assetsAsync.when(
      data: (assets) {
        // Filter out disposed assets
        final availableAssets = assets
            .where((a) => !a.isDisposed && a.quantity > 0)
            .toList();

        if (availableAssets.isEmpty) {
          return Card(
            color: Colors.orange.shade50,
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No available assets found. Please add assets first.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              value: selectedAsset?.id,
              decoration: const InputDecoration(
                labelText: 'Select Asset *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.inventory_2),
                hintText: 'Choose from existing assets',
              ),
              items: availableAssets.map((asset) {
                return DropdownMenuItem<String>(
                  value: asset.id,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        asset.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${asset.assetCode} | Qty: ${asset.quantity} | ${asset.assetTypeDisplayName}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (assetId) {
                if (assetId != null) {
                  final selected = availableAssets.firstWhere(
                    (a) => a.id == assetId,
                  );
                  onAssetSelected(selected);
                } else {
                  onAssetSelected(null);
                }
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select an asset';
                }
                return null;
              },
            ),

            // Show selected asset details
            if (selectedAsset != null) ...[
              const SizedBox(height: 12),
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Selected Asset Details:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildDetailRow('Code', selectedAsset!.assetCode),
                      _buildDetailRow('Type', selectedAsset!.assetTypeDisplayName),
                      _buildDetailRow('Category', selectedAsset!.categoryName ?? '-'),
                      _buildDetailRow(
                        'Available Qty',
                        '${selectedAsset!.quantity}',
                        valueColor: Colors.green.shade700,
                      ),
                      if (selectedAsset!.divisionName != null)
                        _buildDetailRow('Division', selectedAsset!.divisionName!),
                    ],
                  ),
                ),
              ),
            ],
          ],
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, _) => Card(
        color: Colors.red.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Error loading assets: $error',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: valueColor ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}