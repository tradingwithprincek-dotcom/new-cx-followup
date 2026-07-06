import '../../../core/network/api_client.dart';
import '../domain/customer.dart';
import '../domain/customer_filter.dart';

class CustomerPage {
  CustomerPage({required this.items, required this.nextCursor});
  final List<Customer> items;
  final String? nextCursor;
}

class CustomerRepository {
  CustomerRepository(this._apiClient);
  final ApiClient _apiClient;

  Future<CustomerPage> list(CustomerFilter filter, {String? cursor}) async {
    final response = await _apiClient.dio.get(
      '/api/v1/customers',
      queryParameters: {...filter.toQueryParams(), if (cursor != null) 'cursor': cursor},
    );
    final data = response.data;
    return CustomerPage(
      items: (data['items'] as List).map((e) => Customer.fromJson(e)).toList(),
      nextCursor: data['nextCursor'],
    );
  }

  Future<Customer> detail(String id) async {
    final response = await _apiClient.dio.get('/api/v1/customers/$id');
    return Customer.fromJson(response.data);
  }

  Future<List<TimelineEvent>> timeline(String id) async {
    final response = await _apiClient.dio.get('/api/v1/customers/$id/timeline');
    return (response.data as List).map((e) => TimelineEvent.fromJson(e)).toList();
  }

  Future<void> addNote(String id, String note) async {
    await _apiClient.dio.post('/api/v1/customers/$id/notes', data: {'note': note});
  }

  Future<Map<String, List<Customer>>> todayHighlights() async {
    final response = await _apiClient.dio.get('/api/v1/customers/today-highlights');
    final data = response.data;
    return {
      'birthdays': (data['birthdays'] as List).map((e) => Customer.fromJson(e)).toList(),
      'anniversaries': (data['anniversaries'] as List).map((e) => Customer.fromJson(e)).toList(),
    };
  }
}
