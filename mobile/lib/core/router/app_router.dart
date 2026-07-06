import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../network/api_client.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/dashboard/presentation/sales_exec_shell.dart';
import '../../features/dashboard/presentation/manager_admin_shell.dart';

/// Portal picker → one of three login screens → role-based shell.
/// This is the structural boundary described in ARCHITECTURE.md §4:
/// SalesExecShell is the only route tree with customer/timeline/follow-up
/// screens. ManagerAdminShell only ever renders aggregate report screens.
GoRouter buildAppRouter(ApiClient apiClient) {
  final authRepo = AuthRepository(apiClient);

  return GoRouter(
    initialLocation: '/portal-select',
    routes: [
      GoRoute(
        path: '/portal-select',
        builder: (context, state) => const PortalSelectScreen(),
      ),
      GoRoute(
        path: '/login/sales-exec',
        builder: (context, state) => LoginScreen(
          portalTitle: 'Sales Executive Login',
          portalSubtitle: 'Your customers. Your relationships. Only you can see them.',
          authRepository: authRepo,
          onLoginSuccess: (role) => context.go('/sales-exec'),
        ),
      ),
      GoRoute(
        path: '/login/store-manager',
        builder: (context, state) => LoginScreen(
          portalTitle: 'Store Manager Login',
          portalSubtitle: 'Team performance and reports for your store.',
          authRepository: authRepo,
          onLoginSuccess: (role) => context.go('/reports'),
        ),
      ),
      GoRoute(
        path: '/login/admin',
        builder: (context, state) => LoginScreen(
          portalTitle: 'Admin Login',
          portalSubtitle: 'Organization setup and integrations.',
          authRepository: authRepo,
          onLoginSuccess: (role) => context.go('/reports'),
        ),
      ),
      GoRoute(
        path: '/sales-exec',
        builder: (context, state) => const SalesExecShell(),
      ),
      GoRoute(
        path: '/reports',
        builder: (context, state) => const ManagerAdminShell(),
      ),
    ],
  );
}

class PortalSelectScreen extends StatelessWidget {
  const PortalSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('ClientBook AI', textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('Choose how you sign in', textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 40),
              _PortalButton(label: 'Sales Executive', icon: Icons.badge_outlined, route: '/login/sales-exec'),
              const SizedBox(height: 14),
              _PortalButton(label: 'Store Manager', icon: Icons.store_outlined, route: '/login/store-manager'),
              const SizedBox(height: 14),
              _PortalButton(label: 'Admin', icon: Icons.admin_panel_settings_outlined, route: '/login/admin'),
            ],
          ),
        ),
      ),
    );
  }
}

class _PortalButton extends StatelessWidget {
  const _PortalButton({required this.label, required this.icon, required this.route});
  final String label;
  final IconData icon;
  final String route;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => context.push(route),
      icon: Icon(icon),
      label: Align(alignment: Alignment.centerLeft, child: Text(label)),
      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16)),
    );
  }
}
