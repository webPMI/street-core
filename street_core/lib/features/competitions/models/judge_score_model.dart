import 'package:equatable/equatable.dart';

/// Judge Score Model
/// Represents scores given by a judge to a participant in a category
class JudgeScore extends Equatable {

  const JudgeScore({
    required this.id,
    required this.competitionId,
    required this.categoryId,
    required this.participantId,
    required this.participantName,
    this.participantNumber,
    required this.judgeId,
    required this.judgeName,
    this.criteriaScores = const {},
    this.totalScore = 0.0,
    this.comments,
    this.isSubmitted = false,
    this.submittedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory JudgeScore.fromJson(Map<String, dynamic> json) {
    return JudgeScore(
      id: json['id'] as String,
      competitionId: json['competitionId'] as String,
      categoryId: json['categoryId'] as String,
      participantId: json['participantId'] as String,
      participantName: json['participantName'] as String? ?? '',
      participantNumber: json['participantNumber'] as String?,
      judgeId: json['judgeId'] as String,
      judgeName: json['judgeName'] as String? ?? '',
      criteriaScores: (json['criteriaScores'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, (v as num).toDouble())) ??
          {},
      totalScore: json['totalScore'] != null
          ? (json['totalScore'] as num).toDouble()
          : 0.0,
      comments: json['comments'] as String?,
      isSubmitted: json['isSubmitted'] as bool? ?? false,
      submittedAt: json['submittedAt'] != null
          ? DateTime.parse(json['submittedAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
  final String id;
  final String competitionId;
  final String categoryId;
  final String participantId;
  final String participantName;
  final String? participantNumber;
  final String judgeId;
  final String judgeName;
  final Map<String, double> criteriaScores; // criterionName -> score
  final double totalScore;
  final String? comments;
  final bool isSubmitted;
  final DateTime? submittedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Helper getters
  bool get hasScores => criteriaScores.isNotEmpty;
  int get criteriaCount => criteriaScores.length;

  double get averageScore {
    if (criteriaScores.isEmpty) return 0;
    final sum = criteriaScores.values.fold(0.0, (a, b) => a + b);
    return sum / criteriaScores.length;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'competitionId': competitionId,
      'categoryId': categoryId,
      'participantId': participantId,
      'participantName': participantName,
      if (participantNumber != null) 'participantNumber': participantNumber,
      'judgeId': judgeId,
      'judgeName': judgeName,
      'criteriaScores': criteriaScores,
      'totalScore': totalScore,
      if (comments != null) 'comments': comments,
      'isSubmitted': isSubmitted,
      if (submittedAt != null) 'submittedAt': submittedAt!.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  JudgeScore copyWith({
    String? id,
    String? competitionId,
    String? categoryId,
    String? participantId,
    String? participantName,
    String? participantNumber,
    String? judgeId,
    String? judgeName,
    Map<String, double>? criteriaScores,
    double? totalScore,
    String? comments,
    bool? isSubmitted,
    DateTime? submittedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return JudgeScore(
      id: id ?? this.id,
      competitionId: competitionId ?? this.competitionId,
      categoryId: categoryId ?? this.categoryId,
      participantId: participantId ?? this.participantId,
      participantName: participantName ?? this.participantName,
      participantNumber: participantNumber ?? this.participantNumber,
      judgeId: judgeId ?? this.judgeId,
      judgeName: judgeName ?? this.judgeName,
      criteriaScores: criteriaScores ?? this.criteriaScores,
      totalScore: totalScore ?? this.totalScore,
      comments: comments ?? this.comments,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      submittedAt: submittedAt ?? this.submittedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        competitionId,
        categoryId,
        participantId,
        judgeId,
        totalScore,
        isSubmitted,
      ];
}

/// Category Ranking Entry Model
/// Represents a participant's ranking in a category based on judge scores
class CategoryRankingEntry extends Equatable {

  const CategoryRankingEntry({
    required this.position,
    required this.participantId,
    required this.participantName,
    this.participantNumber,
    this.participantAvatar,
    required this.averageScore,
    this.criteriaAverages = const {},
    this.scores = const [],
    required this.totalJudges,
  });

  factory CategoryRankingEntry.fromJson(Map<String, dynamic> json) {
    return CategoryRankingEntry(
      position: json['position'] as int,
      participantId: json['participantId'] as String,
      participantName: json['participantName'] as String,
      participantNumber: json['participantNumber'] as String?,
      participantAvatar: json['participantAvatar'] as String?,
      averageScore: (json['averageScore'] as num).toDouble(),
      criteriaAverages: (json['criteriaAverages'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, (v as num).toDouble())) ??
          {},
      scores: (json['scores'] as List<dynamic>?)
              ?.map((e) => JudgeScore.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalJudges: json['totalJudges'] as int? ?? 0,
    );
  }
  final int position;
  final String participantId;
  final String participantName;
  final String? participantNumber;
  final String? participantAvatar;
  final double averageScore;
  final Map<String, double> criteriaAverages; // criterionName -> average
  final List<JudgeScore> scores; // Individual judge scores
  final int totalJudges;

  // Helper getters
  bool get hasAllScores => scores.length == totalJudges;
  int get scoresSubmitted => scores.where((s) => s.isSubmitted).length;
  bool get isComplete => scoresSubmitted == totalJudges;

  String get medalIcon {
    switch (position) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'position': position,
      'participantId': participantId,
      'participantName': participantName,
      if (participantNumber != null) 'participantNumber': participantNumber,
      if (participantAvatar != null) 'participantAvatar': participantAvatar,
      'averageScore': averageScore,
      'criteriaAverages': criteriaAverages,
      'scores': scores.map((e) => e.toJson()).toList(),
      'totalJudges': totalJudges,
    };
  }

  @override
  List<Object?> get props => [
        position,
        participantId,
        averageScore,
        totalJudges,
      ];
}
