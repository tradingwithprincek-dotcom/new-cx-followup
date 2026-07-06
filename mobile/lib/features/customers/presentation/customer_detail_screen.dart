import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../followups/domain/follow_up.dart';
import '../../followups/presentation/create_edit_follow_up_screen.dart';
import '../../followups/presentation/follow_up_card.dart';
import '../../followups/presentation/follow_up_providers.dart';
import '../domain/customer.dart';
import 'customer_providers.dart';

class CustomerDetailScreen extends ConsumerWidget {
  const CustomerDetailScreen({super.key, required this.customerId});
  final String customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerAsync = ref.watch(customerDetailProvider(customerId));
    final timelineAsync = ref.watch(customerTimelineProvider(customerId));

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.call_outlined),
            tooltip: 'Call customer',
            onPressed: () {}, // wired up in Milestone 5 (Calling)
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            tooltip: 'Send WhatsApp',
            onPressed: () {}, // wired up in Milestone 4 (WhatsApp)
          ),
          IconButton(
            icon: const Icon(Icons.event_outlined),
            tooltip: 'Add follow-up',
            onPressed: () => _openCreateFollowUp(context, ref, customerAsync.valueOrNull),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.note_add_outlined),
        label: const Text('Add note'),
        onPressed: () => _showAddNoteSheet(context, ref),
      ),
      body: customerAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Could not load customer.\n$err')),
        data: (customer) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(customerDetailProvider(customerId));
            ref.invalidate(customerTimelineProvider(customerId));
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _ProfileHeader(customer: customer),
              const SizedBox(height: 20),
              _StatsGrid(customer: customer),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Text('Upcoming Follow-ups', style: Theme.of(context).textTheme.titleMedium),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add'),
                    onPressed: () => _openCreateFollowUp(context, ref, customer),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Consumer(
                builder: (context, ref, _) {
                  final followUpsAsync = ref.watch(customerFollowUpsProvider(customerId));
                  return followUpsAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (err, _) => Text('Could not load follow-ups.\n$err'),
                    data: (page) {
                      final open = page.items.where((f) => f.status == FollowUpStatus.pending).toList();
                      if (open.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Text('No upcoming follow-ups.'),
                        );
                      }
                      return Column(
                        children: open
                            .map((f) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: FollowUpCard(
                                    followUp: f,
                                    onTap: () => _openEditFollowUp(context, ref, f, customer),
                                    onComplete: () async {
                                      await ref.read(followUpRepositoryProvider).complete(f.id);
                                      ref.invalidate(customerFollowUpsProvider(customerId));
                                      ref.invalidate(customerTimelineProvider(customerId));
                                      ref.invalidate(followUpDashboardProvider);
                                    },
                                  ),
                                ))
                            .toList(),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 24),
              Text('Timeline', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              timelineAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, _) => Text('Could not load timeline.\n$err'),
                data: (events) => events.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text('No interactions recorded yet.'),
                      )
                    : Column(children: events.map((e) => _TimelineTile(event: e)).toList()),
              ),
              const SizedBox(height: 80), // room for the FAB
            ],
          ),
        ),
      ),
    );
  }

  void _openCreateFollowUp(BuildContext context, WidgetRef ref, Customer? customer) {
    if (customer == null) return;
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (_) => CreateEditFollowUpScreen(customerId: customer.id, customerName: customer.fullName),
      ),
    )
        .then((_) {
      ref.invalidate(customerFollowUpsProvider(customerId));
      ref.invalidate(customerTimelineProvider(customerId));
    });
  }

  void _openEditFollowUp(BuildContext context, WidgetRef ref, FollowUp followUp, Customer customer) {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (_) => CreateEditFollowUpScreen(
          customerId: customer.id,
          customerName: customer.fullName,
          existing: followUp,
        ),
      ),
    )
        .then((_) {
      ref.invalidate(customerFollowUpsProvider(customerId));
      ref.invalidate(customerTimelineProvider(customerId));
    });
  }

  void _showAddNoteSheet(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Add note', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(controller: controller, maxLines: 3, autofocus: true),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                if (controller.text.trim().isEmpty) return;
                await ref.read(customerRepositoryProvider).addNote(customerId, controller.text.trim());
                ref.invalidate(customerTimelineProvider(customerId));
                if (context.mounted) Navigator.of(context).pop();
              },
              child: const Text('Save note'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.customer});
  final Customer customer;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 34,
          backgroundImage: customer.photoUrl != null ? NetworkImage(customer.photoUrl!) : null,
          child: customer.photoUrl == null ? Text(customer.fullName.characters.first, style: const TextStyle(fontSize: 22)) : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(customer.fullName, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(customer.mobileNumber, style: Theme.of(context).textTheme.bodyMedium),
              if (customer.email != null) Text(customer.email!, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 4),
              Text(statusLabel(customer.status),
                  style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.customer});
  final Customer customer;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.compactCurrency(locale: 'en_IN', symbol: '₹');
    final stats = <(String, String)>[
      ('Lifetime spend', currency.format(customer.lifetimeSpend)),
      ('Purchases', '${customer.numberOfPurchases}'),
      ('Average bill', currency.format(customer.averageBill)),
      ('Favourite category', customer.favouriteCategory ?? '—'),
      ('Favourite product', customer.favouriteProduct ?? '—'),
      ('Customer since', customer.customerSince != null ? DateFormat.yMMM().format(customer.customerSince!) : '—'),
      ('Birthday', customer.birthday != null ? DateFormat.MMMd().format(customer.birthday!) : '—'),
      ('Anniversary', customer.anniversary != null ? DateFormat.MMMd().format(customer.anniversary!) : '—'),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.6,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: stats
          .map((s) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(s.$1, style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 2),
                      Text(s.$2, style: Theme.of(context).textTheme.titleMedium, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({required this.event});
  final TimelineEvent event;

  IconData get _icon {
    switch (event.type) {
      case InteractionType.purchase:
        return Icons.shopping_bag_outlined;
      case InteractionType.call:
        return Icons.call_outlined;
      case InteractionType.whatsapp:
        return Icons.chat_bubble_outline;
      case InteractionType.visit:
        return Icons.storefront_outlined;
      case InteractionType.reminder:
        return Icons.alarm_outlined;
      case InteractionType.note:
        return Icons.sticky_note_2_outlined;
      case InteractionType.wishlist:
        return Icons.favorite_outline;
      case InteractionType.voiceNote:
        return Icons.mic_none_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(radius: 16, child: Icon(_icon, size: 16)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(DateFormat.yMMMd().add_jm().format(event.occurredAt),
                    style: Theme.of(context).textTheme.bodySmall),
                if (event.notes != null) Text(event.notes!),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
