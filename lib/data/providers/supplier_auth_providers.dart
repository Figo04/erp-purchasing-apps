// supplier_auth_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../repositories/supplier_auth_repository.dart';
import '../models/supplier_model.dart';

// Repository Provider
final supplierAuthRepositoryProvider = Provider<SupplierAuthRepository>((ref) {
  return SupplierAuthRepository();
});

final currentSupplierProvider = StateProvider<SupplierModel?>((ref) => null);

// Auth State Notifier
final supplierAuthStateProvider =
    StateNotifierProvider<SupplierAuthNotifier, AsyncValue<SupplierModel?>>(
        (ref) {
  return SupplierAuthNotifier(ref);
});

class SupplierAuthNotifier extends StateNotifier<AsyncValue<SupplierModel?>> {
  final Ref ref;

  SupplierAuthNotifier(this.ref) : super(const AsyncValue.data(null));

  // //  Check session aktif untuk auto-login
  // Future<void> _checkCurrentSession() async {
  //   try {
  //     print(' Checking for active session...');
  //     final repo = ref.read(supplierAuthRepositoryProvider);
  //     final supplier = await repo.getCurrentSupplier();

  //     if (supplier != null) {
  //       print('Found active session: ${supplier.name}');
  //       ref.read(currentSupplierProvider.notifier).state = supplier;
  //       state = AsyncValue.data(supplier);
  //     } else {
  //       print(' No active session');
  //     }
  //   } catch (e) {
  //     print(' Session check failed: $e');
  //     // Don't set error state, just continue
  //   }
  // }

  Future<void> signIn(String email, String password) async {
    try {
      state = const AsyncValue.loading();
      print('🔵 SupplierAuthNotifier: Sign in requested');

      final repo = ref.read(supplierAuthRepositoryProvider);
      final supplier = await repo.signIn(email: email, password: password);

      if (supplier != null) {
        print(' SupplierAuthNotifier: Sign in success');

        // Update both providers
        ref.read(currentSupplierProvider.notifier).state = supplier;
        state = AsyncValue.data(supplier);

        print(' Providers updated with supplier: ${supplier.name}');
      } else {
        throw Exception('Login gagal: supplier tidak ditemukan');
      }
    } catch (e, st) {
      print(' SupplierAuthNotifier: Sign in failed - $e');
      state = AsyncValue.error(e, st);
      rethrow; // throw lagi supaya UI bisa catch error
    }
  }

  Future<void> signOut() async {
    try {
      print('👋 SupplierAuthNotifier: Sign out requested');
      final repo = ref.read(supplierAuthRepositoryProvider);
      await repo.signOut();

      // ✅ Clear both providers
      ref.read(currentSupplierProvider.notifier).state = null;
      state = const AsyncValue.data(null);

      print('✅ SupplierAuthNotifier: Sign out complete');
    } catch (e, st) {
      print('SupplierAuthNotifier: Sign out failed - $e');
      state = AsyncValue.error(e, st);
    }
  }
}
