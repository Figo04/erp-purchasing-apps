import 'package:erp_purchasing_apps/data/providers/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:erp_purchasing_apps/data/models/purchase_requisition_model.dart';
import 'package:erp_purchasing_apps/data/repositories/pr_repository.dart';

final prRepositoryProvider = Provider<PRRepository>((ref) {
  return PRRepository();
});

final refreshTriggerProvider = StateProvider<int>((ref) => 0);


final prManualProvider =
    FutureProvider.autoDispose<List<PurchaseRequisitionModel>>((ref) async {
  ref.watch(refreshTriggerProvider);

  final supabase = Supabase.instance.client;

  print(
      '🔵 Fetching PRs manually (trigger: ${ref.read(refreshTriggerProvider)})');

  try {
    final response = await supabase
        .from('purchase_requisition')
        .select('*, purchase_requisition_item(*)')
        .order('created_at', ascending: false);

    final prs = (response as List)
        .map((json) => PurchaseRequisitionModel.fromJson(json))
        .toList();

    print('✅ Fetched ${prs.length} PRs');

    return prs;
  } catch (e) {
    print('❌ Error fetching PRs: $e');
    rethrow;
  }
});

// Keep existing providers
final prListProvider =
    FutureProvider<List<PurchaseRequisitionModel>>((ref) async {
  final repo = ref.watch(prRepositoryProvider);
  return await repo.getAllPRs();
});

final prStreamProvider = StreamProvider<List<PurchaseRequisitionModel>>((ref) {
  final supabase = Supabase.instance.client;

  return supabase
      .from('purchase_requisition')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false)
      .asyncMap(
        (data) async {
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

final pendingPRCountProvider = Provider<int>((ref) {
  final prStream = ref.watch(prStreamProvider);

  return prStream.when(
    data: (prs) => prs.where((pr) => pr.status == 'pending').length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

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
