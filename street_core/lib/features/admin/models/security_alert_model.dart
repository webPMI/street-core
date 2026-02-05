// lib/admin/models/security_alert_model.dart

import 'package:equatable/equatable.dart';

/// Security Alert Entity
class SecurityAlert extends Equatable {
  const SecurityAlert({
    required this.id,
    required this.alertType,
    required this.severity,
    required this.status,
    required this.title,
    required this.description,
    required this.createdAt,
    this.updatedAt,
    this.resolvedAt,
    this.resolutionType,
    this.resolutionNotes,
    this.assignedTo,
    this.escalatedTo,
    this.relatedEvents,
    this.affectedResources,
    this.recommendedActions,
    this.metadata,
  });

  final String id;
  final String alertType;
  final String severity;
  final String status;
  final String title;
  final String description;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? resolvedAt;
  final String? resolutionType;
  final String? resolutionNotes;
  final String? assignedTo;
  final String? escalatedTo;
  final List<String>? relatedEvents;
  final List<String>? affectedResources;
  final List<String>? recommendedActions;
  final Map<String, dynamic>? metadata;

  @override
  List<Object?> get props => [
        id,
        alertType,
        severity,
        status,
        title,
        description,
        createdAt,
        updatedAt,
        resolvedAt,
        resolutionType,
        resolutionNotes,
        assignedTo,
        escalatedTo,
        relatedEvents,
        affectedResources,
        recommendedActions,
        metadata,
      ];
}

/// Security Alert Model (Data Transfer Object)
class SecurityAlertModel extends SecurityAlert {
  const SecurityAlertModel({
    required super.id,
    required super.alertType,
    required super.severity,
    required super.status,
    required super.title,
    required super.description,
    required super.createdAt,
    super.updatedAt,
    super.resolvedAt,
    super.resolutionType,
    super.resolutionNotes,
    super.assignedTo,
    super.escalatedTo,
    super.relatedEvents,
    super.affectedResources,
    super.recommendedActions,
    super.metadata,
  });

  /// Create from JSON
  factory SecurityAlertModel.fromJson(Map<String, dynamic> json) {
    return SecurityAlertModel(
      id: json['id'] as String,
      alertType: json['alert_type'] as String,
      severity: json['severity'] as String,
      status: json['status'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'] as String)
          : null,
      resolutionType: json['resolution_type'] as String?,
      resolutionNotes: json['resolution_notes'] as String?,
      assignedTo: json['assigned_to'] as String?,
      escalatedTo: json['escalated_to'] as String?,
      relatedEvents: (json['related_events'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      affectedResources: (json['affected_resources'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      recommendedActions: (json['recommended_actions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'alert_type': alertType,
      'severity': severity,
      'status': status,
      'title': title,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      if (resolvedAt != null) 'resolved_at': resolvedAt!.toIso8601String(),
      if (resolutionType != null) 'resolution_type': resolutionType,
      if (resolutionNotes != null) 'resolution_notes': resolutionNotes,
      if (assignedTo != null) 'assigned_to': assignedTo,
      if (escalatedTo != null) 'escalated_to': escalatedTo,
      if (relatedEvents != null) 'related_events': relatedEvents,
      if (affectedResources != null) 'affected_resources': affectedResources,
      if (recommendedActions != null)
        'recommended_actions': recommendedActions,
      if (metadata != null) 'metadata': metadata,
    };
  }

  /// Create a copy with modified fields
  SecurityAlertModel copyWith({
    String? id,
    String? alertType,
    String? severity,
    String? status,
    String? title,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? resolvedAt,
    String? resolutionType,
    String? resolutionNotes,
    String? assignedTo,
    String? escalatedTo,
    List<String>? relatedEvents,
    List<String>? affectedResources,
    List<String>? recommendedActions,
    Map<String, dynamic>? metadata,
  }) {
    return SecurityAlertModel(
      id: id ?? this.id,
      alertType: alertType ?? this.alertType,
      severity: severity ?? this.severity,
      status: status ?? this.status,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolutionType: resolutionType ?? this.resolutionType,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
      assignedTo: assignedTo ?? this.assignedTo,
      escalatedTo: escalatedTo ?? this.escalatedTo,
      relatedEvents: relatedEvents ?? this.relatedEvents,
      affectedResources: affectedResources ?? this.affectedResources,
      recommendedActions: recommendedActions ?? this.recommendedActions,
      metadata: metadata ?? this.metadata,
    );
  }
}
