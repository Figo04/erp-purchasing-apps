import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../models/user_model.dart';
import '../repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final currentUserProvider = StateProvider<UserModel?>((ref) => null);

final authStateProvider =
    StateNotifierProvider<AuthStateNotifier, AsyncValue<UserModel?>>((ref) {
  return AuthStateNotifier(ref);
});

class AuthStateNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final Ref ref;

  // Future<void> signUp({
  //   required String email,
  //   required String password,
  //   required String username,
  //   required String fullName,
  //   required String role,
  // }) async {
  //   try {
  //     state = const AsyncValue.loading();
  //     final authRepo = ref.read(authRepositoryProvider);
  //     final user = await authRepo.signUp(
  //       email: email,
  //       password: password,
  //       username: username,
  //       fullName: fullName,
  //       role: role,
  //     );

  //     if (user != null) {
  //       ref.read(currentUserProvider.notifier).state = user;
  //       state = AsyncValue.data(user);
  //     } else {
  //       throw Exception('Registration failed');
  //     }
  //   } catch (e) {
  //     state = AsyncValue.error(e, StackTrace.current);
  //   }
  // }

  AuthStateNotifier(this.ref) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    try {
      final authRepo = ref.read(authRepositoryProvider);
      final user = await authRepo.getCurrentUser();
      state = AsyncValue.data(user);
      if (user != null) {
        ref.read(currentUserProvider.notifier).state = user;
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> signIn(String email, String password) async {
    try {
      state = const AsyncValue.loading();
      final authRepo = ref.read(authRepositoryProvider);
      final user = await authRepo.signIn(email: email, password: password);

      if (user != null) {
        ref.read(currentUserProvider.notifier).state = user;
        state = AsyncValue.data(user);
      } else {
        throw Exception('Login failed');
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> signOut() async {
    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.signOut();
      ref.read(currentUserProvider.notifier).state = null;
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}
