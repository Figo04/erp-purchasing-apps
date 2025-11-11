import 'package:erp_purchasing_apps/data/models/user_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:erp_purchasing_apps/data/models/auth_model.dart';
import 'package:erp_purchasing_apps/data/repositories/auth_repository.dart';
import 'package:flutter_riverpod/legacy.dart';

/// Auth Repository Provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Current User Provider
/// Holds the currently logged-in user data
final currentUserProvider = StateProvider<UserModel?>((ref) => null);

/// Auth State Provider
/// Manages authentication state and operations
final authStateProvider =
    StateNotifierProvider<AuthStateNotifier, AsyncValue<UserModel?>>((ref) {
  return AuthStateNotifier(ref);
});

/// Auth State Notifier
/// Handles login, logout, and session management
class AuthStateNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final Ref ref;
  late final AuthRepository _authRepo;

  AuthStateNotifier(this.ref) : super(const AsyncValue.data(null)) {
    _authRepo = ref.read(authRepositoryProvider);
    _initializeAuth();
  }

  /// Initialize authentication on app start
  /// Checks if user has valid session
  Future<void> _initializeAuth() async {
    try {
      print('🔵 AuthStateNotifier: Initializing auth...');
      
      final isLoggedIn = await _authRepo.isLoggedIn();
      
      if (isLoggedIn) {
        print('🔵 AuthStateNotifier: Token found, validating session...');
        final user = await _authRepo.getCurrentUser();
        ref.read(currentUserProvider.notifier).state = user;
        state = AsyncValue.data(user);
        print('✅ AuthStateNotifier: Session valid');
      } else {
        print('ℹ️ AuthStateNotifier: No active session');
        state = const AsyncValue.data(null);
      }
    } catch (e, stackTrace) {
      print('❌ AuthStateNotifier: Initialization failed - $e');
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Sign In
  /// Authenticates user with email and password
  Future<void> signIn(String email, String password) async {
    try {
      print('🔵 AuthStateNotifier: Starting sign in...');
      state = const AsyncValue.loading();

      final loginResponse = await _authRepo.signIn(
        email: email,
        password: password,
      );

      // Update user state
      ref.read(currentUserProvider.notifier).state = loginResponse.user;
      state = AsyncValue.data(loginResponse.user);

      print('✅ AuthStateNotifier: Sign in successful');
      print('👤 Welcome ${loginResponse.user.displayName}!');
    } catch (e, stackTrace) {
      print('❌ AuthStateNotifier: Sign in failed - $e');
      ref.read(currentUserProvider.notifier).state = null;
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Sign Out
  /// Logs out user and clears session
  Future<void> signOut() async {
    try {
      print('🔵 AuthStateNotifier: Signing out...');
      
      await _authRepo.signOut();
      
      // Clear user state
      ref.read(currentUserProvider.notifier).state = null;
      state = const AsyncValue.data(null);

      print('✅ AuthStateNotifier: Sign out successful');
    } catch (e, stackTrace) {
      print('❌ AuthStateNotifier: Sign out failed - $e');
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Register (admin creates user)
  Future<void> register({
    required String username,
    required String email,
    required String password,
    String? fullName,
    required String role,
    String? divisionId,
  }) async {
    try {
      print('🔵 AuthStateNotifier: Starting registration...');
      state = const AsyncValue.loading();

      final loginResponse = await _authRepo.register(
        username: username,
        email: email,
        password: password,
        fullName: fullName,
        role: role,
        divisionId: divisionId,
      );

      // Update user state
      ref.read(currentUserProvider.notifier).state = loginResponse.user;
      state = AsyncValue.data(loginResponse.user);

      print('✅ AuthStateNotifier: Registration successful');
    } catch (e, stackTrace) {
      print('❌ AuthStateNotifier: Registration failed - $e');
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Refresh user profile
  /// Fetches latest user data from backend
  Future<void> refreshProfile() async {
    try {
      print('🔵 AuthStateNotifier: Refreshing profile...');
      
      final user = await _authRepo.getCurrentUser();
      ref.read(currentUserProvider.notifier).state = user;
      state = AsyncValue.data(user);

      print('✅ AuthStateNotifier: Profile refreshed');
    } catch (e, stackTrace) {
      print('❌ AuthStateNotifier: Profile refresh failed - $e');
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Check if user is authenticated
  bool get isAuthenticated {
    return state.value != null;
  }

  /// Get current user
  UserModel? get currentUser {
    return state.value;
  }
}

/// Helper provider to check authentication status
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.value != null;
});

/// Helper provider to get current user role
final currentUserRoleProvider = Provider<String?>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.role;
});

/// Helper provider to check if user is admin
final isAdminProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.isAdmin ?? false;
});

/// Helper provider to check if user is kadiv
final isKadivProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.isKadiv ?? false;
});