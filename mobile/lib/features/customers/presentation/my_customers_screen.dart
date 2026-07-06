import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/customer.dart';
import 'customer_providers.dart';
import 'customer_card.dart';
import 'customer_detail_screen.dart';

class MyCustomersScreen extends ConsumerStatefulWidget {
  const MyCustomersScreen({super.key});

  @override
  ConsumerState<MyCustomersScreen> createState() => _MyCustomersScreenState();
}

class _MyCustomersScreenState extends ConsumerState<MyCustomersScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(customerFilterProvider);
    final customersAsync = ref.watch(customerListProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by name, phone, or product',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _searchController.clear();
                        ref.read(customerFilterProvider.notifier).state =
                            filter.copyWith(search: '');
                      },
                    ),
            ),
            onSubmitted: (value) {
              ref.read(customerFilterProvider.notifier).state = filter.copyWith(search: value);
            },
          ),
        ),
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _StatusChip(status: CustomerStatus.vip, label: 'VIP'),
              _StatusChip(status: CustomerStatus.regular, label: 'Regular'),
              _StatusChip(status: CustomerStatus.inactive, label: 'Inactive'),
              _StatusChip(status: CustomerStatus.lost, label: 'Lost'),
              const SizedBox(width: 4),
              const VerticalDivider(width: 1),
              const SizedBox(width: 4),
              _RecencyChip(days: 30),
              _RecencyChip(days: 60),
              _RecencyChip(days: 90),
              const SizedBox(width: 4),
              const VerticalDivider(width: 1),
              const SizedBox(width: 4),
              _ToggleChip(
                label: 'Birthday',
                selected: filter.birthdayThisMonth,
                onChanged: (v) => ref.read(customerFilterProvider.notifier).state =
                    filter.copyWith(birthdayThisMonth: v),
              ),
              _ToggleChip(
                label: 'Anniversary',
                selected: filter.anniversaryThisMonth,
                onChanged: (v) => ref.read(customerFilterProvider.notifier).state =
                    filter.copyWith(anniversaryThisMonth: v),
              ),
              _ToggleChip(
                label: 'Wishlist',
                selected: filter.hasWishlist,
                onChanged: (v) => ref.read(customerFilterProvider.notifier).state =
                    filter.copyWith(hasWishlist: v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: customersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Could not load customers.\n$err', textAlign: TextAlign.center)),
            data: (page) {
              if (page.items.isEmpty) {
                return const Center(child: Text('No customers match these filters.'));
              }
              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(customerListProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: page.items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final customer = page.items[i];
                    return CustomerCard(
                      customer: customer,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => CustomerDetailScreen(customerId: customer.id)),
                      ),
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

class _StatusChip extends ConsumerWidget {
  const _StatusChip({required this.status, required this.label});
  final CustomerStatus status;
  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(customerFilterProvider);
    final selected = filter.status == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (v) => ref.read(customerFilterProvider.notifier).state =
            filter.copyWith(status: v ? status : null, clearStatus: !v),
      ),
    );
  }
}

class _RecencyChip extends ConsumerWidget {
  const _RecencyChip({required this.days});
  final int days;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(customerFilterProvider);
    final selected = filter.lastVisitWithinDays == days;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text('$days Days'),
        selected: selected,
        onSelected: (v) => ref.read(customerFilterProvider.notifier).state =
            filter.copyWith(lastVisitWithinDays: v ? days : null, clearRecency: !v),
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({required this.label, required this.selected, required this.onChanged});
  final String label;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(label: Text(label), selected: selected, onSelected: onChanged),
    );
  }
}
