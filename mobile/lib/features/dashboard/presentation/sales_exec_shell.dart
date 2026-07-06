import 'package:flutter/material.dart';
import '../../customers/presentation/my_customers_screen.dart';
import '../../followups/presentation/follow_up_list_screen.dart';

/// Shell for the SALES_EXEC role. This is the primary product surface.
/// Milestone 2 filled in "My Customers"; Milestone 3 fills in "Tasks"
/// (Follow-up Management). Search is folded into My Customers' search bar
/// for now; a dedicated cross-entity search (invoice/product) still arrives
/// with POS data in Milestone 6. Reports keeps its own placeholder until
/// the reporting milestone.
class SalesExecShell extends StatefulWidget {
  const SalesExecShell({super.key});

  @override
  State<SalesExecShell> createState() => _SalesExecShellState();
}

class _SalesExecShellState extends State<SalesExecShell> {
  int _index = 0;

  static const _tabs = [
    MyCustomersScreen(),
    FollowUpListScreen(),
    _PlaceholderTab(title: 'Reports', subtitle: 'Personal dashboard — later milestone'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ClientBook AI')),
      body: _tabs[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.people_outline), label: 'My Customers'),
          NavigationDestination(icon: Icon(Icons.checklist_outlined), label: 'Tasks'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), label: 'Reports'),
        ],
      ),
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(subtitle, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
