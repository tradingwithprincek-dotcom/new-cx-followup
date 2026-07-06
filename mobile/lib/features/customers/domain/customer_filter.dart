import '../domain/customer.dart';

/// Mirrors ListCustomersQueryDto on the backend — one object so the list
/// screen's filter-chip state maps 1:1 onto the API call.
class CustomerFilter {
  const CustomerFilter({
    this.status,
    this.lastVisitWithinDays,
    this.birthdayThisMonth = false,
    this.anniversaryThisMonth = false,
    this.hasWishlist = false,
    this.search,
  });

  final CustomerStatus? status;
  final int? lastVisitWithinDays; // 30 / 60 / 90
  final bool birthdayThisMonth;
  final bool anniversaryThisMonth;
  final bool hasWishlist;
  final String? search;

  CustomerFilter copyWith({
    CustomerStatus? status,
    bool clearStatus = false,
    int? lastVisitWithinDays,
    bool clearRecency = false,
    bool? birthdayThisMonth,
    bool? anniversaryThisMonth,
    bool? hasWishlist,
    String? search,
  }) {
    return CustomerFilter(
      status: clearStatus ? null : (status ?? this.status),
      lastVisitWithinDays: clearRecency ? null : (lastVisitWithinDays ?? this.lastVisitWithinDays),
      birthdayThisMonth: birthdayThisMonth ?? this.birthdayThisMonth,
      anniversaryThisMonth: anniversaryThisMonth ?? this.anniversaryThisMonth,
      hasWishlist: hasWishlist ?? this.hasWishlist,
      search: search ?? this.search,
    );
  }

  Map<String, dynamic> toQueryParams() {
    return {
      if (status != null) 'status': statusLabel(status!).toUpperCase(),
      if (lastVisitWithinDays != null) 'lastVisitWithinDays': lastVisitWithinDays.toString(),
      if (birthdayThisMonth) 'birthdayThisMonth': 'true',
      if (anniversaryThisMonth) 'anniversaryThisMonth': 'true',
      if (hasWishlist) 'hasWishlist': 'true',
      if (search != null && search!.isNotEmpty) 'search': search,
    };
  }
}
