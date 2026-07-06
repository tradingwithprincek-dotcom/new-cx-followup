import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../domain/customer.dart';

class CustomerCard extends StatelessWidget {
  const CustomerCard({super.key, required this.customer, required this.onTap});
  final Customer customer;
  final VoidCallback onTap;

  Color _statusColor(BuildContext context) {
    switch (customer.status) {
      case CustomerStatus.vip:
        return const Color(0xFFF6B24F);
      case CustomerStatus.regular:
        return Theme.of(context).colorScheme.primary;
      case CustomerStatus.inactive:
        return Colors.grey;
      case CustomerStatus.lost:
        return Colors.redAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.compactCurrency(locale: 'en_IN', symbol: '₹');
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundImage: customer.photoUrl != null ? NetworkImage(customer.photoUrl!) : null,
                child: customer.photoUrl == null ? Text(customer.fullName.characters.first) : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(customer.fullName,
                              style: Theme.of(context).textTheme.titleMedium,
                              overflow: TextOverflow.ellipsis),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _statusColor(context).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            statusLabel(customer.status),
                            style: TextStyle(color: _statusColor(context), fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (customer.favouriteCategory != null) customer.favouriteCategory,
                        if (customer.lastVisitAt != null)
                          'Last visit ${DateFormat.yMMMd().format(customer.lastVisitAt!)}',
                      ].join(' · '),
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Lifetime spend ${currency.format(customer.lifetimeSpend)} · ${customer.numberOfPurchases} purchases',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
