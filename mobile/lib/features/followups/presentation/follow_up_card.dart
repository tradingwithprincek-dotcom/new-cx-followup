import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../domain/follow_up.dart';

class FollowUpCard extends StatelessWidget {
  const FollowUpCard({
    super.key,
    required this.followUp,
    required this.onTap,
    this.onComplete,
  });

  final FollowUp followUp;
  final VoidCallback onTap;
  final VoidCallback? onComplete;

  IconData get _typeIcon {
    switch (followUp.type) {
      case FollowUpType.call:
        return Icons.call_outlined;
      case FollowUpType.whatsapp:
        return Icons.chat_bubble_outline;
      case FollowUpType.visit:
        return Icons.storefront_outlined;
    }
  }

  Color _priorityColor(BuildContext context) {
    switch (followUp.priority) {
      case FollowUpPriority.high:
        return Colors.redAccent;
      case FollowUpPriority.medium:
        return const Color(0xFFF6B24F);
      case FollowUpPriority.low:
        return Colors.grey;
    }
  }

  Color _statusColor(BuildContext context) {
    if (followUp.isMissed) return Colors.redAccent;
    switch (followUp.status) {
      case FollowUpStatus.completed:
        return Colors.green;
      case FollowUpStatus.pending:
        return Theme.of(context).colorScheme.primary;
      case FollowUpStatus.rescheduled:
        return const Color(0xFFF6B24F);
      case FollowUpStatus.cancelled:
        return Colors.grey;
    }
  }

  String get _statusText => followUp.isMissed ? 'Missed' : followUpStatusLabel(followUp.status);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: 52,
                decoration: BoxDecoration(
                  color: _priorityColor(context),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              CircleAvatar(radius: 20, child: Icon(_typeIcon, size: 18)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            followUp.customer?.fullName ?? 'Customer',
                            style: Theme.of(context).textTheme.titleMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _statusColor(context).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _statusText,
                            style: TextStyle(
                              color: _statusColor(context),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${followUpTypeLabel(followUp.type)} · ${followUpPriorityLabel(followUp.priority)} priority',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat.yMMMd().add_jm().format(followUp.reminderAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (followUp.notes != null && followUp.notes!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        followUp.notes!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
              if (onComplete != null && followUp.status == FollowUpStatus.pending)
                IconButton(
                  icon: const Icon(Icons.check_circle_outline),
                  tooltip: 'Mark completed',
                  onPressed: onComplete,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
