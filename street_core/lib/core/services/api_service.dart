// api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:street_core/core/helpers/device_storage.dart';
import 'package:street_core/core/services/api_response.dart';
import '../helpers/logger.dart';
import '../lang/locale_keys.dart';
import '../lang/locale_service.dart';
import '../di/injection.dart';
import 'api_address.dart';
import 'csrf_service.dart';

class ApiService {
  ApiService({
    LocaleService? localeService,
    StorageService? storageService,
  }) : _localeService = localeService,
       _storageServiceParam = storageService;

  final LocaleService? _localeService;
  final StorageService? _storageServiceParam;
  final CsrfService _csrfService = CsrfService();
  final Duration _timeout = const Duration(seconds: 15);

  // Get services from DI when not injected
  LocaleService get _locale => _localeService ?? getIt<LocaleService>();
  StorageService get _storageService => _storageServiceParam ?? getIt<StorageService>();

  String get _lang => _locale.currentLocale;

  String? _cachedBaseUrl;
  String? _cachedToken;
  bool _isRefreshing = false;

  Future<String?> get token async {
    _cachedToken ??= await _getToken();
    return _cachedToken;
  }

  Future<String> get baseUrl async {
    _cachedBaseUrl ??= await getApiAddress();
    return _cachedBaseUrl!;
  }

  Future<String?> _getToken() async {
    return _storageService.readSecure('auth_token');
  }

  Future<Map<String, String>> _buildHeaders(
    String? contentType,
    bool requiredToken,
  ) async {
    final Map<String, String> headers = {
      'Content-Type': contentType ?? 'application/json',
      'Accept-Language': _lang,
    };

    if (requiredToken) {
      final token = await _getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      } else {
        AppLogger.warning('No auth token available', tag: 'API');
      }
    }

    final csrfToken = await _csrfService.getToken();
    if (csrfToken != null) {
      headers['X-CSRF-Token'] = csrfToken;
    }

