import 'follow_up.dart';

/// Search & Filters chips: Today / Tomorrow / This Week / Overdue /
/// Completed / Pending / High Priority. Mirrors ListFollowUpsQueryDto on the
/// backend — one object so the Tasks screen's filter-chip state maps 1:1
/// onto the API call.
enum FollowUpDueFilter { today, tomorrow, thisWeek, overdue }

String followUpDueFilterToApi(FollowUpDueFilter due) {
  switch (due) {
    case FollowUpDueFilter.today:
      return 'today';
    case FollowUpDueFilter.tomorrow:
      return 'tomorrow';
    case FollowUpDueFilter.thisWeek:
      return 'thisWeek';
    case FollowUpDueFilter.overdue:
      return 'overdue';
  }
}

String followUpDueFilterLabel(FollowUpDueFilter due) {
  switch (due) {
    case FollowUpDueFilter.today:
      return 'Today';
    case FollowUpDueFilter.tomorrow:
      return 'Tomorrow';
    case FollowUpDueFilter.thisWeek:
      return 'This Week';
    case FollowUpDueFilter.overdue:
      return 'Overdue';
  }
}

class FollowUpFilter {
  const FollowUpFilter({
    this.due,
    this.status,
    this.priority,
    this.type,
    this.missed = false,
    this.customerId,
  });

  final FollowUpDueFilter? due;
  final FollowUpStatus? status;
  final FollowUpPriority? priority;
  final FollowUpType? type;
  final bool missed;
  final String? customerId;

  FollowUpFilter copyWith({
    FollowUpDueFilter? due,
    bool clearDue = false,
    FollowUpStatus? status,
    bool clearStatus = false,
    FollowUpPriority? priority,
    bool clearPriority = false,
    FollowUpType? type,
    bool clearType = false,
    bool? missed,
    String? customerId,
  }) {
    return FollowUpFilter(
      due: clearDue ? null : (due ?? this.due),
      status: clearStatus ? null : (status ?? this.status),
      priority: clearPriority ? null : (priority ?? this.priority),
      type: clearType ? null : (type ?? this.type),
      missed: missed ?? this.missed,
      customerId: customerId ?? this.customerId,
    );
  }

  Map<String, dynamic> toQueryParams() {
    return {
      if (due != null) 'due': followUpDueFilterToApi(due!),
      if (status != null) 'status': followUpStatusToApi(status!),
      if (priority != null) 'priority': followUpPriorityToApi(priority!),
      if (type != null) 'type': followUpTypeToApi(type!),
      if (missed) 'missed': 'true',
      if (customerId != null) 'customerId': customerId,
    };
  }
}
