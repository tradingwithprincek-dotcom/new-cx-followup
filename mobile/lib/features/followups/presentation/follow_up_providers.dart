import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../customers/presentation/customer_providers.dart';
import '../data/follow_up_repository.dart';
import '../domain/follow_up.dart';
import '../domain/follow_up_filter.dart';

final followUpRepositoryProvider = Provider<FollowUpRepository>((ref) {
  return FollowUpRepository(ref.watch(apiClientProvider));
});

final followUpFilterProvider = StateProvider<FollowUpFilter>((ref) => const FollowUpFilter());

/// Re-fetches whenever the filter changes. Pagination (nextCursor) is
/// handled inside the list screen via loadMore, not re-exposed here — same
/// pattern as customerListProvider in Milestone 2.
final followUpListProvider = FutureProvider.autoDispose<FollowUpPage>((ref) async {
  final filter = ref.watch(followUpFilterProvider);
  final repo = ref.watch(followUpRepositoryProvider);
  return repo.list(filter);
});

final followUpDetailProvider =
    FutureProvider.autoDispose.family<FollowUp, String>((ref, id) async {
  return ref.watch(followUpRepositoryProvider).detail(id);
});

final followUpDashboardProvider = FutureProvider.autoDispose<FollowUpDashboardSummary>((ref) async {
  return ref.watch(followUpRepositoryProvider).dashboardSummary();
});

/// Scoped list for a single customer — powers the "Upcoming Follow-ups"
/// section on the Customer Detail screen.
final customerFollowUpsProvider =
    FutureProvider.autoDispose.family<FollowUpPage, String>((ref, customerId) async {
  final repo = ref.watch(followUpRepositoryProvider);
  return repo.list(FollowUpFilter(customerId: customerId));
});
