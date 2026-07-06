enum FollowUpType { call, whatsapp, visit }

FollowUpType followUpTypeFromString(String raw) {
  switch (raw) {
    case 'CALL':
      return FollowUpType.call;
    case 'WHATSAPP':
      return FollowUpType.whatsapp;
    case 'VISIT':
      return FollowUpType.visit;
    default:
      return FollowUpType.call;
  }
}

String followUpTypeToApi(FollowUpType type) {
  switch (type) {
    case FollowUpType.call:
      return 'CALL';
    case FollowUpType.whatsapp:
      return 'WHATSAPP';
    case FollowUpType.visit:
      return 'VISIT';
  }
}

String followUpTypeLabel(FollowUpType type) {
  switch (type) {
    case FollowUpType.call:
      return 'Call';
    case FollowUpType.whatsapp:
      return 'WhatsApp';
    case FollowUpType.visit:
      return 'Visit';
  }
}

enum FollowUpPriority { low, medium, high }

FollowUpPriority followUpPriorityFromString(String raw) {
  switch (raw) {
    case 'LOW':
      return FollowUpPriority.low;
    case 'MEDIUM':
      return FollowUpPriority.medium;
    case 'HIGH':
      return FollowUpPriority.high;
    default:
      return FollowUpPriority.medium;
  }
}

String followUpPriorityToApi(FollowUpPriority priority) {
  switch (priority) {
    case FollowUpPriority.low:
      return 'LOW';
    case FollowUpPriority.medium:
      return 'MEDIUM';
    case FollowUpPriority.high:
      return 'HIGH';
  }
}

String followUpPriorityLabel(FollowUpPriority priority) {
  switch (priority) {
    case FollowUpPriority.low:
      return 'Low';
    case FollowUpPriority.medium:
      return 'Medium';
    case FollowUpPriority.high:
      return 'High';
  }
}

/// PENDING/COMPLETED/RESCHEDULED/CANCELLED come from the API. "Missed" is
/// never one of these values — it's derived client-side the same way the
/// backend derives it (see `FollowUp.isMissed`), so there is exactly one
/// place that defines what "missed" means.
enum FollowUpStatus { pending, completed, rescheduled, cancelled }

FollowUpStatus followUpStatusFromString(String raw) {
  switch (raw) {
    case 'PENDING':
      return FollowUpStatus.pending;
    case 'COMPLETED':
      return FollowUpStatus.completed;
    case 'RESCHEDULED':
      return FollowUpStatus.rescheduled;
    case 'CANCELLED':
      return FollowUpStatus.cancelled;
    default:
      return FollowUpStatus.pending;
  }
}

String followUpStatusToApi(FollowUpStatus status) {
  switch (status) {
    case FollowUpStatus.pending:
      return 'PENDING';
    case FollowUpStatus.completed:
      return 'COMPLETED';
    case FollowUpStatus.rescheduled:
      return 'RESCHEDULED';
    case FollowUpStatus.cancelled:
      return 'CANCELLED';
  }
}

String followUpStatusLabel(FollowUpStatus status) {
  switch (status) {
    case FollowUpStatus.pending:
      return 'Pending';
    case FollowUpStatus.completed:
      return 'Completed';
    case FollowUpStatus.rescheduled:
      return 'Rescheduled';
    case FollowUpStatus.cancelled:
      return 'Cancelled';
  }
}

/// Lightweight customer summary embedded in a follow-up list/detail
/// response — just enough for the Tasks list card without a second round trip.
class FollowUpCustomerSummary {
  FollowUpCustomerSummary({
    required this.id,
    required this.fullName,
    required this.mobileNumber,
    this.photoUrl,
  });

  final String id;
  final String fullName;
  final String mobileNumber;
  final String? photoUrl;

  factory FollowUpCustomerSummary.fromJson(Map<String, dynamic> json) {
    return FollowUpCustomerSummary(
      id: json['id'],
      fullName: json['fullName'],
      mobileNumber: json['mobileNumber'],
      photoUrl: json['photoUrl'],
    );
  }
}

class FollowUp {
  FollowUp({
    required this.id,
    required this.customerId,
    required this.type,
    required this.priority,
    required this.status,
    required this.reminderAt,
    this.notes,
    this.completedAt,
    this.customer,
  });

  final String id;
  final String customerId;
  final FollowUpType type;
  final FollowUpPriority priority;
  final FollowUpStatus status;
  final DateTime reminderAt;
  final String? notes;
  final DateTime? completedAt;
  final FollowUpCustomerSummary? customer;

  /// Mirrors the backend's derivation exactly: PENDING + reminder in the past.
  bool get isMissed => status == FollowUpStatus.pending && reminderAt.isBefore(DateTime.now());

  factory FollowUp.fromJson(Map<String, dynamic> json) {
    return FollowUp(
      id: json['id'],
      customerId: json['customerId'],
      type: followUpTypeFromString(json['type']),
      priority: followUpPriorityFromString(json['priority']),
      status: followUpStatusFromString(json['status']),
      reminderAt: DateTime.parse(json['reminderAt']).toLocal(),
      notes: json['notes'],
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']).toLocal() : null,
      customer: json['customer'] != null ? FollowUpCustomerSummary.fromJson(json['customer']) : null,
    );
  }
}

class FollowUpDashboardSummary {
  FollowUpDashboardSummary({
    required this.todayCount,
    required this.pendingCount,
    required this.completedTodayCount,
    required this.missedCount,
    required this.upcomingTomorrowCount,
  });

  final int todayCount;
  final int pendingCount;
  final int completedTodayCount;
  final int missedCount;
  final int upcomingTomorrowCount;

  factory FollowUpDashboardSummary.fromJson(Map<String, dynamic> json) {
    return FollowUpDashboardSummary(
      todayCount: json['todayCount'] ?? 0,
      pendingCount: json['pendingCount'] ?? 0,
      completedTodayCount: json['completedTodayCount'] ?? 0,
      missedCount: json['missedCount'] ?? 0,
      upcomingTomorrowCount: json['upcomingTomorrowCount'] ?? 0,
    );
  }
}
