import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:erp_purchasing_apps/data/models/asset_model.dart';
import 'package:erp_purchasing_apps/data/providers/asset_provider.dart';
import 'package:intl/intl.dart';

/// ✅ UPDATED: Widget untuk memilih asset (SEMUA asset: milik sendiri + customer)
/// Menampilkan info ownership di detail card
class AssetSelectionDropdown extends ConsumerWidget {
  final AssetModel? selectedAsset;
  final Function(AssetModel?) onAssetSelected;

  const AssetSelectionDropdown({
    super.key,
    required this.selectedAsset,
    required this.onAssetSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ Get ALL available assets (both milik_sendiri and milik_customer)
    const assetFilter = AssetFilter(status: 'available');
    final assetsAsync = ref.watch(assetListProvider(assetFilter));

    return assetsAsync.when(
      data: (assets) {
        // Filter: hanya available & quantity > 0
        final availableAssets =
            assets.where((a) => a.isAvailable && a.quantity > 0).toList();

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
            // Dropdown untuk pilih asset
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        asset.isMilikSendiri ? Icons.store : Icons.business,
                        size: 20,
                        color:
                            asset.isMilikSendiri ? Colors.blue : Colors.purple,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        fit: FlexFit.loose,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              asset.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ),
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
                if (value == null) return 'Please select an asset';
                return null;
              },
            ),

            // ✅ Detail card untuk selected asset
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

                      // Basic Info
                      _buildDetailRow('Code', selectedAsset!.assetCode),
                      _buildDetailRow(
                        'Type',
                        selectedAsset!.assetTypeDisplayName,
                      ),
                      _buildDetailRow(
                        'Category',
                        selectedAsset!.categoryName ?? '-',
                      ),

                      // ✅ OWNERSHIP INFO (NEW)
                      _buildDetailRow(
                        'Ownership',
                        selectedAsset!.ownershipDisplayName,
                        valueColor: selectedAsset!.isMilikSendiri
                            ? Colors.blue.shade700
                            : Colors.purple.shade700,
                      ),

                      _buildDetailRow(
                        'Source',
                        selectedAsset!.sourceDisplayName,
                        valueColor: selectedAsset!.isFromSupplier
                            ? Colors.teal.shade700
                            : Colors.purple.shade700,
                      ),

                      _buildDetailRow(
                        'Available Qty',
                        '${selectedAsset!.quantity}',
                        valueColor: Colors.green.shade700,
                      ),

                      if (selectedAsset!.divisionName != null)
                        _buildDetailRow(
                          'Division',
                          selectedAsset!.divisionName!,
                        ),

                      // ✅ BEACUKAI IN INFO
                      if (selectedAsset!.hasBeacukaiIn) ...[
                        const Divider(height: 16),
                        const Text(
                          'Beacukai IN:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (selectedAsset!.beacukaiDocIn != null)
                          _buildDetailRow(
                            'Doc',
                            selectedAsset!.beacukaiDocIn!,
                          ),
                        if (selectedAsset!.beacukaiNoIn != null)
                          _buildDetailRow(
                            'No',
                            selectedAsset!.beacukaiNoIn!,
                          ),
                        if (selectedAsset!.beacukaiTglIn != null)
                          _buildDetailRow(
                            'Date',
                            DateFormat('dd MMM yyyy')
                                .format(selectedAsset!.beacukaiTglIn!),
                          ),
                        if (selectedAsset!.beacukaiNoAjuIn != null)
                          _buildDetailRow(
                            'No Aju',
                            selectedAsset!.beacukaiNoAjuIn!,
                          ),
                      ],
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
