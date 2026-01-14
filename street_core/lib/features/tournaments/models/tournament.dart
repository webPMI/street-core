import 'package:equatable/equatable.dart';

/// Tournament model representing a competition series
class Tournament extends Equatable {
  final String id;
  final String title;
  final String description;
  final String organizerId;
  final String organizerName;
  final String sportType;
  final String discipline;
  final String format;
  final String? category;

  // Schedule
  final TournamentSchedule schedule;

  // Registration
  final TournamentRegistration registration;

  // Scoring
  final String scoringSystem;
  final TournamentScoringConfig scoringConfig;

  // Competitions
  final List<String> competitionIds;
  final int totalCompetitions;

  // Athletes
  final List<String> registeredAthleteIds;
  final int totalAthletes;

  // Status
  final String status;
  final bool isLive;

  // Media
  final List<String> prizes;
  final String? rules;
  final String? bannerUrl;
  final String? posterUrl;
  final List<String> tags;

  // Visibility
  final bool isPublic;
  final bool isFeatured;

  // Metadata
  final DateTime createdAt;
  final DateTime updatedAt;

  const Tournament({
    required this.id,
    required this.title,
    required this.description,
    required this.organizerId,
    required this.organizerName,
    required this.sportType,
    required this.discipline,
    required this.format,
    this.category,
    required this.schedule,
    required this.registration,
    required this.scoringSystem,
    required this.scoringConfig,
    required this.competitionIds,
    required this.totalCompetitions,
    required this.registeredAthleteIds,
    required this.totalAthletes,
    required this.status,
    required this.isLive,
    required this.prizes,
    this.rules,
    this.bannerUrl,
    this.posterUrl,
    required this.tags,
    required this.isPublic,
    required this.isFeatured,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Tournament.fromJson(Map<String, dynamic> json) {
    return Tournament(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      organizerId: json['organizerId'] as String,
      organizerName: json['organizerName'] as String? ?? '',
      sportType: json['sportType'] as String,
      discipline: json['discipline'] as String,
      format: json['format'] as String,
      category: json['category'] as String?,
      schedule: TournamentSchedule.fromJson(json['schedule'] as Map<String, dynamic>),
      registration: TournamentRegistration.fromJson(json['registration'] as Map<String, dynamic>),
      scoringSystem: json['scoringSystem'] as String,
      scoringConfig: TournamentScoringConfig.fromJson(json['scoringConfig'] as Map<String, dynamic>),
      competitionIds: (json['competitionIds'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      totalCompetitions: json['totalCompetitions'] as int? ?? 0,
      registeredAthleteIds: (json['registeredAthleteIds'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      totalAthletes: json['totalAthletes'] as int? ?? 0,
      status: json['status'] as String,
      isLive: json['isLive'] as bool? ?? false,
      prizes: (json['prizes'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      rules: json['rules'] as String?,
      bannerUrl: json['bannerUrl'] as String?,
      posterUrl: json['posterUrl'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      isPublic: json['isPublic'] as bool? ?? true,
      isFeatured: json['isFeatured'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'organizerId': organizerId,
      'organizerName': organizerName,
      'sportType': sportType,
      'discipline': discipline,
      'format': format,
      'category': category,
      'schedule': schedule.toJson(),
      'registration': registration.toJson(),
      'scoringSystem': scoringSystem,
      'scoringConfig': scoringConfig.toJson(),
      'competitionIds': competitionIds,
      'totalCompetitions': totalCompetitions,
      'registeredAthleteIds': registeredAthleteIds,
      'totalAthletes': totalAthletes,
      'status': status,
      'isLive': isLive,
      'prizes': prizes,
      'rules': rules,
      'bannerUrl': bannerUrl,
      'posterUrl': posterUrl,
      'tags': tags,
      'isPublic': isPublic,
      'isFeatured': isFeatured,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        organizerId,
        sportType,
        discipline,
        format,
        status,
        updatedAt,
      ];
}

/// Tournament Schedule
class TournamentSchedule extends Equatable {
  final DateTime startDate;
  final DateTime endDate;
  final String? season;
  final int? year;
  final String? timeZone;
  final String? venue;
  final String? city;
  final String? country;

  const TournamentSchedule({
    required this.startDate,
    required this.endDate,
    this.season,
    this.year,
    this.timeZone,
    this.venue,
    this.city,
    this.country,
  });

  factory TournamentSchedule.fromJson(Map<String, dynamic> json) {
    return TournamentSchedule(
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      season: json['season'] as String?,
      year: json['year'] as int?,
      timeZone: json['timeZone'] as String?,
      venue: json['venue'] as String?,
      city: json['city'] as String?,
      country: json['country'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'season': season,
      'year': year,
      'timeZone': timeZone,
      'venue': venue,
      'city': city,
      'country': country,
    };
  }

  @override
  List<Object?> get props => [startDate, endDate, season, year, venue, city, country];
}

/// Tournament Registration Configuration
class TournamentRegistration extends Equatable {
  final int? maxParticipants;
  final DateTime? registrationDeadline;
  final String registrationStatus;
  final bool allowLateRegistration;
  final bool requiresApproval;
  final double? entryFee;
  final String? currency;
  final bool allowIndividualRaceEntry;

  const TournamentRegistration({
    this.maxParticipants,
    this.registrationDeadline,
    required this.registrationStatus,
    required this.allowLateRegistration,
    required this.requiresApproval,
    this.entryFee,
    this.currency,
    required this.allowIndividualRaceEntry,
  });

  factory TournamentRegistration.fromJson(Map<String, dynamic> json) {
    return TournamentRegistration(
      maxParticipants: json['maxParticipants'] as int?,
      registrationDeadline: json['registrationDeadline'] != null
          ? DateTime.parse(json['registrationDeadline'] as String)
          : null,
      registrationStatus: json['registrationStatus'] as String? ?? 'open',
      allowLateRegistration: json['allowLateRegistration'] as bool? ?? false,
      requiresApproval: json['requiresApproval'] as bool? ?? false,
      entryFee: (json['entryFee'] as num?)?.toDouble(),
      currency: json['currency'] as String?,
      allowIndividualRaceEntry: json['allowIndividualRaceEntry'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maxParticipants': maxParticipants,
      'registrationDeadline': registrationDeadline?.toIso8601String(),
      'registrationStatus': registrationStatus,
      'allowLateRegistration': allowLateRegistration,
      'requiresApproval': requiresApproval,
      'entryFee': entryFee,
      'currency': currency,
      'allowIndividualRaceEntry': allowIndividualRaceEntry,
    };
  }

  @override
  List<Object?> get props => [
        maxParticipants,
        registrationDeadline,
        registrationStatus,
        allowLateRegistration,
        requiresApproval,
        entryFee,
        currency,
        allowIndividualRaceEntry,
      ];
}

/// Tournament Scoring Configuration
class TournamentScoringConfig extends Equatable {
  final Map<String, int>? pointsMap;
  final int? countBestOf;
  final String? customFormula;
  final String? timeAggregation;
  final String? tieBreaker;
  final int? minimumRaces;
  final int? dropWorst;
  final double? multiplier;

  const TournamentScoringConfig({
    this.pointsMap,
    this.countBestOf,
    this.customFormula,
    this.timeAggregation,
    this.tieBreaker,
    this.minimumRaces,
    this.dropWorst,
    this.multiplier,
  });

  factory TournamentScoringConfig.fromJson(Map<String, dynamic> json) {
    return TournamentScoringConfig(
      pointsMap: (json['pointsMap'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, value as int),
      ),
      countBestOf: json['countBestOf'] as int?,
      customFormula: json['customFormula'] as String?,
      timeAggregation: json['timeAggregation'] as String?,
      tieBreaker: json['tieBreaker'] as String?,
      minimumRaces: json['minimumRaces'] as int?,
      dropWorst: json['dropWorst'] as int?,
      multiplier: (json['multiplier'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pointsMap': pointsMap,
      'countBestOf': countBestOf,
      'customFormula': customFormula,
      'timeAggregation': timeAggregation,
      'tieBreaker': tieBreaker,
      'minimumRaces': minimumRaces,
      'dropWorst': dropWorst,
      'multiplier': multiplier,
    };
  }

  @override
  List<Object?> get props => [
        pointsMap,
        countBestOf,
        customFormula,
        timeAggregation,
        tieBreaker,
        minimumRaces,
        dropWorst,
        multiplier,
      ];
}
