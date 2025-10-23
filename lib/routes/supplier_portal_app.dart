import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:erp_purchasing_apps/data/providers/supplier_auth_providers.dart';
import 'package:erp_purchasing_apps/presentation/screens/supplier_portal/supplier_login_screen.dart';
import 'package:erp_purchasing_apps/presentation/screens/supplier_portal/supplier_dashboard_screen.dart';
import 'package:erp_purchasing_apps/presentation/screens/supplier_portal/supplier_po_list_screen.dart';
import 'package:erp_purchasing_apps/presentation/screens/supplier_portal/supplier_shipment_form_screen.dart';
import 'package:erp_purchasing_apps/presentation/screens/supplier_portal/supplier_shipment_list_screen.dart';

class SupplierPortalApp extends ConsumerStatefulWidget {
  const SupplierPortalApp({super.key});

  @override
  ConsumerState<SupplierPortalApp> createState() => _SupplierPortalAppState();
}

class _SupplierPortalAppState extends ConsumerState<SupplierPortalApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = _createRouter();
  }

  GoRouter _createRouter() {
    return GoRouter(
      initialLocation: '/supplier/login',
      debugLogDiagnostics: true,
      redirect: (context, state) {
        // ✅ Check current supplier dari provider
        final currentSupplier = ref.read(currentSupplierProvider);
        final isLoggedIn = currentSupplier != null;
        final isLoggingIn = state.matchedLocation == '/supplier/login';

        print('🔄 GoRouter redirect check:');
        print('   - Supplier: ${currentSupplier?.name}');
        print('   - Email: ${currentSupplier?.email}');
        print('   - isLoggedIn: $isLoggedIn');
        print('   - current location: ${state.matchedLocation}');

        // Jika belum login dan bukan di halaman login -> redirect ke login
        if (!isLoggedIn && !isLoggingIn) {
          print('   ➡️ Redirecting to login (not authenticated)');
          return '/supplier/login';
        }

        // Jika sudah login dan masih di halaman login -> redirect ke dashboard
        if (isLoggedIn && isLoggingIn) {
          print('   ➡️ Redirecting to dashboard (already authenticated)');
          return '/supplier/dashboard';
        }

        print('   ✅ No redirect needed');
        return null;
      },
      routes: [
        GoRoute(
          path: '/supplier/login',
          builder: (context, state) => const SupplierLoginScreen(),
        ),
        GoRoute(
          path: '/supplier/dashboard',
          builder: (context, state) => const SupplierDashboardScreen(),
        ),
        GoRoute(
          path: '/supplier/pos',
          builder: (context, state) => const SupplierPOListScreen(),
        ),
        GoRoute(
          path: '/supplier/shipments',
          builder: (context, state) => const SupplierShipmentListScreen(),
        ),
        GoRoute(
          path: '/supplier/shipment/create',
          builder: (context, state) {
            final poId = state.uri.queryParameters['poId'];
            return SupplierShipmentFormScreen(poId: poId);
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Listen ke perubahan supplier auth dan refresh router
    ref.listen(currentSupplierProvider, (previous, next) {
      print(' Supplier auth state changed:');
      print('   - Previous: ${previous?.name}');
      print('   - Next: ${next?.name}');
      print('   - Refreshing router...');
      _router.refresh();
    });

    return MaterialApp.router(
      title: 'Supplier Portal',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}