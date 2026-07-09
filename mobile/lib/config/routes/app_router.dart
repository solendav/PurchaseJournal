import 'package:go_router/go_router.dart';
import 'package:purchase_journal/config/routes/route_names.dart';
import 'package:purchase_journal/core/auth/auth_session.dart';
import 'package:purchase_journal/features/auth/presentation/pages/login_page.dart';
import 'package:purchase_journal/features/auth/presentation/pages/register_page.dart';
import 'package:purchase_journal/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:purchase_journal/features/dashboard/presentation/pages/main_shell.dart';
import 'package:purchase_journal/features/profile/presentation/pages/profile_page.dart';
import 'package:purchase_journal/features/purchases/presentation/pages/payment_detail_page.dart';
import 'package:purchase_journal/features/purchases/presentation/pages/purchase_detail_page.dart';
import 'package:purchase_journal/features/purchases/presentation/pages/purchase_form_page.dart';
import 'package:purchase_journal/features/purchases/presentation/pages/purchase_list_page.dart';
import 'package:purchase_journal/features/purchases/presentation/pages/scan_receipt_page.dart';
import 'package:purchase_journal/features/suppliers/presentation/pages/supplier_detail_page.dart';
import 'package:purchase_journal/features/suppliers/presentation/pages/supplier_list_page.dart';

GoRouter createAppRouter(AuthSession authSession) {
  return GoRouter(
    initialLocation: RouteNames.home,
    refreshListenable: authSession,
    redirect: (context, state) {
      final loggedIn = authSession.isAuthenticated;
      final onAuth = state.matchedLocation == RouteNames.login ||
          state.matchedLocation == RouteNames.register;
      if (!loggedIn && !onAuth) return RouteNames.login;
      if (loggedIn && onAuth) return RouteNames.home;
      return null;
    },
    routes: [
      GoRoute(path: RouteNames.login, builder: (_, __) => const LoginPage()),
      GoRoute(path: RouteNames.register, builder: (_, __) => const RegisterPage()),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: RouteNames.home, builder: (_, __) => const DashboardTab()),
          GoRoute(path: RouteNames.purchases, builder: (_, __) => const PurchaseListPage()),
          GoRoute(path: RouteNames.suppliers, builder: (_, __) => const SupplierListPage()),
          GoRoute(path: RouteNames.profile, builder: (_, __) => const ProfilePage()),
        ],
      ),
      GoRoute(
        path: RouteNames.purchaseNew,
        builder: (context, state) => PurchaseFormPage(
          initialSupplierId: state.uri.queryParameters['supplierId'],
        ),
      ),
      GoRoute(
        path: RouteNames.purchaseScan,
        builder: (context, state) => ScanReceiptPage(
          initialSupplierId: state.uri.queryParameters['supplierId'],
        ),
      ),
      GoRoute(
        path: '${RouteNames.purchaseDetail}/:id/edit',
        builder: (context, state) => PurchaseFormPage(purchaseId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '${RouteNames.purchaseDetail}/:id',
        builder: (context, state) => PurchaseDetailPage(purchaseId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '${RouteNames.paymentDetail}/:id',
        builder: (context, state) => PaymentDetailPage(paymentId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: RouteNames.supplierDetail,
        builder: (context, state) => SupplierDetailPage(supplierId: state.pathParameters['id']!),
      ),
    ],
  );
}
