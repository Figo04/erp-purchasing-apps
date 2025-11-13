import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:erp_purchasing_apps/data/models/purchase_requisition_model.dart';
import 'package:erp_purchasing_apps/data/repositories/pr_repository.dart';
import 'package:erp_purchasing_apps/data/providers/auth_providers.dart';

// PR Repository Provider
final prRepositoryProvider = Provider<PRRepository>((ref) {
  return PRRepository();
});

// PR List Provider
final prListProvider =
    FutureProvider<List<PurchaseRequisitionModel>>((ref) async {
  final repo = ref.watch(prRepositoryProvider);
  return await repo.getAllPRs();
});

// Selected PR Provider
final selectedPRovider =
    StateProvider<PurchaseRequisitionModel?>((ref) => null);

// PR Status Filter Provider
final prStatusFilterProvider = StateProvider<String?>((ref) => null);

// PR Year Filter Provider
final prYearFilterProvider = StateProvider<int?>((ref) => null);

// Filtered PRs Provider
final filteredPRsProvider =
    FutureProvider<List<PurchaseRequisitionModel>>((ref) async {
  final repo = ref.watch(prRepositoryProvider);
  final statusFilter = ref.watch(prStatusFilterProvider);
  final yearFilter = ref.watch(prYearFilterProvider);

  return await repo.getAllPRs(
    status: statusFilter,
    year: yearFilter,
  );
});

// Pending PR Count Provider
final pendingPRCountProvider = Provider<int>((ref) {
  final prList = ref.watch(prListProvider);

  return prList.when(
    data: (prs) => prs.where((pr) => pr.status == 'pending').length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// My PR Count Provider
final myPRCountProvider = Provider<int>((ref) {
  final prList = ref.watch(prListProvider);
  final currentUser = ref.watch(currentUserProvider);

  if (currentUser == null) return 0;

  return prList.when(
    data: (prs) => prs.where((pr) => pr.requesterId == currentUser.id).length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

// PR State Notifer
class PRNotifier
    extends StateNotifier<AsyncValue<List<PurchaseRequisitionModel>>> {
  final PRRepository _repository;
  final Ref ref;

  PRNotifier(this.ref, this._repository) : super(const AsyncValue.loading()) {
    loadPRs();
  }

  // Load all PRs
  Future<void> loadPRs() async {
    try {
      state = const AsyncValue.loading();
      final prs = await _repository.getAllPRs();
      state = AsyncValue.data(prs);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  // Create new PR
  Future<void> createPR(CreatePRRequest request) async {
    try {
      await _repository.createPR(request);
      await loadPRs();
    } catch (e) {
      rethrow;
    }
  }

  // Update PR
  Future<void> updatePR(String id, UpdatePRRequest request) async {
    try {
      await _repository.updatePR(id, request);
      await loadPRs();
    } catch (e) {
      rethrow;
    }
  }

  // Delete PR
  Future<void> deletePR(String id) async {
    try {
      await _repository.deletePR(id);
      await loadPRs();
    } catch (e) {
      rethrow;
    }
  }

  // Approve PR
  Future<void> approvePR(String id) async {
    try {
      await _repository.approvePR(id);
      await loadPRs();
    } catch (e) {
      rethrow;
    }
  }

  // Reject PR
  Future<void> rejectPR(String id, String reason) async {
    try {
      await _repository.rejectPR(id, reason);
      await loadPRs();
    } catch (e) {
      rethrow;
    }
  }

  // Delete PR
  Future<void> closePR(String id) async {
    try {
      await _repository.closePR(id);
      await loadPRs();
    } catch (e) {
      rethrow;
    }
  }

  // Refresh PRs
  Future<void> refresh() async {
    await loadPRs();
  }

  // Load PRs by status
  Future<void> loadPRsByStatus(String status) async {
    try {
      state = const AsyncValue.loading();
      final prs = await _repository.getAllPRs(status: status);
      state = AsyncValue.data(prs);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

/// PR State Notifier Provider
final prNotifierProvider =
    StateNotifierProvider<PRNotifier, AsyncValue<List<PurchaseRequisitionModel>>>(
        (ref) {
  final repository = ref.watch(prRepositoryProvider);
  return PRNotifier(ref, repository);
});

/// Refresh Trigger Provider (for manual refresh)
final refreshTriggerProvider = StateProvider<int>((ref) => 0);

/// Is Refreshing Provider
final isRefreshingProvider = StateProvider<bool>((ref) => false);

/// Manual Refresh Provider
final prManualProvider =
    FutureProvider.autoDispose<List<PurchaseRequisitionModel>>((ref) async {
  ref.watch(refreshTriggerProvider);

  try {
    ref.read(isRefreshingProvider.notifier).state = true;
    final repo = ref.read(prRepositoryProvider);
    final prs = await repo.getAllPRs();
    ref.read(isRefreshingProvider.notifier).state = false;
    return prs;
  } catch (e) {
    ref.read(isRefreshingProvider.notifier).state = false;
    rethrow;
  }
});

/// Stream-like Provider (polling every 30s)
/// Replaces Supabase realtime stream
final prStreamProvider =
    StreamProvider<List<PurchaseRequisitionModel>>((ref) {
  return Stream.periodic(const Duration(seconds: 30), (_) async {
    final repo = ref.read(prRepositoryProvider);
    return await repo.getAllPRs();
  }).asyncMap((future) => future);
});