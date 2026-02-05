// lib/admin/models/security_metrics_model.dart

import 'package:equatable/equatable.dart';

/// Security Metrics Entity
class SecurityMetrics extends Equatable {
  const SecurityMetrics({
    required this.startDate,
    required this.endDate,
    required this.totalEvents,
    required this.totalAlerts,
    required this.resolvedAlerts,
    required this.pendingAlerts,
    required this.criticalAlerts,
    required this.highAlerts,
    required this.mediumAlerts,
    required this.lowAlerts,
    required this.blockedIps,
    required this.uniqueThreats,
    required this.averageRiskScore,
    required this.totalBlocked,
    required this.falsePositives,
    this.eventsByType,
    this.eventsBySeverity,
    this.topThreats,
    this.topAffectedResources,
    this.trendData,
    this.metadata,
  });

  final DateTime startDate;
  final DateTime endDate;
  final int totalEvents;
  final int totalAlerts;
  final int resolvedAlerts;
  final int pendingAlerts;
  final int criticalAlerts;
  final int highAlerts;
  final int mediumAlerts;
  final int lowAlerts;
  final int blockedIps;
  final int uniqueThreats;
  final double averageRiskScore;
  final int totalBlocked;
  final int falsePositives;
  final Map<String, int>? eventsByType;
  final Map<String, int>? eventsBySeverity;
  final List<ThreatSummary>? topThreats;
  final List<String>? topAffectedResources;
  final List<TrendDataPoint>? trendData;
  final Map<String, dynamic>? metadata;

  @override
  List<Object?> get props => [
        startDate,
        endDate,
        totalEvents,
        totalAlerts,
        resolvedAlerts,
        pendingAlerts,
        criticalAlerts,
        highAlerts,
        mediumAlerts,
        lowAlerts,
        blockedIps,
        uniqueThreats,
        averageRiskScore,
        totalBlocked,
        falsePositives,
        eventsByType,
        eventsBySeverity,
        topThreats,
        topAffectedResources,
        trendData,
        metadata,
      ];
}

/// Threat Summary
class ThreatSummary extends Equatable {
  const ThreatSummary({
    required this.threatType,
    required this.count,
    required this.severity,
  });

  final String threatType;
  final int count;
  final String severity;

  @override
  List<Object?> get props => [threatType, count, severity];

  factory ThreatSummary.fromJson(Map<String, dynamic> json) {
    return ThreatSummary(
      threatType: json['threat_type'] as String,
      count: json['count'] as int,
      severity: json['severity'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'threat_type': threatType,
      'count': count,
      'severity': severity,
    };
  }
}

/// Trend Data Point
class TrendDataPoint extends Equatable {
  const TrendDataPoint({
    required this.timestamp,
    required this.value,
    this.label,
  });

  final DateTime timestamp;
  final double value;
  final String? label;

  @override
  List<Object?> get props => [timestamp, value, label];

  factory TrendDataPoint.fromJson(Map<String, dynamic> json) {
    return TrendDataPoint(
      timestamp: DateTime.parse(json['timestamp'] as String),
      value: (json['value'] as num).toDouble(),
      label: json['label'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'value': value,
      if (label != null) 'label': label,
    };
  }
}

/// Security Metrics Model (Data Transfer Object)
class SecurityMetricsModel extends SecurityMetrics {
  const SecurityMetricsModel({
    required super.startDate,
    required super.endDate,
    required super.totalEvents,
    required super.totalAlerts,
    required super.resolvedAlerts,
    required super.pendingAlerts,
    required super.criticalAlerts,
    required super.highAlerts,
    required super.mediumAlerts,
    required super.lowAlerts,
    required super.blockedIps,
    required super.uniqueThreats,
    required super.averageRiskScore,
    required super.totalBlocked,
    required super.falsePositives,
    super.eventsByType,
    super.eventsBySeverity,
    super.topThreats,
    super.topAffectedResources,
    super.trendData,
    super.metadata,
  });

