/// Competition Model - Main competition entity.
/// Following Monolith-by-Features architecture (ADR-005).

import 'package:equatable/equatable.dart';

import '../../../core/services/api_address.dart';
import 'leaderboard.dart';
import 'podium_result.dart';
import 'prize_pool.dart';
import 'round.dart';
import 'scoring_criteria.dart';

// Re-export split models for backward compatibility
export 'leaderboard.dart';
export 'podium_result.dart';
export 'prize_pool.dart';
export 'rider_score.dart';
export 'round.dart';
export 'scoring_criteria.dart';

// =============================================================================
// COMPETITION ENTITY
// =============================================================================

/// Competition Model - Extended Event for competitive sports
class Competition extends Equatable {
  const Competition({
    required this.id,
    required this.eventId,
    required this.title,
    required this.description,
    required this.organizerId,
    required this.organizerName,
    this.clubId,
    this.clubName,
    this.competitionType,
    this.format,
    this.category,
    this.discipline,
    required this.startDate,
    required this.endDate,
    this.venue,
    this.city,
    this.country,
    this.latitude,
    this.longitude,
    this.maxParticipants = 100,
    this.minParticipants = 2,
    this.currentParticipants = 0,
    this.registrationDeadline,
    this.requiresApproval = false,
    this.entryFee,
    this.currency,
    this.registeredAthleteIds = const [],
    this.waitlistAthleteIds = const [],
    this.participantStatus,
    this.registrationType,
    this.externalRegistrationUrl,
    this.externalProvider,
    this.judgeIds = const [],
    this.headJudgeIds = const [],
    this.requiredJudges = 3,
    required this.scoringCriteria,
    this.dropHighestScore = false,
    this.dropLowestScore = false,
    this.totalRounds = 1,
    this.currentRound = 0,
    this.rounds = const [],
    this.hasQualifying = false,
    this.hasSemiFinals = false,
    this.hasFinals = true,
    this.status = 'upcoming',
    this.isLive = false,
    this.allowLiveScoring = true,
    this.showLiveResults = true,
    this.liveStreamUrl,
    this.leaderboard,
    this.podium,
    this.isResultsPublished = false,
    this.resultsPublishedAt,
    this.prizePool,
    this.sponsors,
    this.hasPointsForRanking = true,
    this.rules,
    this.requirements,
    this.requiredDocuments,
    this.equipmentRules,
    this.bannerUrl,
    this.imageUrls,
    this.videoUrl,
    this.highlightUrls,
    this.customFields,
    this.tags,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Competition.fromJson(Map<String, dynamic> json) {
    return Competition(
      id: json['id'] as String,
      eventId: json['eventId'] as String? ?? json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      organizerId: json['organizerId'] as String,
      organizerName: json['organizerName'] as String? ?? '',
      clubId: json['clubId'] as String?,
      clubName: json['clubName'] as String?,
      competitionType: json['competitionType'] as String?,
      format: json['format'] as String?,
      category: json['category'] as String?,
      discipline: json['discipline'] as String?,
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'] as String)
          : (json['schedule'] != null
              ? DateTime.parse(json['schedule']['startDate'] as String)
              : DateTime.now()),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : (json['schedule'] != null
              ? DateTime.parse(json['schedule']['endDate'] as String)
              : DateTime.now()),
      venue: json['venue'] as String? ?? json['schedule']?['venue'] as String?,
      city: json['city'] as String? ?? json['schedule']?['city'] as String?,
      country:
          json['country'] as String? ?? json['schedule']?['country'] as String?,
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : json['schedule']?['latitude'] != null
              ? (json['schedule']['latitude'] as num).toDouble()
              : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : json['schedule']?['longitude'] != null
              ? (json['schedule']['longitude'] as num).toDouble()
              : null,
      maxParticipants: json['maxParticipants'] as int? ??
          json['registration']?['maxParticipants'] as int? ??
          100,
      minParticipants: json['minParticipants'] as int? ??
          json['registration']?['minParticipants'] as int? ??
          2,
      currentParticipants: json['currentParticipants'] as int? ??
          json['registration']?['currentParticipants'] as int? ??
          0,
      registrationDeadline: json['registrationDeadline'] != null
          ? DateTime.parse(json['registrationDeadline'] as String)
          : json['registration']?['registrationDeadline'] != null
              ? DateTime.parse(
                  json['registration']['registrationDeadline'] as String)
              : null,
      requiresApproval: json['requiresApproval'] as bool? ??
          json['registration']?['requiresApproval'] as bool? ??
          false,
      entryFee: json['entryFee'] != null
          ? (json['entryFee'] as num).toDouble()
          : json['registration']?['entryFee'] != null
              ? (json['registration']['entryFee'] as num).toDouble()
              : null,
      currency: json['currency'] as String? ??
          json['registration']?['currency'] as String?,
      registeredAthleteIds: (json['registeredAthleteIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          (json['registration']?['registeredAthleteIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      waitlistAthleteIds: (json['waitlistAthleteIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          (json['registration']?['waitlistAthleteIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      participantStatus: json['participantStatus'] as String? ??
          json['registration']?['participantStatus'] as String?,
      registrationType: json['registrationType'] as String? ??
          json['registration']?['registrationType'] as String?,
      externalRegistrationUrl: json['externalRegistrationUrl'] as String? ??
          json['registration']?['externalRegistrationUrl'] as String?,
      externalProvider: json['externalProvider'] as String? ??
          json['registration']?['externalProvider'] as String?,
      judgeIds: (json['judgeIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      headJudgeIds: (json['headJudgeIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      requiredJudges: json['requiredJudges'] as int? ?? 3,
      scoringCriteria: json['scoringCriteria'] != null
          ? ScoringCriteria.fromJson(
              json['scoringCriteria'] as Map<String, dynamic>)
          : const ScoringCriteria(type: 'points'),
      dropHighestScore: json['dropHighestScore'] as bool? ?? false,
      dropLowestScore: json['dropLowestScore'] as bool? ?? false,
      totalRounds: json['totalRounds'] as int? ?? 1,
      currentRound: json['currentRound'] as int? ?? 0,
      rounds: (json['rounds'] as List<dynamic>?)
              ?.map((e) => Round.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      hasQualifying: json['hasQualifying'] as bool? ?? false,
      hasSemiFinals: json['hasSemiFinals'] as bool? ?? false,
      hasFinals: json['hasFinals'] as bool? ?? true,
      status: json['status'] as String? ?? 'upcoming',
      isLive: json['isLive'] as bool? ?? false,
      allowLiveScoring: json['allowLiveScoring'] as bool? ?? true,
      showLiveResults: json['showLiveResults'] as bool? ?? true,
      liveStreamUrl: json['liveStreamUrl'] as String?,
      leaderboard: json['leaderboard'] != null
          ? Leaderboard.fromJson(json['leaderboard'] as Map<String, dynamic>)
          : null,
      podium: (json['podium'] as List<dynamic>?)
          ?.map((e) => PodiumResult.fromJson(e as Map<String, dynamic>))
          .toList(),
      isResultsPublished: json['isResultsPublished'] as bool? ?? false,
      resultsPublishedAt: json['resultsPublishedAt'] != null
          ? DateTime.parse(json['resultsPublishedAt'] as String)
          : null,
      prizePool: json['prizePool'] != null
          ? PrizePool.fromJson(json['prizePool'] as Map<String, dynamic>)
          : null,
      sponsors: (json['sponsors'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      hasPointsForRanking: json['hasPointsForRanking'] as bool? ?? true,
      rules: json['rules'] as String?,
      requirements: json['requirements'] as String?,
      requiredDocuments: (json['requiredDocuments'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      equipmentRules: json['equipmentRules'] as String?,
      bannerUrl: mediaUrlOrNull(json['bannerUrl']),
      imageUrls: parseMediaUrls(json['imageUrls']),
      videoUrl: mediaUrlOrNull(json['videoUrl']),
      highlightUrls: parseMediaUrls(json['highlightUrls']),
      customFields: json['customFields'] as Map<String, dynamic>?,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
      notes: json['notes'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  // Basic Info
  final String id;
  final String eventId;
  final String title;
  final String description;
  final String organizerId;
  final String organizerName;
  final String? clubId;
  final String? clubName;

  // Competition Type & Format
  final String? competitionType;
  final String? format;
  final String? category;
  final String? discipline;

  // Schedule & Location
  final DateTime startDate;
  final DateTime endDate;
  final String? venue;
  final String? city;
  final String? country;
  final double? latitude;
  final double? longitude;

  // Registration
  final int maxParticipants;
  final int minParticipants;
  final int currentParticipants;
  final DateTime? registrationDeadline;
  final bool requiresApproval;
  final double? entryFee;
  final String? currency;

  // Participants
  final List<String> registeredAthleteIds;
  final List<String> waitlistAthleteIds;
  final String? participantStatus;

  // External Registration
  final String? registrationType; // "internal" | "external" | null
  final String? externalRegistrationUrl;
  final String? externalProvider; // e.g., "Eventbrite", "Ticketmaster"

  // Judging
  final List<String> judgeIds;
  final List<String> headJudgeIds;
  final int requiredJudges;
  final ScoringCriteria scoringCriteria;
  final bool dropHighestScore;
  final bool dropLowestScore;

  // Rounds & Heats
  final int totalRounds;
  final int currentRound;
  final List<Round> rounds;
  final bool hasQualifying;
  final bool hasSemiFinals;
  final bool hasFinals;

  // Status & Live
  final String status;
  final bool isLive;
  final bool allowLiveScoring;
  final bool showLiveResults;
  final String? liveStreamUrl;

  // Results & Rankings
  final Leaderboard? leaderboard;
  final List<PodiumResult>? podium;
  final bool isResultsPublished;
  final DateTime? resultsPublishedAt;

  // Prizes & Rewards
  final PrizePool? prizePool;
  final List<String>? sponsors;
  final bool hasPointsForRanking;

  // Rules & Requirements
  final String? rules;
  final String? requirements;
  final List<String>? requiredDocuments;
  final String? equipmentRules;

  // Media
  final String? bannerUrl;
  final List<String>? imageUrls;
  final String? videoUrl;
  final List<String>? highlightUrls;

  // Additional
  final Map<String, dynamic>? customFields;
  final List<String>? tags;
  final String? notes;

  // Metadata
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'title': title,
      'description': description,
      'organizerId': organizerId,
      'organizerName': organizerName,
      'clubId': clubId,
      'clubName': clubName,
      'competitionType': competitionType,
      'format': format,
      'category': category,
      'discipline': discipline,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'venue': venue,
      'city': city,
      'country': country,
      'latitude': latitude,
      'longitude': longitude,
      'maxParticipants': maxParticipants,
      'minParticipants': minParticipants,
      'currentParticipants': currentParticipants,
      'registrationDeadline': registrationDeadline?.toIso8601String(),
      'requiresApproval': requiresApproval,
      'entryFee': entryFee,
      'currency': currency,
      'registeredAthleteIds': registeredAthleteIds,
      'waitlistAthleteIds': waitlistAthleteIds,
      'participantStatus': participantStatus,
      'registrationType': registrationType,
      'externalRegistrationUrl': externalRegistrationUrl,
      'externalProvider': externalProvider,
      'judgeIds': judgeIds,
      'headJudgeIds': headJudgeIds,
      'requiredJudges': requiredJudges,
      'scoringCriteria': scoringCriteria.toJson(),
      'dropHighestScore': dropHighestScore,
      'dropLowestScore': dropLowestScore,
      'totalRounds': totalRounds,
      'currentRound': currentRound,
      'rounds': rounds.map((e) => e.toJson()).toList(),
      'hasQualifying': hasQualifying,
      'hasSemiFinals': hasSemiFinals,
      'hasFinals': hasFinals,
      'status': status,
      'isLive': isLive,
      'allowLiveScoring': allowLiveScoring,
      'showLiveResults': showLiveResults,
      'liveStreamUrl': liveStreamUrl,
      'leaderboard': leaderboard?.toJson(),
      'podium': podium?.map((e) => e.toJson()).toList(),
      'isResultsPublished': isResultsPublished,
      'resultsPublishedAt': resultsPublishedAt?.toIso8601String(),
      'prizePool': prizePool?.toJson(),
      'sponsors': sponsors,
      'hasPointsForRanking': hasPointsForRanking,
      'rules': rules,
      'requirements': requirements,
      'requiredDocuments': requiredDocuments,
      'equipmentRules': equipmentRules,
      'bannerUrl': bannerUrl,
      'imageUrls': imageUrls,
      'videoUrl': videoUrl,
      'highlightUrls': highlightUrls,
      'customFields': customFields,
      'tags': tags,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // ===========================================================================
  // BUSINESS LOGIC HELPERS (Pure logic, no API calls)
  // ===========================================================================

  /// Check if a user can register for this competition
  bool canRegisterUser(String userId) {
    // Check if registration is open
    if (participantStatus != 'open') return false;

    // Check if deadline passed
    if (registrationDeadline != null &&
        DateTime.now().isAfter(registrationDeadline!)) {
      return false;
    }

    // Check if max participants reached
    if (currentParticipants >= maxParticipants) return false;

    // Check if status is upcoming
    if (status != 'upcoming') return false;

    // Check if already registered
    if (registeredAthleteIds.contains(userId)) return false;

    return true;
  }

  /// Check if a user is registered for this competition
  bool isRegisteredBy(String userId) => registeredAthleteIds.contains(userId);

  /// Check if a user is a judge for this competition
  bool isJudgedBy(String userId) => judgeIds.contains(userId);

  /// Check if a user is a head judge for this competition
  bool isHeadJudge(String userId) => headJudgeIds.contains(userId);

  /// Check if a user is the organizer of this competition
  bool isOrganizedBy(String userId) => organizerId == userId;

  /// Check if a user can manage this competition (is organizer)
  bool canBeManagedBy(String userId) => organizerId == userId;

  /// Check if registration is still open
  bool get isRegistrationOpen {
    if (participantStatus != 'open') return false;
    if (registrationDeadline != null &&
        DateTime.now().isAfter(registrationDeadline!)) {
      return false;
    }
    return status == 'upcoming';
  }

  /// Check if competition has available spots
  bool get hasAvailableSpots => currentParticipants < maxParticipants;

  /// Get remaining spots count
  int get remainingSpots => maxParticipants - currentParticipants;

  /// Check if competition is in the past
  bool get isPast => endDate.isBefore(DateTime.now());

  /// Check if competition is upcoming
  bool get isUpcoming => status == 'upcoming' && startDate.isAfter(DateTime.now());

  /// Check if competition is currently running
  bool get isRunning => status == 'live' || isLive;

  /// Check if competition is completed
  bool get isCompleted => status == 'completed';

  /// Get scoring type from scoring criteria
  String get scoringType => scoringCriteria.type;

  /// Get max score from scoring criteria
  double get maxScore => scoringCriteria.maxScore;

  /// Check if competition uses external registration
  bool get isExternalRegistration => registrationType == 'external';

  /// Check if competition uses internal registration
  bool get isInternalRegistration => registrationType == 'internal' || registrationType == null;

  /// Get the external registration URL if available
  String? getExternalRegistrationUrl() {
    if (isExternalRegistration && externalRegistrationUrl != null) {
      return externalRegistrationUrl;
    }
    return null;
  }

  @override
  List<Object?> get props => [
        id,
        eventId,
        title,
        competitionType,
        format,
        discipline,
        status,
        isLive,
        currentParticipants,
        bannerUrl, // Include media to detect changes
        imageUrls,
        updatedAt, // Include to detect any updates
        createdAt,
      ];
}
