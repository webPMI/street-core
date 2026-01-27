// lib/admin/repositories/security_repository_impl.dart

import '../../../core/services/api_service.dart';
import '../../../data/models/paginated_result.dart';
import '../models/security_alert_model.dart';
import '../models/security_event_model.dart';
import '../models/security_metrics_model.dart';
import '../models/threat_intel_model.dart';
import './security_repository.dart';

/// Security Repository Implementation
/// Implements security operations using the API service
class SecurityRepositoryImpl implements ISecurityRepository {
  SecurityRepositoryImpl(this._apiService);

  final ApiService _apiService;

  // ========== Security Events ==========

  @override
  Future<PaginatedResult<SecurityEvent>> fetchEvents({
    int page = 1,
    int limit = 50,
    String? severity,
    String? eventType,
    DateTime? startDate,
    DateTime? endDate,
    String? ipAddress,
    String? userId,
    bool? resolved,
    int? riskScoreMin,
    int? riskScoreMax,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (severity != null) 'severity': severity,
      if (eventType != null) 'event_type': eventType,
      if (startDate != null) 'start_date': startDate.toIso8601String(),
      if (endDate != null) 'end_date': endDate.toIso8601String(),
      if (ipAddress != null) 'ip_address': ipAddress,
      if (userId != null) 'user_id': userId,
      if (resolved != null) 'resolved': resolved,
      if (riskScoreMin != null) 'risk_score_min': riskScoreMin,
      if (riskScoreMax != null) 'risk_score_max': riskScoreMax,
    };

    final response = await _apiService.useFetch(
      '/admin/security/events',
      method: 'GET',
      queryParameters: queryParams,
    );

    final result = PaginatedResult<SecurityEvent>.fromJson(
      response.data,
      (json) => SecurityEventModel.fromJson(json),
    );

    // Map items to results for backward compatibility
    return PaginatedResult<SecurityEvent>(
      items: result.items,
      currentPage: result.currentPage,
      totalPages: result.totalPages,
      totalItems: result.totalItems,
      itemsPerPage: result.itemsPerPage,
      hasNext: result.hasNext,
      hasPrevious: result.hasPrevious,
    );
  }

