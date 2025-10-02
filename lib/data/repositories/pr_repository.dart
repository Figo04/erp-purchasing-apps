import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/purchase_requisition_model.dart';

class PRRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get all PRs
  Future<List<PurchaseRequisitionModel>> getAllPRs() async {
    try {
      final response = await _supabase
          .from('purchase_requisition')
          .select('*, purchase_requisition_item(*)')
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => PurchaseRequisitionModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load PRs: $e');
    }
  }

  // Get PRs by user
  Future<List<PurchaseRequisitionModel>> getPRsByUser(String userId) async {
    try {
      final response = await _supabase
          .from('purchase_requisition')
          .select('*, purchase_requisition_item(*)')
          .eq('requester_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => PurchaseRequisitionModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load user PRs: $e');
    }
  }

  // Get PR by ID
  Future<PurchaseRequisitionModel?> getPRById(String id) async {
    try {
      final response = await _supabase
          .from('purchase_requisition')
          .select('*, purchase_requisition_item(*)')
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return PurchaseRequisitionModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to load PR: $e');
    }
  }

  // Generate PR Number
  Future<String> generatePRNumber() async {
    try {
      final response = await _supabase.rpc('generate_pr_number');
      return response as String;
    } catch (e) {
      // Fallback if function not available
      final now = DateTime.now();
      final countResponse =
          await _supabase.from('purchase_requisition').select().count();

      final count = countResponse.count; // Ambil count dari response
      return 'PR-${now.year}${now.month.toString().padLeft(2, '0')}-${(count + 1).toString().padLeft(4, '0')}';
    }
  }

  // Create PR with items
  Future<PurchaseRequisitionModel> createPR({
    required String requesterId,
    required List<Map<String, dynamic>> items,
    String? notes,
  }) async {
    try {
      // Generate PR number
      final prNumber = await generatePRNumber();

      // Insert PR
      final prResponse = await _supabase
          .from('purchase_requisition')
          .insert({
            'pr_number': prNumber,
            'requester_id': requesterId,
            'status': 'draft',
            'notes': notes,
          })
          .select()
          .single();

      final prId = prResponse['id'];

      // Insert PR Items
      final itemsData = items.map((item) {
        return {
          'pr_id': prId,
          'item_name': item['item_name'],
          'quantity': item['quantity'],
          'unit': item['unit'] ?? 'pcs',
          'estimated_price': item['estimated_price'],
          'notes': item['notes'],
        };
      }).toList();

      await _supabase.from('purchase_requisition_item').insert(itemsData);

      // Get complete PR with items
      final createdPR = await getPRById(prId);
      if (createdPR == null) {
        throw Exception('Failed to retrieve created PR');
      }
      return createdPR;
    } catch (e) {
      throw Exception('Failed to create PR: $e');
    }
  }

  // Update PR (only draft)
  Future<PurchaseRequisitionModel> updatePR({
    required String id,
    required List<Map<String, dynamic>> items,
    String? notes,
  }) async {
    try {
      // Update PR
      await _supabase
          .from('purchase_requisition')
          .update({'notes': notes}).eq('id', id);

      // Delete old items
      await _supabase
          .from('purchase_requisition_item')
          .delete()
          .eq('pr_id', id);

      // Insert new items
      final itemsData = items.map((item) {
        return {
          'pr_id': id,
          'item_name': item['item_name'],
          'quantity': item['quantity'],
          'unit': item['unit'] ?? 'pcs',
          'estimated_price': item['estimated_price'],
          'notes': item['notes'],
        };
      }).toList();

      await _supabase.from('purchase_requisition_item').insert(itemsData);

      // Get updated PR

      final createdPR = await getPRById(id);
      if (createdPR == null) {
        throw Exception('Failed to retrieve created PR');
      }
      return createdPR;
    } catch (e) {
      throw Exception('Failed to update PR: $e');
    }
  }

  // Submit PR (change status to pending)
  Future<void> submitPR(String id) async {
    try {
      await _supabase
          .from('purchase_requisition')
          .update({'status': 'pending'}).eq('id', id);
    } catch (e) {
      throw Exception('Failed to submit PR: $e');
    }
  }

  // Approve PR
  Future<void> approvePR(String id, String approvedBy) async {
    try {
      await _supabase.from('purchase_requisition').update({
        'status': 'approved',
        'approved_by': approvedBy,
        'approved_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
    } catch (e) {
      throw Exception('Failed to approve PR: $e');
    }
  }

  // Reject PR
  Future<void> rejectPR(String id, String approvedBy, String reason) async {
    try {
      await _supabase.from('purchase_requisition').update({
        'status': 'rejected',
        'approved_by': approvedBy,
        'approved_at': DateTime.now().toIso8601String(),
        'rejection_reason': reason,
      }).eq('id', id);
    } catch (e) {
      throw Exception('Failed to reject PR: $e');
    }
  }

  // Delete PR (only draft)
  Future<void> deletePR(String id) async {
    try {
      await _supabase.from('purchase_requisition').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete PR: $e');
    }
  }
}
