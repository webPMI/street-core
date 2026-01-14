// lib/features/competitions/models/offline_score.dart

import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';

part 'offline_score.g.dart';

/// Offline score model for storing judge scores locally
/// when there's no internet connection
@HiveType(typeId: 1)
class OfflineScore extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String competitionId;

  @HiveField(2)
  final String categoryId;

  @HiveField(3)
  final String participantId;

  @HiveField(4)
  final String judgeId;

  @HiveField(5)
  final Map<String, double> criteriaScores;

  @HiveField(6)
  final String? comments;

  @HiveField(7)
  final DateTime createdAt;

  @HiveField(8)
  final int syncAttempts;

  @HiveField(9)
  final String? lastSyncError;

  @HiveField(10)
  final bool isUpdate;

  @HiveField(11)
  final String? existingScoreId;

  const OfflineScore({
    required this.id,
    required this.competitionId,
    required this.categoryId,
    required this.participantId,
    required this.judgeId,
    required this.criteriaScores,
    this.comments,
    required this.createdAt,
    this.syncAttempts = 0,
    this.lastSyncError,
    this.isUpdate = false,
    this.existingScoreId,
  });

  /// Create from score submission data
  factory OfflineScore.fromSubmission({
    required String competitionId,
    required String categoryId,
    required String participantId,
    required String judgeId,
    required Map<String, double> criteriaScores,
    String? comments,
    bool isUpdate = false,
    String? existingScoreId,
  }) {
    return OfflineScore(
      id: '${DateTime.now().millisecondsSinceEpoch}_$participantId',
      competitionId: competitionId,
      categoryId: categoryId,
      participantId: participantId,
      judgeId: judgeId,
      criteriaScores: criteriaScores,
      comments: comments,
      createdAt: DateTime.now(),
      isUpdate: isUpdate,
      existingScoreId: existingScoreId,
    );
  }

  /// Convert to JSON for API submission
  Map<String, dynamic> toApiJson() {
    return {
      'participantId': participantId,
      'criteriaScores': criteriaScores,
      if (comments != null && comments!.isNotEmpty) 'comments': comments,
    };
  }

  /// Copy with updated fields
  OfflineScore copyWith({
    int? syncAttempts,
    String? lastSyncError,
  }) {
    return OfflineScore(
      id: id,
      competitionId: competitionId,
      categoryId: categoryId,
      participantId: participantId,
      judgeId: judgeId,
      criteriaScores: criteriaScores,
      comments: comments,
      createdAt: createdAt,
      syncAttempts: syncAttempts ?? this.syncAttempts,
      lastSyncError: lastSyncError,
      isUpdate: isUpdate,
      existingScoreId: existingScoreId,
    );
  }

  /// Check if max sync attempts reached
  bool get maxSyncAttemptsReached => syncAttempts >= 5;

  /// Get total score
  double get totalScore {
    return criteriaScores.values.fold(0.0, (sum, score) => sum + score);
  }

  @override
  List<Object?> get props => [
        id,
        competitionId,
        categoryId,
        participantId,
        judgeId,
        criteriaScores,
        comments,
        createdAt,
        syncAttempts,
        isUpdate,
        existingScoreId,
      ];
}
