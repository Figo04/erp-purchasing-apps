import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:erp_purchasing_apps/data/providers/auth_providers.dart';
import 'package:erp_purchasing_apps/presentation/screens/supplier_portal/supplier_login_screen.dart';
import 'package:erp_purchasing_apps/presentation/screens/supplier_portal/supplier_dashboard_screen.dart';
import 'package:erp_purchasing_apps/presentation/screens/supplier_portal/supplier_po_list_screen.dart';
import 'package:erp_purchasing_apps/presentation/screens/supplier_portal/supplier_shipment_form_screen.dart';
import 'package:erp_purchasing_apps/presentation/screens/supplier_portal/supplier_shipment_list_screen.dart';

class SupplierPortalApp extends ConsumerWidget {
  const SupplierPortalApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = _createRouter(ref);

    return MaterialApp.router(
      title: 'Supplier Portal',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }

  GoRouter _createRouter(WidgetRef ref) {
    return GoRouter(
      initialLocation: '/supplier/login',
      redirect: (context, state) {
        final currentUser = ref.read(currentUserProvider);
        final isLoggedIn = currentUser != null;
        final isLoggingIn = state.matchedLocation == '/supplier/login';

        if (!isLoggedIn && !isLoggingIn) {
          return '/supplier/login';
        }

        if (isLoggedIn && isLoggingIn) {
          return '/supplier/dashboard';
        }

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
}
