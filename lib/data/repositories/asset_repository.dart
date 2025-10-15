import 'package:erp_purchasing_apps/data/models/asset_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AssetRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get all assets with user info (joined)
  Future<List<AssetModel>> getAllAssets() async {
    try {
      final response = await _supabase.from('asset').select('''
            *,
            users!asset_assigned_to_fkey(full_name)
          ''').order('created_at', ascending: false);

      return (response as List).map((json) {
        // Extract user full_name from joined data
        final userData = json['users'];
        final Map<String, dynamic> assetData = Map.from(json);
        assetData.remove('users');

        if (userData != null) {
          assetData['assigned_to_name'] = userData['full_name'];
        }

        return AssetModel.fromJson(assetData);
      }).toList();
    } catch (e) {
      throw Exception('Failed to load assets: $e');
    }
  }

  // Get asset by ID
  Future<AssetModel?> getAssetById(String id) async {
    try {
      final response = await _supabase.from('asset').select('''
            *,
            users!asset_assigned_to_fkey(full_name)
          ''').eq('id', id).maybeSingle();

      if (response == null) return null;

      final userData = response['users'];
      final Map<String, dynamic> assetData = Map.from(response);
      assetData.remove('users');

      if (userData != null) {
        assetData['assigned_to_name'] = userData['full_name'];
      }

      return AssetModel.fromJson(assetData);
    } catch (e) {
      throw Exception('Failed to load asset: $e');
    }
  }

  // Create new asset
  Future<AssetModel> createAsset({
    required String name,
    required String category,
    required int quantity,
    double? purchasePrice,
    String? notes,
  }) async {
    try {
      // Generate asset code
      final assetCode = await _generateAssetCode();

      final data = {
        'asset_code': assetCode,
        'name': name,
        'category': category,
        'status': 'available',
        'quantity': quantity,
        'purchase_price': purchasePrice,
        'notes': notes,
      };

      final response =
          await _supabase.from('asset').insert(data).select().single();

      return AssetModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create asset: $e');
    }
  }

  // Update asset
  Future<AssetModel> updateAsset({
    required String id,
    required String name,
    required String category,
    required int quantity,
    double? purchasePrice,
    String? notes,
  }) async {
    try {
      final data = {
        'name': name,
        'category': category,
        'quantity': quantity,
        'purchase_price': purchasePrice,
        'notes': notes,
      };

      final response = await _supabase
          .from('asset')
          .update(data)
          .eq('id', id)
          .select()
          .single();

      return AssetModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update asset: $e');
    }
  }

  // Delete asset
  Future<void> deleteAsset(String id) async {
    try {
      await _supabase.from('asset').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete asset: $e');
    }
  }

  // Assign asset to user
  Future<AssetModel> assignAsset({
    required String id,
    required String userId,
    String? reason,
  }) async {
    try {
      final current = await getAssetById(id);
      if (current == null) {
        throw Exception('Asset not found');
      }

      if (current.status == 'borrowed') {
        throw Exception('Asset is already borrowed');
      }

      // Add to notes
      String? notes = current.notes;
      if (reason != null && reason.isNotEmpty) {
        notes =
            '${notes ?? ''}\n[ASSIGNED] to user on ${DateTime.now()}: $reason'
                .trim();
      }

      final data = {
        'assigned_to': userId,
        'assigned_date': DateTime.now().toIso8601String(),
        'status': 'borrowed',
        'notes': notes,
      };

      final response = await _supabase
          .from('asset')
          .update(data)
          .eq('id', id)
          .select()
          .single();

      return AssetModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to assign asset: $e');
    }
  }

  // Unassign asset (return)
  Future<AssetModel> unassignAsset({
    required String id,
    String? returnNotes,
  }) async {
    try {
      final current = await getAssetById(id);
      if (current == null) {
        throw Exception('Asset not found');
      }

      // Add to notes
      String? notes = current.notes;
      if (returnNotes != null && returnNotes.isNotEmpty) {
        notes = '${notes ?? ''}\n[RETURNED] on ${DateTime.now()}: $returnNotes'
            .trim();
      } else {
        notes = '${notes ?? ''}\n[RETURNED] on ${DateTime.now()}'.trim();
      }

      final data = {
        'assigned_to': null,
        'assigned_date': null,
        'status': 'available',
        'notes': notes,
      };

      final response = await _supabase
          .from('asset')
          .update(data)
          .eq('id', id)
          .select()
          .single();

      return AssetModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to return asset: $e');
    }
  }

  // Update asset status
  Future<AssetModel> updateStatus({
    required String id,
    required String status,
    String? reason,
  }) async {
    try {
      final current = await getAssetById(id);
      if (current == null) {
        throw Exception('Asset not found');
      }

      String? notes = current.notes;
      if (reason != null && reason.isNotEmpty) {
        notes =
            '${notes ?? ''}\n[STATUS CHANGE] ${current.status} → $status: $reason'
                .trim();
      }

      final data = {
        'status': status,
        'notes': notes,
      };

      final response = await _supabase
          .from('asset')
          .update(data)
          .eq('id', id)
          .select()
          .single();

      return AssetModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update status: $e');
    }
  }

  // Get assets by category
  Future<List<AssetModel>> getAssetsByCategory(String category) async {
    try {
      final response = await _supabase.from('asset').select('''
            *,
            users!asset_assigned_to_fkey(full_name)
          ''').eq('category', category).order('name', ascending: true);

      return (response as List).map((json) {
        final userData = json['users'];
        final Map<String, dynamic> assetData = Map.from(json);
        assetData.remove('users');

        if (userData != null) {
          assetData['assigned_to_name'] = userData['full_name'];
        }

        return AssetModel.fromJson(assetData);
      }).toList();
    } catch (e) {
      throw Exception('Failed to load assets by category: $e');
    }
  }

  // Get assets by status
  Future<List<AssetModel>> getAssetsByStatus(String status) async {
    try {
      final response = await _supabase.from('asset').select('''
            *,
            users!asset_assigned_to_fkey(full_name)
          ''').eq('status', status).order('name', ascending: true);

      return (response as List).map((json) {
        final userData = json['users'];
        final Map<String, dynamic> assetData = Map.from(json);
        assetData.remove('users');

        if (userData != null) {
          assetData['assigned_to_name'] = userData['full_name'];
        }

        return AssetModel.fromJson(assetData);
      }).toList();
    } catch (e) {
      throw Exception('Failed to load assets by status: $e');
    }
  }

  // Get my assigned assets (for regular users)
  Future<List<AssetModel>> getMyAssignedAssets(String userId) async {
    try {
      final response = await _supabase
          .from('asset')
          .select('''
            *,
            users!asset_assigned_to_fkey(full_name)
          ''')
          .eq('assigned_to', userId)
          .order('assigned_date', ascending: false);

      return (response as List).map((json) {
        final userData = json['users'];
        final Map<String, dynamic> assetData = Map.from(json);
        assetData.remove('users');

        if (userData != null) {
          assetData['assigned_to_name'] = userData['full_name'];
        }

        return AssetModel.fromJson(assetData);
      }).toList();
    } catch (e) {
      throw Exception('Failed to load my assets: $e');
    }
  }

  // Search assets
  Future<List<AssetModel>> searchAssets(String query) async {
    try {
      final response = await _supabase
          .from('asset')
          .select('''
            *,
            users!asset_assigned_to_fkey(full_name)
          ''')
          .or('name.ilike.%$query%,asset_code.ilike.%$query%')
          .order('name', ascending: true);

      return (response as List).map((json) {
        final userData = json['users'];
        final Map<String, dynamic> assetData = Map.from(json);
        assetData.remove('users');

        if (userData != null) {
          assetData['assigned_to_name'] = userData['full_name'];
        }

        return AssetModel.fromJson(assetData);
      }).toList();
    } catch (e) {
      throw Exception('Failed to search assets: $e');
    }
  }

  // Decrease quantity for consumable assets
  Future<AssetModel> decreaseQuantity({
    required String id,
    required int quantity,
    required String reason,
  }) async {
    try {
      final current = await getAssetById(id);
      if (current == null) {
        throw Exception('Asset not found');
      }

      if (current.category != 'consumable') {
        throw Exception('Only consumable assets can decrease quantity');
      }

      if (quantity > current.quantity) {
        throw Exception('Quantity exceeds available stock');
      }

      final newQuantity = current.quantity - quantity;
      final notes =
          '${current.notes ?? ''}\n[CONSUMED] -$quantity: $reason'.trim();

      final data = {
        'quantity': newQuantity,
        'notes': notes,
      };

      final response = await _supabase
          .from('asset')
          .update(data)
          .eq('id', id)
          .select()
          .single();

      return AssetModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to decrease quantity: $e');
    }
  }

  // Generate asset code
  Future<String> _generateAssetCode() async {
    try {
      final count = await _supabase.from('asset').select().count();

      final nextNumber = count.count + 1;
      final yearMonth =
          DateTime.now().toString().substring(0, 7).replaceAll('-', '');
      return 'AST-$yearMonth-${nextNumber.toString().padLeft(4, '0')}';
    } catch (e) {
      throw Exception('Failed to generate asset code: $e');
    }
  }
}
