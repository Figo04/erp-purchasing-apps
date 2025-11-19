import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:erp_purchasing_apps/data/models/lpb_model.dart';
import 'package:erp_purchasing_apps/data/repositories/lpb_repository.dart';
import 'package:flutter_riverpod/legacy.dart';

// ============================================
// REPOSITORY PROVIDER
// ============================================

final lpbRepositoryProvider = Provider<LPBRepository>((ref) {
  return LPBRepository();
});

// ============================================
// STATE CLASSES
// ============================================

/// State untuk LPB list
class LPBListState {
  final List<LPBModel> lpbs;
  final bool isLoading;
  final String? error;

  LPBListState({
    this.lpbs = const [],
    this.isLoading = false,
    this.error,
  });

  LPBListState copyWith({
    List<LPBModel>? lpbs,
    bool? isLoading,
    String? error,
  }) {
    return LPBListState(
      lpbs: lpbs ?? this.lpbs,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// State untuk single LPB detail
class LPBDetailState {
  final LPBModel? lpb;
  final bool isLoading;
  final String? error;

  LPBDetailState({
    this.lpb,
    this.isLoading = false,
    this.error,
  });

  LPBDetailState copyWith({
    LPBModel? lpb,
    bool? isLoading,
    String? error,
  }) {
    return LPBDetailState(
      lpb: lpb ?? this.lpb,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ============================================
// STATE NOTIFIERS
// ============================================

/// LPB List State Notifier
class LPBListNotifier extends StateNotifier<LPBListState> {
  final LPBRepository _repository;

  LPBListNotifier(this._repository) : super(LPBListState());

  /// Load all LPBs with filters
  Future<void> loadLPBs({
    String? poId,
    String? supplierId,
    String? receivedBy,
    String? status,
    String? search,
    String? fromDate,
    String? toDate,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final lpbs = await _repository.getAllLPBs(
        poId: poId,
        supplierId: supplierId,
        receivedBy: receivedBy,
        status: status,
        search: search,
        fromDate: fromDate,
        toDate: toDate,
      );

      state = state.copyWith(
        lpbs: lpbs,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Refresh LPBs (manual reload)
  Future<void> refresh() async {
    await loadLPBs();
  }

  /// Filter by status
  void filterByStatus(String? status) {
    loadLPBs(status: status);
  }

  /// Search LPBs
  void search(String query) {
    loadLPBs(search: query);
  }

  /// Delete LPB
  Future<bool> deleteLPB(String lpbId) async {
    try {
      await _repository.deleteLPB(lpbId);
      // Reload list after delete
      await refresh();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Complete LPB
  Future<bool> completeLPB(String lpbId, {String? notes}) async {
    try {
      await _repository.completeLPB(lpbId, notes: notes);
      // Reload list after complete
      await refresh();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

/// LPB Detail State Notifier
class LPBDetailNotifier extends StateNotifier<LPBDetailState> {
  final LPBRepository _repository;

  LPBDetailNotifier(this._repository) : super(LPBDetailState());

  /// Load LPB by ID
  Future<void> loadLPB(String id) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final lpb = await _repository.getLPBById(id);

      state = state.copyWith(
        lpb: lpb,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Create LPB
  Future<LPBModel?> createLPB({
    required String poId,
    String? shipmentId,
    DateTime? receiptDate,
    String? invoiceNumber,
    double? invoiceAmount,
    String? notes,
    required List<Map<String, dynamic>> items,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final lpb = await _repository.createLPB(
        poId: poId,
        shipmentId: shipmentId,
        receiptDate: receiptDate,
        invoiceNumber: invoiceNumber,
        invoiceAmount: invoiceAmount,
        notes: notes,
        items: items,
      );

      state = state.copyWith(
        lpb: lpb,
        isLoading: false,
      );

      return lpb;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return null;
    }
  }

  /// Create LPB from Shipment
  Future<LPBModel?> createLPBFromShipment(String shipmentId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final lpb = await _repository.createLPBFromShipment(shipmentId);

      state = state.copyWith(
        lpb: lpb,
        isLoading: false,
      );

      return lpb;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return null;
    }
  }

  /// Clear current LPB
  void clear() {
    state = LPBDetailState();
  }
}

// ============================================
// PROVIDERS
// ============================================

/// LPB List Provider
final lpbListProvider =
    StateNotifierProvider<LPBListNotifier, LPBListState>((ref) {
  final repository = ref.watch(lpbRepositoryProvider);
  return LPBListNotifier(repository);
});

/// LPB Detail Provider
final lpbDetailProvider =
    StateNotifierProvider<LPBDetailNotifier, LPBDetailState>((ref) {
  final repository = ref.watch(lpbRepositoryProvider);
  return LPBDetailNotifier(repository);
});

// ============================================
// COMPUTED PROVIDERS (Helpers)
// ============================================

/// Get LPBs by PO
final lpbsByPOProvider =
    FutureProvider.family<List<LPBModel>, String>((ref, poId) async {
  final repo = ref.watch(lpbRepositoryProvider);
  return await repo.getLPBsByPO(poId);
});

/// Draft LPBs count
final draftLPBsCountProvider = Provider<int>((ref) {
  final state = ref.watch(lpbListProvider);
  return state.lpbs.where((lpb) => lpb.status == 'draft').length;
});

/// Completed LPBs count
final completedLPBsCountProvider = Provider<int>((ref) {
  final state = ref.watch(lpbListProvider);
  return state.lpbs.where((lpb) => lpb.status == 'completed').length;
});

/// Unpaid LPBs count
final unpaidLPBsCountProvider = Provider<int>((ref) {
  final state = ref.watch(lpbListProvider);
  return state.lpbs
      .where((lpb) => lpb.paymentStatus == 'unpaid' && lpb.status == 'completed')
      .length;
});

// ============================================
// AUTO-LOAD PROVIDER (Optional - for dashboard)
// ============================================

/// Auto-load LPBs on provider initialization
final autoLoadLPBsProvider = Provider<void>((ref) {
  // Auto-load ketika pertama kali provider dibuat
  Future.microtask(() {
    ref.read(lpbListProvider.notifier).loadLPBs();
  });
});