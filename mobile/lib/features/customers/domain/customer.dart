enum CustomerStatus { vip, regular, inactive, lost }

CustomerStatus statusFromString(String raw) {
  switch (raw) {
    case 'VIP':
      return CustomerStatus.vip;
    case 'REGULAR':
      return CustomerStatus.regular;
    case 'INACTIVE':
      return CustomerStatus.inactive;
    case 'LOST':
      return CustomerStatus.lost;
    default:
      return CustomerStatus.regular;
  }
}

String statusLabel(CustomerStatus status) {
  switch (status) {
    case CustomerStatus.vip:
      return 'VIP';
    case CustomerStatus.regular:
      return 'Regular';
    case CustomerStatus.inactive:
      return 'Inactive';
    case CustomerStatus.lost:
      return 'Lost';
  }
}

class Customer {
  Customer({
    required this.id,
    required this.fullName,
    required this.mobileNumber,
    required this.status,
    this.photoUrl,
    this.email,
    this.birthday,
    this.anniversary,
    this.lastVisitAt,
    this.totalShopping = 0,
    this.lifetimeSpend = 0,
    this.numberOfPurchases = 0,
    this.averageBill = 0,
    this.favouriteCategory,
    this.favouriteProduct,
    this.customerSince,
  });

  final String id;
  final String fullName;
  final String mobileNumber;
  final String? photoUrl;
  final String? email;
  final DateTime? birthday;
  final DateTime? anniversary;
  final DateTime? lastVisitAt;
  final double totalShopping;
  final double lifetimeSpend;
  final int numberOfPurchases;
  final double averageBill;
  final String? favouriteCategory;
  final String? favouriteProduct;
  final DateTime? customerSince;
  final CustomerStatus status;

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'],
      fullName: json['fullName'],
      mobileNumber: json['mobileNumber'],
      photoUrl: json['photoUrl'],
      email: json['email'],
      birthday: json['birthday'] != null ? DateTime.parse(json['birthday']) : null,
      anniversary: json['anniversary'] != null ? DateTime.parse(json['anniversary']) : null,
      lastVisitAt: json['lastVisitAt'] != null ? DateTime.parse(json['lastVisitAt']) : null,
      totalShopping: (json['totalShopping'] as num?)?.toDouble() ?? 0,
      lifetimeSpend: (json['lifetimeSpend'] as num?)?.toDouble() ?? 0,
      numberOfPurchases: json['numberOfPurchases'] ?? 0,
      averageBill: (json['averageBill'] as num?)?.toDouble() ?? 0,
      favouriteCategory: json['favouriteCategory'],
      favouriteProduct: json['favouriteProduct'],
      customerSince: json['customerSince'] != null ? DateTime.parse(json['customerSince']) : null,
      status: statusFromString(json['status'] ?? 'REGULAR'),
    );
  }
}

enum InteractionType { purchase, call, whatsapp, visit, reminder, note, wishlist, voiceNote }

InteractionType interactionTypeFromString(String raw) {
  switch (raw) {
    case 'PURCHASE':
      return InteractionType.purchase;
    case 'CALL':
      return InteractionType.call;
    case 'WHATSAPP':
      return InteractionType.whatsapp;
    case 'VISIT':
      return InteractionType.visit;
    case 'REMINDER':
      return InteractionType.reminder;
    case 'NOTE':
      return InteractionType.note;
    case 'WISHLIST':
      return InteractionType.wishlist;
    case 'VOICE_NOTE':
      return InteractionType.voiceNote;
    default:
      return InteractionType.note;
  }
}

class TimelineEvent {
  TimelineEvent({required this.id, required this.type, required this.occurredAt, this.notes});

  final String id;
  final InteractionType type;
  final DateTime occurredAt;
  final String? notes;

  factory TimelineEvent.fromJson(Map<String, dynamic> json) {
    return TimelineEvent(
      id: json['id'],
      type: interactionTypeFromString(json['type']),
      occurredAt: DateTime.parse(json['occurredAt']),
      notes: json['notes'],
    );
  }
}
