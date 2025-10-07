import 'package:erp_purchasing_apps/presentation/screens/purchase%20order/po_approval_screen.dart';
import 'package:erp_purchasing_apps/presentation/screens/purchase%20order/po_list_screen.dart';
import 'package:erp_purchasing_apps/presentation/screens/purchase%20requisition/pr_approval_history_screen.dart';
import 'package:erp_purchasing_apps/presentation/screens/purchase%20requisition/pr_approval_screen.dart';
import 'package:erp_purchasing_apps/presentation/screens/purchase%20requisition/pr_list_screen,.dart';
import 'package:erp_purchasing_apps/presentation/screens/supplier/supplier_list_screen.dart';
import 'package:erp_purchasing_apps/presentation/screens/user/user_list_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:erp_purchasing_apps/data/providers/auth_providers.dart';
import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/dashboard/dashboard_screen.dart';
// import '../presentation/screens/auth/register_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final currentPath = state.matchedLocation;

      // Allow access to login and register pages when not logged in
      if (!isLoggedIn &&
          (currentPath == '/login' || currentPath == '/register')) {
        return null; // Allow access
      }

      // Redirect to login if not logged in and trying to access other pages
      if (!isLoggedIn) {
        return '/login';
      }

      // Redirect to dashboard if logged in and on login/register page
      if (isLoggedIn &&
          (currentPath == '/login' || currentPath == '/register')) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      // GoRoute(
      //   path: '/register',
      //   builder: (context, state) => const RegisterScreen(),
      // ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/suppliers',
        builder: (context, state) => const SupplierListScreen(),
      ),
      GoRoute(
        path: '/users',
        builder: (context, state) => const UserListScreen(),
      ),
      GoRoute(
        path: '/pr',
        builder: (context, state) => const PRListScreen(),
      ),
      GoRoute(
        path: '/po',
        builder: (context, state) => const POListScreen(),
      ),
      GoRoute(
        path: '/pr-approval',
        builder: (context, state) => const PRApprovalScreen(),
      ),
      GoRoute(
        path: '/po-approval',
        builder: (context, state) => const POApprovalScreen(),
      ),
      GoRoute(
        path: '/pr-history',
        builder: (context, state) => const PRApprovalHistoryScreen(),
      ),
    ],
  );
});
