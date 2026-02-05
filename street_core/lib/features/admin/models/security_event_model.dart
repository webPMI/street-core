// lib/admin/models/security_event_model.dart

import 'package:equatable/equatable.dart';

/// Security Event Entity
class SecurityEvent extends Equatable {
  const SecurityEvent({
    required this.id,
    required this.eventType,
    required this.severity,
    required this.timestamp,
    required this.ipAddress,
    required this.userId,
    required this.userAgent,
    required this.endpoint,
    required this.method,
    required this.statusCode,
    required this.responseTime,
    required this.riskScore,
    required this.resolved,
    this.resolutionNotes,
    this.resolvedAt,
    this.resolvedBy,
    this.falsePositive = false,
    this.metadata,
  });

  final String id;
  final String eventType;
  final String severity;
  final DateTime timestamp;
  final String ipAddress;
  final String? userId;
  final String? userAgent;
  final String endpoint;
  final String method;
  final int statusCode;
  final int responseTime;
  final int riskScore;
  final bool resolved;
  final String? resolutionNotes;
  final DateTime? resolvedAt;
  final String? resolvedBy;
  final bool falsePositive;
  final Map<String, dynamic>? metadata;

  @override
  List<Object?> get props => [
        id,
        eventType,
        severity,
        timestamp,
        ipAddress,
        userId,
        userAgent,
        endpoint,
        method,
        statusCode,
        responseTime,
        riskScore,
        resolved,
        resolutionNotes,
        resolvedAt,
        resolvedBy,
        falsePositive,
        metadata,
      ];
}

/// Security Event Model (Data Transfer Object)
class SecurityEventModel extends SecurityEvent {
  const SecurityEventModel({
    required super.id,
    required super.eventType,
    required super.severity,
    required super.timestamp,
    required super.ipAddress,
    required super.userId,
    required super.userAgent,
    required super.endpoint,
    required super.method,
    required super.statusCode,
    required super.responseTime,
    required super.riskScore,
    required super.resolved,
    super.resolutionNotes,
    super.resolvedAt,
    super.resolvedBy,
    super.falsePositive,
    super.metadata,
  });

  /// Create from JSON
  factory SecurityEventModel.fromJson(Map<String, dynamic> json) {
    return SecurityEventModel(
      id: json['id'] as String,
      eventType: json['event_type'] as String,
      severity: json['severity'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      ipAddress: json['ip_address'] as String,
      userId: json['user_id'] as String?,
      userAgent: json['user_agent'] as String?,
      endpoint: json['endpoint'] as String,
      method: json['method'] as String,
      statusCode: json['status_code'] as int,
      responseTime: json['response_time'] as int,
      riskScore: json['risk_score'] as int,
      resolved: json['resolved'] as bool,
      resolutionNotes: json['resolution_notes'] as String?,
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'] as String)
          : null,
      resolvedBy: json['resolved_by'] as String?,
      falsePositive: json['false_positive'] as bool? ?? false,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event_type': eventType,
      'severity': severity,
      'timestamp': timestamp.toIso8601String(),
      'ip_address': ipAddress,
      if (userId != null) 'user_id': userId,
      if (userAgent != null) 'user_agent': userAgent,
      'endpoint': endpoint,
      'method': method,
      'status_code': statusCode,
      'response_time': responseTime,
      'risk_score': riskScore,
      'resolved': resolved,
      if (resolutionNotes != null) 'resolution_notes': resolutionNotes,
      if (resolvedAt != null) 'resolved_at': resolvedAt!.toIso8601String(),
      if (resolvedBy != null) 'resolved_by': resolvedBy,
      'false_positive': falsePositive,
      if (metadata != null) 'metadata': metadata,
    };
  }

  /// Create a copy with modified fields
  SecurityEventModel copyWith({
    String? id,
    String? eventType,
    String? severity,
    DateTime? timestamp,
    String? ipAddress,
    String? userId,
    String? userAgent,
    String? endpoint,
    String? method,
    int? statusCode,
    int? responseTime,
    int? riskScore,
    bool? resolved,
    String? resolutionNotes,
    DateTime? resolvedAt,
    String? resolvedBy,
    bool? falsePositive,
    Map<String, dynamic>? metadata,
  }) {
    return SecurityEventModel(
      id: id ?? this.id,
      eventType: eventType ?? this.eventType,
      severity: severity ?? this.severity,
      timestamp: timestamp ?? this.timestamp,
      ipAddress: ipAddress ?? this.ipAddress,
      userId: userId ?? this.userId,
      userAgent: userAgent ?? this.userAgent,
      endpoint: endpoint ?? this.endpoint,
      method: method ?? this.method,
      statusCode: statusCode ?? this.statusCode,
      responseTime: responseTime ?? this.responseTime,
      riskScore: riskScore ?? this.riskScore,
      resolved: resolved ?? this.resolved,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      falsePositive: falsePositive ?? this.falsePositive,
      metadata: metadata ?? this.metadata,
    );
  }
}
