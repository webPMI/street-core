// lib/admin/repositories/security_repository.dart

import '../../../data/models/paginated_result.dart';
import '../models/security_alert_model.dart';
import '../models/security_event_model.dart';
import '../models/security_metrics_model.dart';
import '../models/threat_intel_model.dart';

/// Security Repository Interface
/// Defines security operations for event management, threat intelligence, and alerts
abstract class ISecurityRepository {
  // ========== Security Events ==========

  /// Fetch security events with pagination and filters
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
  });

  /// Fetch a single security event by ID
  Future<SecurityEvent> fetchEventById(String id);

  /// Mark a security event as resolved
  Future<void> resolveEvent(String id, String resolution);

  /// Mark a security event as false positive
  Future<void> markEventFalsePositive(String id, String reason);

  /// Export security events
  Future<String> exportEvents({
    String format = 'json',
    Map<String, dynamic>? filters,
  });

  // ========== Threat Intelligence ==========

  /// Fetch threat intelligence data for a specific IP address
  Future<ThreatIntel> fetchThreatIntelByIp(String ipAddress);

  /// Fetch threat intelligence with pagination and filters
  Future<PaginatedResult<ThreatIntel>> fetchThreatIntel({
    int page = 1,
    int limit = 50,
    String? threatLevel,
    bool? isBlocked,
  });

  /// Block an IP address
  Future<void> blockIp({
    required String ipAddress,
    required int durationMinutes,
    required String reason,
    String blockType = 'temporary',
  });

  /// Unblock an IP address
  Future<void> unblockIp(String ipAddress);

  /// Enrich threat intelligence data for an IP
  Future<ThreatIntel> enrichIpThreatIntel(String ipAddress);

  // ========== Security Alerts ==========

  /// Fetch security alerts with pagination and filters
  Future<PaginatedResult<SecurityAlert>> fetchAlerts({
    int page = 1,
    int limit = 50,
    String? severity,
    String? status,
    String? alertType,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Fetch a single security alert by ID
  Future<SecurityAlert> fetchAlertById(String id);

  /// Resolve a security alert
  Future<void> resolveAlert({
    required String id,
    required String resolutionType,
    required String resolutionNotes,
  });

  /// Escalate a security alert
  Future<void> escalateAlert(String id, String escalateTo);

  /// Assign a security alert to a user
  Future<void> assignAlert(String id, String assignTo);

  // ========== Security Metrics ==========

  /// Fetch security metrics
  Future<SecurityMetrics> fetchMetrics({
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Stream real-time security events
  Stream<SecurityEvent> streamEvents({
    String? severity,
    String? eventType,
  });

  // ========== Advanced Operations ==========

  /// Execute a security playbook
  Future<void> executePlaybook({
    required String playbookId,
    required Map<String, dynamic> parameters,
  });

  /// Predict threats using ML model
  Future<Map<String, dynamic>> predictThreat({
    required String modelName,
    required Map<String, dynamic> features,
  });

  /// Advanced search for security events
  Future<PaginatedResult<SecurityEvent>> searchEvents({
    required Map<String, dynamic> query,
    int page = 1,
    int limit = 50,
  });
}
