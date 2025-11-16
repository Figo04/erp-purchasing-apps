import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:erp_purchasing_apps/data/models/division_model.dart';
import 'package:erp_purchasing_apps/data/repositories/division_repository.dart';
import 'package:flutter_riverpod/legacy.dart';

/// Division Repository Provider
final divisionRepositoryProvider = Provider<DivisionRepository>((ref) {
  return DivisionRepository();
});

/// All Divisions Provider (with cache)
final divisionListProvider = FutureProvider.autoDispose<List<DivisionModel>>((ref) async {
  // Keep data alive even when widget is disposed
  ref.keepAlive();
  
  final repo = ref.watch(divisionRepositoryProvider);
  return await repo.getAllDivisions();
});

/// Active Divisions Only Provider (for dropdowns)
final activeDivisionListProvider = FutureProvider.autoDispose<List<DivisionModel>>((ref) async {
  // Keep data alive for better UX
  ref.keepAlive();
  
  final repo = ref.watch(divisionRepositoryProvider);
  return await repo.getAllDivisions(isActive: true);
});

/// Selected Division Provider (for forms)
final selectedDivisionProvider = StateProvider<DivisionModel?>((ref) => null);

/// Division by ID Provider
final divisionByIdProvider = FutureProvider.family<DivisionModel, String>((ref, id) async {
  final repo = ref.watch(divisionRepositoryProvider);
  return await repo.getDivisionById(id);
});

/// Division Map Provider (for quick lookups)
final divisionMapProvider = Provider<Map<String, DivisionModel>>((ref) {
  final divisionsAsync = ref.watch(divisionListProvider);
  
  return divisionsAsync.when(
    data: (divisions) {
      return {
        for (var div in divisions) div.id: div,
      };
    },
    loading: () => {},
    error: (_, __) => {},
  );
});