import 'package:flutter_riverpod/flutter_riverpod.dart';
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
