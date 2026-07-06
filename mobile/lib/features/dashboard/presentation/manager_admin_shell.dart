import 'package:flutter/material.dart';

/// Shell for STORE_MANAGER and ADMIN roles.
/// Deliberately has no route to any customer's individual timeline/notes —
/// that screen simply does not exist in this shell's route tree, which is
/// the mobile-side half of the "managers can't touch personal notes" rule.
class ManagerAdminShell extends StatelessWidget {
  const ManagerAdminShell({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ClientBook AI — Reports')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Team & Store Reports', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                'Sales, conversion, retention and follow-up-completion reports arrive in Milestone 2/3. '
                'This shell never gets access to individual customer notes or timelines.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
