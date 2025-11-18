import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:erp_purchasing_apps/data/models/shipment_model.dart';
import 'package:erp_purchasing_apps/data/repositories/shipment_repository.dart';
import 'package:flutter_riverpod/legacy.dart';

final shipmentRepositoryProvider = Provider<ShipmentRepository>((ref) {
  return ShipmentRepository();
});

// ============================================
// STATE CLASSES
// ============================================

/// State untuk shipment list
class ShipmentListState {
  final List<ShipmentModel> shipments;
  final bool isLoading;
  final String? error;

  ShipmentListState({
    this.shipments = const [],
    this.isLoading = false,
    this.error,
  });

  ShipmentListState copyWith({
    List<ShipmentModel>? shipments,
    bool? isLoading,
    String? error,
  }) {
    return ShipmentListState(
      shipments: shipments ?? this.shipments,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// State untuk single shipment detail
class ShipmentDetailState {
  final ShipmentModel? shipment;
  final bool isLoading;
  final String? error;

  ShipmentDetailState({
    this.shipment,
    this.isLoading = false,
    this.error,
  });

  ShipmentDetailState copyWith({
    ShipmentModel? shipment,
    bool? isLoading,
    String? error,
  }) {
    return ShipmentDetailState(
      shipment: shipment ?? this.shipment,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ============================================
// STATE NOTIFIERS
// ============================================

/// Shipment List State Notifier
class ShipmentListNotifier extends StateNotifier<ShipmentListState> {
  final ShipmentRepository _repository;

  ShipmentListNotifier(this._repository) : super(ShipmentListState());

  /// Load all shipments with filters
  Future<void> loadShipments({
    String? poId,
    String? supplierId,
    String? status,
    String? search,
    String? fromDate,
    String? toDate,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final shipments = await _repository.getAllShipments(
        poId: poId,
        supplierId: supplierId,
        status: status,
        search: search,
        fromDate: fromDate,
        toDate: toDate,
      );

      state = state.copyWith(
        shipments: shipments,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Refresh shipments (manual reload)
  Future<void> refresh() async {
    await loadShipments();
  }

  /// Filter by status
  void filterByStatus(String? status) {
    loadShipments(status: status);
  }

  /// Search shipments
  void search(String query) {
    loadShipments(search: query);
  }
}

/// Shipment Detail State Notifier
class ShipmentDetailNotifier extends StateNotifier<ShipmentDetailState> {
  final ShipmentRepository _repository;

  ShipmentDetailNotifier(this._repository) : super(ShipmentDetailState());

  /// Load shipment by ID
  Future<void> loadShipment(String id) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final shipment = await _repository.getShipmentById(id);

      state = state.copyWith(
        shipment: shipment,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Scan QR Code
  Future<ShipmentModel?> scanQR(String qrCodeData) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final shipment = await _repository.scanQRCode(qrCodeData);

      state = state.copyWith(
        shipment: shipment,
        isLoading: false,
      );

      return shipment;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return null;
    }
  }

  /// Clear current shipment
  void clear() {
    state = ShipmentDetailState();
  }
}

// ============================================
// PROVIDERS
// ============================================

/// Shipment List Provider
final shipmentListProvider =
    StateNotifierProvider<ShipmentListNotifier, ShipmentListState>((ref) {
  final repository = ref.watch(shipmentRepositoryProvider);
  return ShipmentListNotifier(repository);
});

/// Shipment Detail Provider
final shipmentDetailProvider =
    StateNotifierProvider<ShipmentDetailNotifier, ShipmentDetailState>((ref) {
  final repository = ref.watch(shipmentRepositoryProvider);
  return ShipmentDetailNotifier(repository);
});

// ============================================
// COMPUTED PROVIDERS (Helpers)
// ============================================

/// Get shipments by PO
final shipmentsByPOProvider =
    FutureProvider.family<List<ShipmentModel>, String>((ref, poId) async {
  final repo = ref.watch(shipmentRepositoryProvider);
  return await repo.getShipmentsByPO(poId);
});

/// Pending shipments count
final pendingShipmentsCountProvider = Provider<int>((ref) {
  final state = ref.watch(shipmentListProvider);
  return state.shipments.where((s) => s.status == 'pending').length;
});

/// Received shipments count
final receivedShipmentsCountProvider = Provider<int>((ref) {
  final state = ref.watch(shipmentListProvider);
  return state.shipments.where((s) => s.status == 'received').length;
});

/// Partial shipments count
final partialShipmentsCountProvider = Provider<int>((ref) {
  final state = ref.watch(shipmentListProvider);
  return state.shipments.where((s) => s.status == 'partial').length;
});

// ============================================
// AUTO-LOAD PROVIDER (Optional - for dashboard)
// ============================================

/// Auto-load shipments on provider initialization
final autoLoadShipmentsProvider = Provider<void>((ref) {
  // Auto-load ketika pertama kali provider dibuat
  Future.microtask(() {
    ref.read(shipmentListProvider.notifier).loadShipments();
  });
});