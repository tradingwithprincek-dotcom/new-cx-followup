import 'package:dio/dio.dart';
import 'token_storage.dart';

/// Single Dio instance for the whole app.
/// Attaches the access token to every request and transparently refreshes
/// it on a 401 so a sales exec never gets logged out mid-follow-up call.
class ApiClient {
  ApiClient({required this.baseUrl}) {
    _dio = Dio(BaseOptions(baseUrl: baseUrl, connectTimeout: const Duration(seconds: 10)));
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenStorage.accessToken;
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401 && !_isRefreshing) {
            _isRefreshing = true;
            final refreshed = await _tryRefresh();
            _isRefreshing = false;
            if (refreshed) {
              final cloned = await _retry(error.requestOptions);
              return handler.resolve(cloned);
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  final String baseUrl;
  late final Dio _dio;
  final _tokenStorage = TokenStorage();
  bool _isRefreshing = false;

  Dio get dio => _dio;

  Future<bool> _tryRefresh() async {
    final refreshToken = await _tokenStorage.refreshToken;
    if (refreshToken == null) return false;
    try {
      final response = await Dio(BaseOptions(baseUrl: baseUrl)).post(
        '/api/v1/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      final data = response.data;
      await _tokenStorage.saveSession(
        accessToken: data['accessToken'],
        refreshToken: data['refreshToken'],
        role: data['user']['role'],
      );
      return true;
    } catch (_) {
      await _tokenStorage.clear();
      return false;
    }
  }

  Future<Response> _retry(RequestOptions requestOptions) async {
    final token = await _tokenStorage.accessToken;
    final options = Options(method: requestOptions.method, headers: {
      ...requestOptions.headers,
      'Authorization': 'Bearer $token',
    });
    return _dio.request(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }
}
