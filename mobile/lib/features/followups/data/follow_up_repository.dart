import '../../../core/network/api_client.dart';
import '../domain/follow_up.dart';
import '../domain/follow_up_filter.dart';

class FollowUpPage {
  FollowUpPage({required this.items, required this.nextCursor});
  final List<FollowUp> items;
  final String? nextCursor;
}

class FollowUpRepository {
  FollowUpRepository(this._apiClient);
  final ApiClient _apiClient;

  Future<FollowUpPage> list(FollowUpFilter filter, {String? cursor}) async {
    final response = await _apiClient.dio.get(
      '/api/v1/followups',
      queryParameters: {...filter.toQueryParams(), if (cursor != null) 'cursor': cursor},
    );
    final data = response.data;
    return FollowUpPage(
      items: (data['items'] as List).map((e) => FollowUp.fromJson(e)).toList(),
      nextCursor: data['nextCursor'],
    );
  }

  Future<FollowUp> detail(String id) async {
    final response = await _apiClient.dio.get('/api/v1/followups/$id');
    return FollowUp.fromJson(response.data);
  }

  Future<FollowUp> create({
    required String customerId,
    required FollowUpType type,
    required FollowUpPriority priority,
    required DateTime reminderAt,
    String? notes,
  }) async {
    final response = await _apiClient.dio.post(
      '/api/v1/followups',
      data: {
        'customerId': customerId,
        'type': followUpTypeToApi(type),
        'priority': followUpPriorityToApi(priority),
        'reminderAt': reminderAt.toUtc().toIso8601String(),
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );
    return FollowUp.fromJson(response.data);
  }

  Future<FollowUp> update(
    String id, {
    FollowUpType? type,
    FollowUpPriority? priority,
    DateTime? reminderAt,
    String? notes,
    FollowUpStatus? status,
  }) async {
    final response = await _apiClient.dio.patch(
      '/api/v1/followups/$id',
      data: {
        if (type != null) 'type': followUpTypeToApi(type),
        if (priority != null) 'priority': followUpPriorityToApi(priority),
        if (reminderAt != null) 'reminderAt': reminderAt.toUtc().toIso8601String(),
        if (notes != null) 'notes': notes,
        if (status != null) 'status': followUpStatusToApi(status),
      },
    );
    return FollowUp.fromJson(response.data);
  }

  Future<FollowUp> complete(String id) async {
    final response = await _apiClient.dio.post('/api/v1/followups/$id/complete');
    return FollowUp.fromJson(response.data);
  }

  Future<void> delete(String id) async {
    await _apiClient.dio.delete('/api/v1/followups/$id');
  }

  Future<FollowUpDashboardSummary> dashboardSummary() async {
    final response = await _apiClient.dio.get('/api/v1/followups/dashboard-summary');
    return FollowUpDashboardSummary.fromJson(response.data);
  }
}
