import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/network/api_client.dart';
import 'core/router/app_router.dart';
import 'core/notifications/notification_service.dart';
import 'features/customers/presentation/customer_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Point this at your deployed NestJS API. For local dev against an
  // Android emulator, use http://10.0.2.2:3000; for iOS simulator, use
  // http://localhost:3000.
  final apiClient = ApiClient(baseUrl: 'https://api.clientbook.ai');

  // Follow-up reminders (Milestone 3) — safe to init before login since it
  // only touches local OS notification channels, no auth required.
  await NotificationService.instance.init();

  runApp(
    ProviderScope(
      overrides: [apiClientProvider.overrideWithValue(apiClient)],
      child: ClientBookApp(apiClient: apiClient),
    ),
  );
}

class ClientBookApp extends StatelessWidget {
  const ClientBookApp({super.key, required this.apiClient});
  final ApiClient apiClient;

  @override
  Widget build(BuildContext context) {
    final router = buildAppRouter(apiClient);

    return MaterialApp.router(
      title: 'ClientBook AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
