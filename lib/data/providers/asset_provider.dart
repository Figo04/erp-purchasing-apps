import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/asset_model.dart';
import '../repositories/asset_repository.dart';

final assetRepositoryProvider = Provider<AssetRepository>((ref) {
  return AssetRepository();
});

// Real-time Asset Stream Provider
final assetStreamProvider = StreamProvider<List<AssetModel>>((ref) {
  final supabase = Supabase.instance.client;

  return supabase
      .from('asset')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false)
      .asyncMap((data) async {
        // Fetch user info for assigned assets
        final List<AssetModel> assets = [];

        for (var json in data) {
          if (json['assigned_to'] != null) {
            try {
              final userResponse = await supabase
                  .from('users')
                  .select('full_name')
                  .eq('id', json['assigned_to'])
                  .maybeSingle();

              if (userResponse != null) {
                json['assigned_to_name'] = userResponse['full_name'];
              }
            } catch (e) {
              // Ignore error, just don't add assigned_to_name
            }
          }
          assets.add(AssetModel.fromJson(json));
        }

        return assets;
      });
});

// Borrowed assets count
final borrowedAssetsCountProvider = Provider<int>((ref) {
  final assetStream = ref.watch(assetStreamProvider);

  return assetStream.when(
    data: (assets) =>
        assets.where((asset) => asset.status == 'borrowed').length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

// Assets by category count
final assetsByCategoryProvider = Provider<Map<String, int>>((ref) {
  final assetStream = ref.watch(assetStreamProvider);

  return assetStream.when(
    data: (assets) {
      return {
        'consumable': assets.where((a) => a.category == 'consumable').length,
        'loanable': assets.where((a) => a.category == 'loanable').length,
        'saleable': assets.where((a) => a.category == 'saleable').length,
      };
    },
    loading: () => {'consumable': 0, 'loanable': 0, 'saleable': 0},
    error: (_, __) => {'consumable': 0, 'loanable': 0, 'saleable': 0},
  );
});

// My assigned assets (for regular users)
final myAssignedAssetsProvider =
    FutureProvider.family<List<AssetModel>, String>((ref, userId) async {
  final repo = ref.watch(assetRepositoryProvider);
  return await repo.getMyAssignedAssets(userId);
});
