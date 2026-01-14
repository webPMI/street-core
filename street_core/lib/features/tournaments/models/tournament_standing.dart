import 'package:equatable/equatable.dart';

/// Tournament Standing model representing athlete rankings
class TournamentStanding extends Equatable {
  final String id;
  final String tournamentId;
  final String athleteId;
  final String athleteName;
  final String? athleteAvatar;
  final int position;
  final int? previousPosition;
  final double totalPoints;
  final double countedPoints;
  final List<CompetitionResult> competitionResults;
  final int competitionsCompleted;
  final int competitionsMissed;
  final String? lastCompetitionId;
  final DateTime? lastUpdated;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TournamentStanding({
    required this.id,
    required this.tournamentId,
    required this.athleteId,
    required this.athleteName,
    this.athleteAvatar,
    required this.position,
    this.previousPosition,
    required this.totalPoints,
    required this.countedPoints,
    required this.competitionResults,
    required this.competitionsCompleted,
    required this.competitionsMissed,
    this.lastCompetitionId,
    this.lastUpdated,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TournamentStanding.fromJson(Map<String, dynamic> json) {
    return TournamentStanding(
      id: json['id'] as String,
      tournamentId: json['tournamentId'] as String,
      athleteId: json['athleteId'] as String,
      athleteName: json['athleteName'] as String,
      athleteAvatar: json['athleteAvatar'] as String?,
      position: json['position'] as int,
      previousPosition: json['previousPosition'] as int?,
      totalPoints: (json['totalPoints'] as num).toDouble(),
      countedPoints: (json['countedPoints'] as num).toDouble(),
      competitionResults: (json['competitionResults'] as List<dynamic>?)
              ?.map((e) => CompetitionResult.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      competitionsCompleted: json['competitionsCompleted'] as int? ?? 0,
      competitionsMissed: json['competitionsMissed'] as int? ?? 0,
      lastCompetitionId: json['lastCompetitionId'] as String?,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tournamentId': tournamentId,
      'athleteId': athleteId,
      'athleteName': athleteName,
      'athleteAvatar': athleteAvatar,
      'position': position,
      'previousPosition': previousPosition,
      'totalPoints': totalPoints,
      'countedPoints': countedPoints,
      'competitionResults': competitionResults.map((e) => e.toJson()).toList(),
      'competitionsCompleted': competitionsCompleted,
      'competitionsMissed': competitionsMissed,
      'lastCompetitionId': lastCompetitionId,
      'lastUpdated': lastUpdated?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Get position change indicator (up/down/stable)
  String get positionChange {
    if (previousPosition == null) return 'new';
    if (previousPosition! > position) return 'up';
    if (previousPosition! < position) return 'down';
    return 'stable';
  }

  /// Get position change value
  int? get positionDiff {
    if (previousPosition == null) return null;
    return previousPosition! - position;
  }

  @override
  List<Object?> get props => [
        id,
        tournamentId,
        athleteId,
        position,
        totalPoints,
        countedPoints,
        updatedAt,
      ];
}

/// Competition Result within a tournament
class CompetitionResult extends Equatable {
  final String competitionId;
  final String competitionName;
  final DateTime competitionDate;
  final int position;
  final double points;
  final bool isCounted;
  final String? notes;

  const CompetitionResult({
    required this.competitionId,
    required this.competitionName,
    required this.competitionDate,
    required this.position,
    required this.points,
    required this.isCounted,
    this.notes,
  });

  factory CompetitionResult.fromJson(Map<String, dynamic> json) {
    return CompetitionResult(
      competitionId: json['competitionId'] as String,
      competitionName: json['competitionName'] as String,
      competitionDate: DateTime.parse(json['competitionDate'] as String),
      position: json['position'] as int,
      points: (json['points'] as num).toDouble(),
      isCounted: json['isCounted'] as bool? ?? true,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'competitionId': competitionId,
      'competitionName': competitionName,
      'competitionDate': competitionDate.toIso8601String(),
      'position': position,
      'points': points,
      'isCounted': isCounted,
      'notes': notes,
    };
  }

  @override
  List<Object?> get props => [
        competitionId,
        position,
        points,
        isCounted,
      ];
}