    return headers;
  }

  Future<ApiResponse<T>> useFetch<T>(
    String uri, {
    required String method,
    String? contentType,
    bool requiredToken = true,
    T Function(dynamic)? fromJsonT,
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
    bool isRetry = false,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      final urlBase = await getApiAddress();
      final String finalUri = '$urlBase$uri';
      final headers = await _buildHeaders(contentType, requiredToken);

      AppLogger.apiRequest(method.toUpperCase(), finalUri, data: body);

      final http.Response response = await _makeRequest(
        method,
        finalUri,
        headers,
        body,
        queryParameters: queryParameters,
      ).timeout(
        _timeout,
        onTimeout: () {
          AppLogger.error('Request timeout after ${_timeout.inSeconds}s', tag: 'API');
          throw Exception('error_timeout_request');
        },
      );

      stopwatch.stop();
      AppLogger.apiResponse(
        response.statusCode,
        finalUri,
        ms: stopwatch.elapsedMilliseconds,
        data: response.statusCode >= 400 ? response.body : null,
      );

      // Handle 401 with token refresh
      if (response.statusCode == 401 && requiredToken && !isRetry) {
        AppLogger.auth('Token expired, attempting refresh');
        final refreshSuccess = await refreshToken();
        if (refreshSuccess) {
          AppLogger.auth('Token refreshed, retrying request');
          return useFetch<T>(
            uri,
            method: method,
            contentType: contentType,
            requiredToken: requiredToken,
            fromJsonT: fromJsonT,
            body: body,
            queryParameters: queryParameters,
            isRetry: true,
          );
        } else {
          AppLogger.error('Token refresh failed', tag: 'AUTH');
        }
      }

      return _handleResponse(response, fromJsonT);
    } on Exception catch (error, stackTrace) {
      stopwatch.stop();
      AppLogger.error(
        'API request failed: $uri',
        error: error,
        stackTrace: stackTrace,
        tag: 'API',
      );
      return ApiResponse<T>(
        status: 'error',
        message: LocaleKeys.errorNetwork,
        statusCode: 500,
      );
    }
  }

  ApiResponse<T> _handleResponse<T>(
    http.Response response,
    T Function(dynamic)? fromJsonT,
  ) {
    Map<String, dynamic> responseBody;
    try {
      responseBody = jsonDecode(response.body);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to parse JSON response',
        error: e,
        stackTrace: stackTrace,
        tag: 'API',
      );
      return ApiResponse<T>(
        status: 'error',
        message: LocaleKeys.errorInvalidResponse,
        statusCode: response.statusCode,
      );
    }

    if (response.statusCode >= 400) {
      final apiMessage = responseBody['message'] ?? LocaleKeys.errorUnknown;
      AppLogger.debug('API error response: $apiMessage', tag: 'API');
      return ApiResponse<T>(
        status: 'error',
        message: apiMessage,
        statusCode: response.statusCode,
      );
    }

    return ApiResponse<T>.fromJson(responseBody, fromJsonT);
  }

  Future<http.Response> _makeRequest(
    String method,
    String uri,
    Map<String, String> headers,
    Map<String, dynamic>? dataToSend, {
    Map<String, dynamic>? queryParameters,
  }) async {
    var url = Uri.parse(uri);

    if (queryParameters != null && queryParameters.isNotEmpty) {
      url = url.replace(
        queryParameters: queryParameters.map(
          (key, value) => MapEntry(key, value.toString()),
        ),
      );
    }

    final body = dataToSend != null ? jsonEncode(dataToSend) : null;

    switch (method.toLowerCase()) {
      case 'get':
        return http.get(url, headers: headers);
      case 'post':
        return http.post(url, headers: headers, body: body);
      case 'put':
        return http.put(url, headers: headers, body: body);
      case 'delete':
        return http.delete(url, headers: headers, body: body);
      default:
        AppLogger.error('Unsupported HTTP method: $method', tag: 'API');
        throw Exception('Unsupported HTTP method: $method');
    }
  }

  Future<bool> refreshToken() async {
    if (_isRefreshing) {
      AppLogger.debug('Token refresh already in progress, waiting...', tag: 'AUTH');
      await Future<void>.delayed(const Duration(milliseconds: 100));
      return _isRefreshing == false;
    }

    _isRefreshing = true;
    AppLogger.auth('Starting token refresh');

    try {
      final refreshToken = await _storageService.readSecure('refresh_token');

      if (refreshToken == null || refreshToken.isEmpty) {
        AppLogger.warning('No refresh token available', tag: 'AUTH');
        _isRefreshing = false;
        return false;
      }

      final urlBase = await getApiAddress();
      final String refreshUri = '$urlBase/api/v2/auth/refresh';

      final headers = {
        'Content-Type': 'application/json',
        'Accept-Language': _lang,
      };

      final body = jsonEncode({'refreshToken': refreshToken});

      AppLogger.apiRequest('POST', refreshUri);

      final response = await http
          .post(Uri.parse(refreshUri), headers: headers, body: body)
          .timeout(_timeout, onTimeout: () {
            AppLogger.error('Token refresh timeout', tag: 'AUTH');
            throw Exception('Refresh timeout');
          });

      AppLogger.apiResponse(response.statusCode, refreshUri);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['status'] == 'success' && responseData['data'] != null) {
          final newAccessToken = responseData['data']['access_token'] as String?;
          final newRefreshToken = responseData['data']['refresh_token'] as String?;

          if (newAccessToken != null && newRefreshToken != null) {
            await _storageService.saveSecure('auth_token', newAccessToken);
            await _storageService.saveSecure('refresh_token', newRefreshToken);
            _cachedToken = null;
            _isRefreshing = false;
            AppLogger.auth('Token refresh successful');
            return true;
          }
        }
      }

      AppLogger.error('Token refresh failed with status ${response.statusCode}', tag: 'AUTH');
      _isRefreshing = false;
      return false;
    } catch (e, stackTrace) {
      AppLogger.error('Token refresh exception', error: e, stackTrace: stackTrace, tag: 'AUTH');
      _isRefreshing = false;
      return false;
    }
  }

  // Convenience methods
  Future<ApiResponse<Map<String, dynamic>>> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    bool requiredToken = true,
  }) async {
    String uri = endpoint;
    if (queryParameters != null && queryParameters.isNotEmpty) {
      final queryString = queryParameters.entries
          .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}')
          .join('&');
      uri = '$endpoint?$queryString';
    }
    return useFetch<Map<String, dynamic>>(
      uri,
      method: 'get',
      requiredToken: requiredToken,
      fromJsonT: (json) => json as Map<String, dynamic>,
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> post(
    String endpoint, {
    Map<String, dynamic>? data,
    bool requiredToken = true,
  }) async {
    return useFetch<Map<String, dynamic>>(
      endpoint,
      method: 'post',
      requiredToken: requiredToken,
      body: data,
      fromJsonT: (json) => json as Map<String, dynamic>,
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> put(
    String endpoint, {
    Map<String, dynamic>? data,
    bool requiredToken = true,
  }) async {
    return useFetch<Map<String, dynamic>>(
      endpoint,
      method: 'put',
      requiredToken: requiredToken,
      body: data,
      fromJsonT: (json) => json as Map<String, dynamic>,
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> delete(
    String endpoint, {
    Map<String, dynamic>? data,
    bool requiredToken = true,
  }) async {
    return useFetch<Map<String, dynamic>>(
      endpoint,
      method: 'delete',
      requiredToken: requiredToken,
      body: data,
      fromJsonT: (json) => json as Map<String, dynamic>,
    );
  }
}
