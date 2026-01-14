/// Heat Model - Competition heat/group structure for organizing athletes.
/// Following Monolith-by-Features architecture (ADR-005).
///
/// Heats allow competitions to organize athletes into smaller groups for:
/// - Sequential scoring (one athlete at a time)
/// - Simultaneous scoring (all athletes compete together)

import 'package:equatable/equatable.dart';

// =============================================================================
// ENUMS
// =============================================================================

/// Heat mode determines judge UI behavior
enum HeatMode {
  /// Athletes compete one at a time (skateboarding, BMX freestyle)
  sequential('sequential'),

  /// Athletes compete simultaneously (racing, park jams)
  simultaneous('simultaneous');

  const HeatMode(this.value);
  final String value;

  /// Parse from JSON string
  static HeatMode fromString(String value) {
    return HeatMode.values.firstWhere(
      (mode) => mode.value == value,
      orElse: () => HeatMode.sequential,
    );
  }
}

/// Heat status lifecycle
enum HeatStatus {
  /// Heat is created but not started
  pending('pending'),

  /// Heat is currently active
  active('active'),

  /// Heat is completed
  completed('completed');

  const HeatStatus(this.value);
  final String value;

  /// Parse from JSON string
  static HeatStatus fromString(String value) {
    return HeatStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => HeatStatus.pending,
    );
  }
}

// =============================================================================
// HEAT MODEL
// =============================================================================

/// Heat represents a group of athletes within a round
class Heat extends Equatable {
  const Heat({
    required this.id,
    required this.competitionId,
    required this.roundId,
    required this.name,
    required this.order,
    required this.mode,
    required this.status,
    this.categoryId,
    this.athleteIds = const [],
    this.athleteOrder = const [],
    this.maxAthletes,
    this.startTime,
    this.endTime,
    this.duration,
    this.createdAt,
    this.updatedAt,
  });

  /// Create Heat from JSON response
  factory Heat.fromJson(Map<String, dynamic> json) {
    return Heat(
      id: json['id'] as String,
      competitionId: json['competitionId'] as String,
      roundId: json['roundId'] as String,
      name: json['name'] as String,
      order: json['order'] as int,
      mode: HeatMode.fromString(json['mode'] as String),
      status: HeatStatus.fromString(json['status'] as String),
      categoryId: json['categoryId'] as String?,
      athleteIds: (json['athleteIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      athleteOrder: (json['athleteOrder'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      maxAthletes: json['maxAthletes'] as int?,
      startTime: json['startTime'] != null
          ? DateTime.parse(json['startTime'] as String)
          : null,
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      duration: json['duration'] as int?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  // Core identification
  final String id;
  final String competitionId;
  final String roundId;
  final String? categoryId;

  // Heat configuration
  final String name; // e.g., "Heat 1"
  final int order; // Display order
  final HeatMode mode; // sequential | simultaneous
  final HeatStatus status; // pending | active | completed
  final int? maxAthletes; // Capacity limit

  // Athletes
  final List<String> athleteIds; // All athletes in this heat
  final List<String> athleteOrder; // Order for sequential mode

  // Timing
  final DateTime? startTime;
  final DateTime? endTime;
  final int? duration; // Duration in seconds

  // Metadata
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Convert to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'competitionId': competitionId,
      'roundId': roundId,
      if (categoryId != null) 'categoryId': categoryId,
      'name': name,
      'order': order,
      'mode': mode.value,
      'status': status.value,
      if (maxAthletes != null) 'maxAthletes': maxAthletes,
      'athleteIds': athleteIds,
      'athleteOrder': athleteOrder,
      if (startTime != null) 'startTime': startTime!.toIso8601String(),
      if (endTime != null) 'endTime': endTime!.toIso8601String(),
      if (duration != null) 'duration': duration,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  // ==========================================================================
  // HELPER METHODS
  // ==========================================================================

  /// Check if this is a sequential heat
  bool get isSequential => mode == HeatMode.sequential;

  /// Check if this is a simultaneous heat
  bool get isSimultaneous => mode == HeatMode.simultaneous;

  /// Check if heat is pending
  bool get isPending => status == HeatStatus.pending;

  /// Check if heat is active
  bool get isActive => status == HeatStatus.active;

  /// Check if heat is completed
  bool get isCompleted => status == HeatStatus.completed;

  /// Get number of athletes in this heat
  int get athleteCount => athleteIds.length;

  /// Check if heat is full
  bool get isFull => maxAthletes != null && athleteCount >= maxAthletes!;

  /// Check if heat has available slots
  bool get hasAvailableSlots => !isFull;

  /// Check if a specific athlete is in this heat
  bool hasAthlete(String athleteId) => athleteIds.contains(athleteId);

  /// Get athlete position in order (for sequential mode)
  /// Returns -1 if not found or if not using athlete order
  int getAthletePosition(String athleteId) {
    if (athleteOrder.isEmpty) return -1;
    return athleteOrder.indexOf(athleteId);
  }

  /// Get percentage of slots filled
  double get fillPercentage {
    if (maxAthletes == null || maxAthletes == 0) return 0.0;
    return (athleteCount / maxAthletes!) * 100;
  }

  /// Get display name for UI
  String get displayName => name;

  /// Get status display text
  String get statusDisplay {
    switch (status) {
      case HeatStatus.pending:
        return 'Pendiente';
      case HeatStatus.active:
        return 'En curso';
      case HeatStatus.completed:
        return 'Completado';
    }
  }

  /// Get mode display text
  String get modeDisplay {
    switch (mode) {
      case HeatMode.sequential:
        return 'Secuencial';
      case HeatMode.simultaneous:
        return 'Simultáneo';
    }
  }

  /// Copy with method for immutability
  Heat copyWith({
    String? id,
    String? competitionId,
    String? roundId,
    String? categoryId,
    String? name,
    int? order,
    HeatMode? mode,
    HeatStatus? status,
    int? maxAthletes,
    List<String>? athleteIds,
    List<String>? athleteOrder,
    DateTime? startTime,
    DateTime? endTime,
    int? duration,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Heat(
      id: id ?? this.id,
      competitionId: competitionId ?? this.competitionId,
      roundId: roundId ?? this.roundId,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      order: order ?? this.order,
      mode: mode ?? this.mode,
      status: status ?? this.status,
      maxAthletes: maxAthletes ?? this.maxAthletes,
      athleteIds: athleteIds ?? this.athleteIds,
      athleteOrder: athleteOrder ?? this.athleteOrder,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      duration: duration ?? this.duration,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        competitionId,
        roundId,
        categoryId,
        name,
        order,
        mode,
        status,
        maxAthletes,
        athleteIds,
        athleteOrder,
        startTime,
        endTime,
        duration,
        createdAt,
        updatedAt,
      ];

  @override
  String toString() {
    return 'Heat(id: $id, name: $name, mode: ${mode.value}, status: ${status.value}, athletes: $athleteCount)';
  }
}
