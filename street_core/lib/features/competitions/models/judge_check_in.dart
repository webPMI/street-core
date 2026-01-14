import 'package:equatable/equatable.dart';

/// Judge check-in status constants
class CheckInStatus {
  static const String pending = 'pending';
  static const String checkedIn = 'checked_in';
  static const String noShow = 'no_show';
}

/// JudgeCheckIn model representing a judge's check-in for a competition
class JudgeCheckIn extends Equatable {
  const JudgeCheckIn({
    required this.id,
    required this.competitionId,
    required this.judgeId,
    required this.judgeName,
    required this.status,
    required this.windowStartsAt,
    this.checkInAt,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String competitionId;
  final String judgeId;
  final String judgeName;
  final String status;
  final DateTime windowStartsAt;
  final DateTime? checkInAt;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isCheckedIn => status == CheckInStatus.checkedIn;
  bool get isPending => status == CheckInStatus.pending;
  bool get isNoShow => status == CheckInStatus.noShow;
  bool get isWindowOpen => DateTime.now().isAfter(windowStartsAt) || DateTime.now().isAtSameMomentAs(windowStartsAt);

  factory JudgeCheckIn.fromJson(Map<String, dynamic> json) {
    return JudgeCheckIn(
      id: json['id'] as String,
      competitionId: json['competitionId'] as String,
      judgeId: json['judgeId'] as String,
      judgeName: json['judgeName'] as String,
      status: json['status'] as String,
      windowStartsAt: DateTime.parse(json['windowStartsAt'] as String),
      checkInAt: json['checkInAt'] != null ? DateTime.parse(json['checkInAt'] as String) : null,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'competitionId': competitionId,
      'judgeId': judgeId,
      'judgeName': judgeName,
      'status': status,
      'windowStartsAt': windowStartsAt.toIso8601String(),
      'checkInAt': checkInAt?.toIso8601String(),
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  JudgeCheckIn copyWith({
    String? id,
    String? competitionId,
    String? judgeId,
    String? judgeName,
    String? status,
    DateTime? windowStartsAt,
    DateTime? checkInAt,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return JudgeCheckIn(
      id: id ?? this.id,
      competitionId: competitionId ?? this.competitionId,
      judgeId: judgeId ?? this.judgeId,
      judgeName: judgeName ?? this.judgeName,
      status: status ?? this.status,
      windowStartsAt: windowStartsAt ?? this.windowStartsAt,
      checkInAt: checkInAt ?? this.checkInAt,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        competitionId,
        judgeId,
        judgeName,
        status,
        windowStartsAt,
        checkInAt,
        notes,
        createdAt,
        updatedAt,
      ];
}

/// StartValidationResult model representing the validation state for starting a competition
class StartValidationResult extends Equatable {
  const StartValidationResult({
    required this.canStart,
    required this.errors,
    required this.warnings,
    required this.hasCategories,
    required this.categoriesCount,
    required this.categoriesWithCriteria,
    required this.minParticipants,
    required this.currentParticipants,
    required this.requiredJudges,
    required this.currentJudges,
    required this.status,
  });

  final bool canStart;
  final List<String> errors;
  final List<String> warnings;
  final bool hasCategories;
  final int categoriesCount;
  final int categoriesWithCriteria;
  final int minParticipants;
  final int currentParticipants;
  final int requiredJudges;
  final int currentJudges;
  final String status;

  factory StartValidationResult.fromJson(Map<String, dynamic> json) {
    return StartValidationResult(
      canStart: json['canStart'] as bool,
      errors: (json['errors'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      warnings: (json['warnings'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      hasCategories: json['hasCategories'] as bool,
      categoriesCount: json['categoriesCount'] as int,
      categoriesWithCriteria: json['categoriesWithCriteria'] as int,
      minParticipants: json['minParticipants'] as int,
      currentParticipants: json['currentParticipants'] as int,
      requiredJudges: json['requiredJudges'] as int,
      currentJudges: json['currentJudges'] as int,
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'canStart': canStart,
      'errors': errors,
      'warnings': warnings,
      'hasCategories': hasCategories,
      'categoriesCount': categoriesCount,
      'categoriesWithCriteria': categoriesWithCriteria,
      'minParticipants': minParticipants,
      'currentParticipants': currentParticipants,
      'requiredJudges': requiredJudges,
      'currentJudges': currentJudges,
      'status': status,
    };
  }

  @override
  List<Object?> get props => [
        canStart,
        errors,
        warnings,
        hasCategories,
        categoriesCount,
        categoriesWithCriteria,
        minParticipants,
        currentParticipants,
        requiredJudges,
        currentJudges,
        status,
      ];
}
