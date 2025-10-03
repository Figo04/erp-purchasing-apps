import 'package:erp_purchasing_apps/data/providers/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:erp_purchasing_apps/data/models/purchase_requisition_model.dart';
import 'package:erp_purchasing_apps/data/repositories/pr_repository.dart';

final prRepositoryProvider = Provider<PRRepository>((ref) {
  return PRRepository();
});

final prListProvider =
    FutureProvider<List<PurchaseRequisitionModel>>((ref) async {
  final repo = ref.watch(prRepositoryProvider);
  return await repo.getAllPRs();
});

// Real-time PR Stream Provider
final prStreamProvider = StreamProvider<List<PurchaseRequisitionModel>>((ref) {
  final supabase = Supabase.instance.client;

  return supabase
      .from('purchase_requisition')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false)
      .asyncMap(
        (data) async {
          // For each PR, Fetch its items
          final List<PurchaseRequisitionModel> prs = [];

          for (var prData in data) {
            final itemsResponse = await supabase
                .from('purchase_requisition_item')
                .select()
                .eq('pr_id', prData['id']);

            prData['purchase_requisition_item'] = itemsResponse;
            prs.add(PurchaseRequisitionModel.fromJson(prData));
          }

          return prs;
        },
      );
});

// pending PR Count Provider (for notification badge)
final pendingPRCountProvider = Provider<int>((ref) {
  final prStream = ref.watch(prStreamProvider);

  return prStream.when(
    data: (prs) => prs.where((pr) => pr.status == 'pending').length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

// User's own PR Count Provider
final myPRCountProvider = Provider<int>((ref) {
  final prStream = ref.watch(prListProvider);
  final currentUser = ref.watch(currentUserProvider);

  if (currentUser == null) return 0;

  return prStream.when(
    data: (prs) => prs.where((pr) => pr.requesterId == currentUser.id).length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});