  @override
  Future<SecurityEvent> fetchEventById(String id) async {
    final response = await _apiService.useFetch(
      '/admin/security/events/$id',
      method: 'GET',
    );

    return SecurityEventModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> resolveEvent(String id, String resolution) async {
    await _apiService.useFetch(
      '/admin/security/events/$id/resolve',
      method: 'POST',
      body: {'resolution': resolution},
    );
  }

  @override
  Future<void> markEventFalsePositive(String id, String reason) async {
    await _apiService.useFetch(
      '/admin/security/events/$id/false-positive',
      method: 'POST',
      body: {'reason': reason},
    );
  }

  @override
  Future<String> exportEvents({
    String format = 'json',
    Map<String, dynamic>? filters,
  }) async {
    final response = await _apiService.useFetch(
      '/admin/security/events/export',
      method: 'POST',
      body: {'format': format, if (filters != null) 'filters': filters},
    );

    return response.data['download_url'] as String;
  }

  // ========== Threat Intelligence ==========

  @override
  Future<ThreatIntel> fetchThreatIntelByIp(String ipAddress) async {
    final response = await _apiService.useFetch(
      '/admin/security/threat-intel/$ipAddress',
      method: 'GET',
    );

    return ThreatIntelModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<PaginatedResult<ThreatIntel>> fetchThreatIntel({
    int page = 1,
    int limit = 50,
    String? threatLevel,
    bool? isBlocked,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (threatLevel != null) 'threat_level': threatLevel,
      if (isBlocked != null) 'is_blocked': isBlocked,
    };

    final response = await _apiService.useFetch(
      '/admin/security/threat-intel',
      method: 'GET',
      queryParameters: queryParams,
    );

    return PaginatedResult<ThreatIntel>.fromJson(
      response.data,
      (json) => ThreatIntelModel.fromJson(json),
    );
  }

  @override
  Future<void> blockIp({
    required String ipAddress,
    required int durationMinutes,
    required String reason,
    String blockType = 'temporary',
  }) async {
    await _apiService.useFetch(
      '/admin/security/threat-intel/$ipAddress/block',
      method: 'POST',
      body: {
        'duration_minutes': durationMinutes,
        'reason': reason,
        'block_type': blockType,
      },
    );
  }

  @override
  Future<void> unblockIp(String ipAddress) async {
    await _apiService.useFetch(
      '/admin/security/threat-intel/$ipAddress/unblock',
      method: 'POST',
    );
  }

  @override
  Future<ThreatIntel> enrichIpThreatIntel(String ipAddress) async {
    final response = await _apiService.useFetch(
      '/admin/security/threat-intel/$ipAddress/enrich',
      method: 'POST',
    );

    return ThreatIntelModel.fromJson(response.data as Map<String, dynamic>);
  }

  // ========== Security Alerts ==========

  @override
  Future<PaginatedResult<SecurityAlert>> fetchAlerts({
    int page = 1,
    int limit = 50,
    String? severity,
    String? status,
    String? alertType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (severity != null) 'severity': severity,
      if (status != null) 'status': status,
      if (alertType != null) 'alert_type': alertType,
      if (startDate != null) 'start_date': startDate.toIso8601String(),
      if (endDate != null) 'end_date': endDate.toIso8601String(),
    };

    final response = await _apiService.useFetch(
      '/admin/security/alerts',
      method: 'GET',
      queryParameters: queryParams,
    );

    return PaginatedResult<SecurityAlert>.fromJson(
      response.data,
      (json) => SecurityAlertModel.fromJson(json),
    );
  }

  @override
  Future<SecurityAlert> fetchAlertById(String id) async {
    final response = await _apiService.useFetch(
      '/admin/security/alerts/$id',
      method: 'GET',
    );

    return SecurityAlertModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> resolveAlert({
    required String id,
    required String resolutionType,
    required String resolutionNotes,
  }) async {
    await _apiService.useFetch(
      '/admin/security/alerts/$id/resolve',
      method: 'POST',
      body: {
        'resolution_type': resolutionType,
        'resolution_notes': resolutionNotes,
      },
    );
  }

  @override
  Future<void> escalateAlert(String id, String escalateTo) async {
    await _apiService.useFetch(
      '/admin/security/alerts/$id/escalate',
      method: 'POST',
      body: {'escalate_to': escalateTo},
    );
  }

  @override
  Future<void> assignAlert(String id, String assignTo) async {
    await _apiService.useFetch(
      '/admin/security/alerts/$id/assign',
      method: 'POST',
      body: {'assign_to': assignTo},
    );
  }

  // ========== Security Metrics ==========

  @override
  Future<SecurityMetrics> fetchMetrics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final queryParams = <String, dynamic>{
      if (startDate != null) 'start_date': startDate.toIso8601String(),
      if (endDate != null) 'end_date': endDate.toIso8601String(),
    };

    final response = await _apiService.useFetch(
      '/admin/security/metrics',
      method: 'GET',
      queryParameters: queryParams,
    );

    return SecurityMetricsModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Stream<SecurityEvent> streamEvents({
    String? severity,
    String? eventType,
  }) async* {
    // TODO: Implement SSE streaming when backend supports it
    // For now, return empty stream
    yield* const Stream.empty();
  }

  // ========== Advanced Operations ==========

  @override
  Future<void> executePlaybook({
    required String playbookId,
    required Map<String, dynamic> parameters,
  }) async {
    await _apiService.useFetch(
      '/admin/security/playbooks/$playbookId/execute',
      method: 'POST',
      body: {'parameters': parameters},
    );
  }

  @override
  Future<Map<String, dynamic>> predictThreat({
    required String modelName,
    required Map<String, dynamic> features,
  }) async {
    final response = await _apiService.useFetch(
      '/admin/security/ml/predict',
      method: 'POST',
      body: {'model_name': modelName, 'features': features},
    );

    return response.data as Map<String, dynamic>;
  }

  @override
  Future<PaginatedResult<SecurityEvent>> searchEvents({
    required Map<String, dynamic> query,
    int page = 1,
    int limit = 50,
  }) async {
    final response = await _apiService.useFetch(
      '/admin/security/events/search',
      method: 'POST',
      body: {'query': query, 'page': page, 'limit': limit},
    );

    final result = PaginatedResult<SecurityEvent>.fromJson(
      response.data,
      (json) => SecurityEventModel.fromJson(json),
    );

    // Map items to results for backward compatibility
    return PaginatedResult<SecurityEvent>(
      items: result.items,
      currentPage: result.currentPage,
      totalPages: result.totalPages,
      totalItems: result.totalItems,
      itemsPerPage: result.itemsPerPage,
      hasNext: result.hasNext,
      hasPrevious: result.hasPrevious,
    );
  }
}
