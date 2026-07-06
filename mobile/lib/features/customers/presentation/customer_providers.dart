import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../data/customer_repository.dart';
import '../domain/customer.dart';
import '../domain/customer_filter.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  throw UnimplementedError('Override in main.dart with the real base URL');
});

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return CustomerRepository(ref.watch(apiClientProvider));
});

final customerFilterProvider = StateProvider<CustomerFilter>((ref) => const CustomerFilter());

/// Re-fetches whenever the filter changes. Pagination (nextCursor) is
/// handled inside the list screen via loadMore, not re-exposed here, to
/// keep this provider's contract simple: "first page for this filter."
final customerListProvider = FutureProvider.autoDispose<CustomerPage>((ref) async {
  final filter = ref.watch(customerFilterProvider);
  final repo = ref.watch(customerRepositoryProvider);
  return repo.list(filter);
});

final customerDetailProvider =
    FutureProvider.autoDispose.family<Customer, String>((ref, id) async {
  return ref.watch(customerRepositoryProvider).detail(id);
});

final customerTimelineProvider =
    FutureProvider.autoDispose.family<List<TimelineEvent>, String>((ref, id) async {
  return ref.watch(customerRepositoryProvider).timeline(id);
});