  /// Create from JSON
  factory SecurityMetricsModel.fromJson(Map<String, dynamic> json) {
    return SecurityMetricsModel(
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      totalEvents: json['total_events'] as int,
      totalAlerts: json['total_alerts'] as int,
      resolvedAlerts: json['resolved_alerts'] as int,
      pendingAlerts: json['pending_alerts'] as int,
      criticalAlerts: json['critical_alerts'] as int,
      highAlerts: json['high_alerts'] as int,
      mediumAlerts: json['medium_alerts'] as int,
      lowAlerts: json['low_alerts'] as int,
      blockedIps: json['blocked_ips'] as int,
      uniqueThreats: json['unique_threats'] as int,
      averageRiskScore: (json['average_risk_score'] as num).toDouble(),
      totalBlocked: json['total_blocked'] as int,
      falsePositives: json['false_positives'] as int,
      eventsByType: (json['events_by_type'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(k, v as int)),
      eventsBySeverity: (json['events_by_severity'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(k, v as int)),
      topThreats: (json['top_threats'] as List<dynamic>?)
          ?.map((e) => ThreatSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
      topAffectedResources: (json['top_affected_resources'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      trendData: (json['trend_data'] as List<dynamic>?)
          ?.map((e) => TrendDataPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'total_events': totalEvents,
      'total_alerts': totalAlerts,
      'resolved_alerts': resolvedAlerts,
      'pending_alerts': pendingAlerts,
      'critical_alerts': criticalAlerts,
      'high_alerts': highAlerts,
      'medium_alerts': mediumAlerts,
      'low_alerts': lowAlerts,
      'blocked_ips': blockedIps,
      'unique_threats': uniqueThreats,
      'average_risk_score': averageRiskScore,
      'total_blocked': totalBlocked,
      'false_positives': falsePositives,
      if (eventsByType != null) 'events_by_type': eventsByType,
      if (eventsBySeverity != null) 'events_by_severity': eventsBySeverity,
      if (topThreats != null)
        'top_threats': topThreats!.map((e) => e.toJson()).toList(),
      if (topAffectedResources != null)
        'top_affected_resources': topAffectedResources,
      if (trendData != null)
        'trend_data': trendData!.map((e) => e.toJson()).toList(),
      if (metadata != null) 'metadata': metadata,
    };
  }

  /// Create a copy with modified fields
  SecurityMetricsModel copyWith({
    DateTime? startDate,
    DateTime? endDate,
    int? totalEvents,
    int? totalAlerts,
    int? resolvedAlerts,
    int? pendingAlerts,
    int? criticalAlerts,
    int? highAlerts,
    int? mediumAlerts,
    int? lowAlerts,
    int? blockedIps,
    int? uniqueThreats,
    double? averageRiskScore,
    int? totalBlocked,
    int? falsePositives,
    Map<String, int>? eventsByType,
    Map<String, int>? eventsBySeverity,
    List<ThreatSummary>? topThreats,
    List<String>? topAffectedResources,
    List<TrendDataPoint>? trendData,
    Map<String, dynamic>? metadata,
  }) {
    return SecurityMetricsModel(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      totalEvents: totalEvents ?? this.totalEvents,
      totalAlerts: totalAlerts ?? this.totalAlerts,
      resolvedAlerts: resolvedAlerts ?? this.resolvedAlerts,
      pendingAlerts: pendingAlerts ?? this.pendingAlerts,
      criticalAlerts: criticalAlerts ?? this.criticalAlerts,
      highAlerts: highAlerts ?? this.highAlerts,
      mediumAlerts: mediumAlerts ?? this.mediumAlerts,
      lowAlerts: lowAlerts ?? this.lowAlerts,
      blockedIps: blockedIps ?? this.blockedIps,
      uniqueThreats: uniqueThreats ?? this.uniqueThreats,
      averageRiskScore: averageRiskScore ?? this.averageRiskScore,
      totalBlocked: totalBlocked ?? this.totalBlocked,
      falsePositives: falsePositives ?? this.falsePositives,
      eventsByType: eventsByType ?? this.eventsByType,
      eventsBySeverity: eventsBySeverity ?? this.eventsBySeverity,
      topThreats: topThreats ?? this.topThreats,
      topAffectedResources: topAffectedResources ?? this.topAffectedResources,
      trendData: trendData ?? this.trendData,
      metadata: metadata ?? this.metadata,
    );
  }
}
