import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/notifications/notification_service.dart';
import '../domain/follow_up.dart';
import '../domain/follow_up_filter.dart';
import 'create_edit_follow_up_screen.dart';
import 'follow_up_calendar_view.dart';
import 'follow_up_card.dart';
import 'follow_up_providers.dart';

/// The Sales Exec shell's "Tasks" tab: Dashboard follow-up cards, search &
/// filter chips (Today/Tomorrow/This Week/Overdue/Completed/Pending/High
/// Priority), and a List ⇄ Calendar toggle.
class FollowUpListScreen extends ConsumerStatefulWidget {
  const FollowUpListScreen({super.key});

  @override
  ConsumerState<FollowUpListScreen> createState() => _FollowUpListScreenState();
}

class _FollowUpListScreenState extends ConsumerState<FollowUpListScreen> {
  bool _calendarMode = false;

  Future<void> _completeFollowUp(FollowUp followUp) async {
    await ref.read(followUpRepositoryProvider).complete(followUp.id);
    await NotificationService.instance.cancelFollowUpReminder(followUp.id);
    ref.invalidate(followUpListProvider);
    ref.invalidate(followUpDashboardProvider);
  }

  Future<void> _openFollowUp(FollowUp followUp) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateEditFollowUpScreen(
          customerId: followUp.customerId,
          customerName: followUp.customer?.fullName ?? 'Customer',
          existing: followUp,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(followUpFilterProvider);
    final dashboardAsync = ref.watch(followUpDashboardProvider);
    final followUpsAsync = ref.watch(followUpListProvider);

    return Column(
      children: [
        dashboardAsync.when(
          loading: () => const SizedBox(height: 96, child: Center(child: CircularProgressIndicator())),
          error: (_, __) => const SizedBox.shrink(),
          data: (summary) => _DashboardRow(summary: summary),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              Expanded(child: Text('Follow-ups', style: Theme.of(context).textTheme.titleMedium)),
              IconButton(
                icon: Icon(_calendarMode ? Icons.view_list_outlined : Icons.calendar_month_outlined),
                tooltip: _calendarMode ? 'List view' : 'Calendar view',
                onPressed: () => setState(() => _calendarMode = !_calendarMode),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              for (final due in FollowUpDueFilter.values)
                _DueChip(due: due, selected: filter.due == due),
              const SizedBox(width: 4),
              const VerticalDivider(width: 1),
              const SizedBox(width: 4),
              _StatusChip(status: FollowUpStatus.pending, label: 'Pending'),
              _StatusChip(status: FollowUpStatus.completed, label: 'Completed'),
              const SizedBox(width: 4),
              const VerticalDivider(width: 1),
              const SizedBox(width: 4),
              _HighPriorityChip(),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: followUpsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Could not load follow-ups.\n$err', textAlign: TextAlign.center)),
            data: (page) {
              if (page.items.isEmpty) {
                return const Center(child: Text('No follow-ups match these filters.'));
              }
              if (_calendarMode) {
                return FollowUpCalendarView(
                  followUps: page.items,
                  onTapFollowUp: _openFollowUp,
                  onComplete: _completeFollowUp,
                );
              }
              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(followUpListProvider);
                  ref.invalidate(followUpDashboardProvider);
                },
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: page.items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final followUp = page.items[i];
                    return FollowUpCard(
                      followUp: followUp,
                      onTap: () => _openFollowUp(followUp),
                      onComplete: () => _completeFollowUp(followUp),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DashboardRow extends StatelessWidget {
  const _DashboardRow({required this.summary});
  final FollowUpDashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final cards = [
      ('Today', summary.todayCount, Icons.today_outlined),
      ('Pending', summary.pendingCount, Icons.pending_actions_outlined),
      ('Completed Today', summary.completedTodayCount, Icons.check_circle_outline),
      ('Missed', summary.missedCount, Icons.error_outline),
      ('Tomorrow', summary.upcomingTomorrowCount, Icons.event_outlined),
    ];

    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        itemCount: cards.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final (label, count, icon) = cards[i];
          return Card(
            child: Container(
              width: 120,
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 6),
                  Text('$count', style: Theme.of(context).textTheme.titleLarge),
                  Text(label, style: Theme.of(context).textTheme.bodySmall, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DueChip extends ConsumerWidget {
  const _DueChip({required this.due, required this.selected});
  final FollowUpDueFilter due;
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(followUpFilterProvider);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(followUpDueFilterLabel(due)),
        selected: selected,
        onSelected: (v) => ref.read(followUpFilterProvider.notifier).state =
            filter.copyWith(due: v ? due : null, clearDue: !v),
      ),
    );
  }
}

class _StatusChip extends ConsumerWidget {
  const _StatusChip({required this.status, required this.label});
  final FollowUpStatus status;
  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(followUpFilterProvider);
    final selected = filter.status == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (v) => ref.read(followUpFilterProvider.notifier).state =
            filter.copyWith(status: v ? status : null, clearStatus: !v),
      ),
    );
  }
}

class _HighPriorityChip extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(followUpFilterProvider);
    final selected = filter.priority == FollowUpPriority.high;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: const Text('High Priority'),
        selected: selected,
        onSelected: (v) => ref.read(followUpFilterProvider.notifier).state = filter.copyWith(
          priority: v ? FollowUpPriority.high : null,
          clearPriority: !v,
        ),
      ),
    );
  }
}
