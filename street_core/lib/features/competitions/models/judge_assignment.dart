/// Modelo de Asignación de Juez - Representa un juez asignado a una competición.
/// Following Monolith-by-Features architecture (ADR-005).

import 'package:equatable/equatable.dart';
import './competition.dart';

/// Asignación de juez a una competición.
class JudgeAssignment extends Equatable {
  const JudgeAssignment({
    required this.id,
    required this.competitionId,
    required this.competition,
    required this.judgeId,
    required this.judgeName,
    this.judgeEmail,
    this.categoryIds = const [],
    this.categoryNames = const [],
    this.role,
    this.status = 'active',
    this.assignedAt,
    this.acceptedAt,
    this.notes,
  });

  factory JudgeAssignment.fromJson(Map<String, dynamic> json) {
    return JudgeAssignment(
      id: json['id'] as String,
      competitionId: json['competitionId'] as String,
      competition: Competition.fromJson(
        json['competition'] as Map<String, dynamic>,
      ),
      judgeId: json['judgeId'] as String,
      judgeName: json['judgeName'] as String? ?? '',
      judgeEmail: json['judgeEmail'] as String?,
      categoryIds:
          (json['categoryIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      categoryNames:
          (json['categoryNames'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      role: json['role'] as String?,
      status: json['status'] as String? ?? 'active',
      assignedAt: json['assignedAt'] != null
          ? DateTime.parse(json['assignedAt'] as String)
          : null,
      acceptedAt: json['acceptedAt'] != null
          ? DateTime.parse(json['acceptedAt'] as String)
          : null,
      notes: json['notes'] as String?,
    );
  }

  final String id;
  final String competitionId;
  final Competition competition;
  final String judgeId;
  final String judgeName;
  final String? judgeEmail;
  final List<String> categoryIds;
  final List<String> categoryNames;
  final String? role;
  final String status;
  final DateTime? assignedAt;
  final DateTime? acceptedAt;
  final String? notes;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'competitionId': competitionId,
      'competition': competition.toJson(),
      'judgeId': judgeId,
      'judgeName': judgeName,
      'judgeEmail': judgeEmail,
      'categoryIds': categoryIds,
      'categoryNames': categoryNames,
      'role': role,
      'status': status,
      'assignedAt': assignedAt?.toIso8601String(),
      'acceptedAt': acceptedAt?.toIso8601String(),
      'notes': notes,
    };
  }

  @override
  List<Object?> get props => [id, competitionId, judgeId, status];
}
