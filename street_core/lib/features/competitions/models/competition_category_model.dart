import 'package:equatable/equatable.dart';

/// Competition Category Model
/// Represents a category within a competition for organizing participants by skill level, age groups, etc.
class CompetitionCategory extends Equatable {

  const CompetitionCategory({
    required this.id,
    required this.competitionId,
    required this.name,
    required this.description,
    required this.maxJudges,
    this.minAge,
    this.maxAge,
    required this.skillLevel,
    this.participants = const [],
    this.judges = const [],
    this.order = 0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CompetitionCategory.fromJson(Map<String, dynamic> json) {
    return CompetitionCategory(
      id: json['id'] as String,
      competitionId: json['competitionId'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      maxJudges: json['maxJudges'] as int? ?? 3,
      minAge: json['minAge'] as int?,
      maxAge: json['maxAge'] as int?,
      skillLevel: json['skillLevel'] as String,
      participants:
          (json['participants'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      judges:
          (json['judges'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      order: json['order'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
  final String id;
  final String competitionId;
  final String name;
  final String description;
  final int maxJudges;
  final int? minAge;
  final int? maxAge;
  final String skillLevel; // beginner, intermediate, advanced, pro
  final List<String> participants;
  final List<String> judges;
  final int order;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Helper getters
  bool get isFull => judges.length >= maxJudges;
  bool get hasJudges => judges.isNotEmpty;
  int get availableJudgeSlots => maxJudges - judges.length;
  int get participantCount => participants.length;
  int get judgeCount => judges.length;

  String get ageRangeDisplay {
    if (minAge != null && maxAge != null) {
      return '$minAge-$maxAge años';
    } else if (minAge != null) {
      return '$minAge+ años';
    } else if (maxAge != null) {
      return 'Hasta $maxAge años';
    }
    return 'Todas las edades';
  }

  String get skillLevelDisplay {
    switch (skillLevel) {
      case 'beginner':
        return 'Principiante';
      case 'intermediate':
        return 'Intermedio';
      case 'advanced':
        return 'Avanzado';
      case 'pro':
        return 'Profesional';
      default:
        return skillLevel;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'competitionId': competitionId,
      'name': name,
      'description': description,
      'maxJudges': maxJudges,
      if (minAge != null) 'minAge': minAge,
      if (maxAge != null) 'maxAge': maxAge,
      'skillLevel': skillLevel,
      'participants': participants,
      'judges': judges,
      'order': order,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  CompetitionCategory copyWith({
    String? id,
    String? competitionId,
    String? name,
    String? description,
    int? maxJudges,
    int? minAge,
    int? maxAge,
    String? skillLevel,
    List<String>? participants,
    List<String>? judges,
    int? order,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CompetitionCategory(
      id: id ?? this.id,
      competitionId: competitionId ?? this.competitionId,
      name: name ?? this.name,
      description: description ?? this.description,
      maxJudges: maxJudges ?? this.maxJudges,
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
      skillLevel: skillLevel ?? this.skillLevel,
      participants: participants ?? this.participants,
      judges: judges ?? this.judges,
      order: order ?? this.order,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    competitionId,
    name,
    skillLevel,
    maxJudges,
    participants,
    judges,
    order,
    isActive,
  ];
}

/// Skill Level Constants
class SkillLevel {
  static const String beginner = 'beginner';
  static const String intermediate = 'intermediate';
  static const String advanced = 'advanced';
  static const String pro = 'pro';

  static List<String> get all => [beginner, intermediate, advanced, pro];

  static String getDisplayName(String level) {
    switch (level) {
      case beginner:
        return 'Principiante';
      case intermediate:
        return 'Intermedio';
      case advanced:
        return 'Avanzado';
      case pro:
        return 'Profesional';
      default:
        return level;
    }
  }
}
