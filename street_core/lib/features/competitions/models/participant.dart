/// Modelo de Participante - Representa un atleta/equipo participando en una competición.
/// Following Monolith-by-Features architecture (ADR-005).

import 'package:equatable/equatable.dart';

/// Estados posibles de un participante
class ParticipantStatus {
  static const String pending = 'pending';
  static const String approved = 'approved';
  static const String rejected = 'rejected';
  static const String withdrawn = 'withdrawn';
  static const String checkedIn = 'checked_in';
  // Legacy status
  static const String registered = 'registered';
}

/// Participante en una competición.
class Participant extends Equatable {
  const Participant({
    required this.id,
    required this.competitionId,
    required this.athleteId,
    required this.athleteName,
    this.athleteEmail,
    this.athleteNumber,
    this.clubId,
    this.clubName,
    this.categoryId,
    this.categoryName,
    this.teamId,
    this.teamName,
    this.status = 'pending',
    this.statusMessage,
    this.approvedBy,
    this.approvedAt,
    this.rejectedBy,
    this.rejectedAt,
    this.registrationNumber = 0,
    this.entryFeePaid = false,
    this.paymentReference,
    this.registeredAt,
    this.checkedInAt,
    this.checkedInBy,
    this.notes,
    this.athleteNotes,
    this.createdAt,
    this.updatedAt,
  });

  factory Participant.fromJson(Map<String, dynamic> json) {
    // Handle new backend structure (ParticipantInfo from GetParticipantsUseCase)
    final userId = json['userId'] as String?;
    final userName = json['userName'] as String?;
    final firstName = json['firstName'] as String?;
    final lastName = json['lastName'] as String?;
    final isApproved = json['isApproved'] as bool?;

    // If new structure is detected, map it to the Participant model
    if (userId != null) {
      final fullName = [firstName, lastName]
          .where((n) => n != null && n.isNotEmpty)
          .join(' ');

      return Participant(
        id: json['id'] as String,
        competitionId: json['competitionId'] as String? ?? '',
        athleteId: userId,
        athleteName: fullName.isNotEmpty ? fullName : (userName ?? 'Unknown'),
        athleteEmail: null,
        athleteNumber: null,
        clubId: json['clubId'] as String?,
        clubName: json['clubName'] as String?,
        categoryId: json['categoryId'] as String?,
        categoryName: json['categoryName'] as String?,
        teamId: null,
        teamName: null,
        status: isApproved == true ? 'approved' : 'pending',
        statusMessage: null,
        approvedBy: null,
        approvedAt: null,
        rejectedBy: null,
        rejectedAt: null,
        registrationNumber: 0,
        entryFeePaid: false,
        paymentReference: null,
        registeredAt: null,
        checkedInAt: null,
        checkedInBy: null,
        notes: null,
        athleteNotes: null,
        createdAt: null,
        updatedAt: null,
      );
    }

    // Handle legacy structure (full Participant model)
    return Participant(
      id: json['id'] as String,
      competitionId: json['competitionId'] as String,
      athleteId: json['athleteId'] as String? ?? json['riderId'] as String? ?? '',
      athleteName:
          json['athleteName'] as String? ?? json['riderName'] as String? ?? '',
      athleteEmail: json['athleteEmail'] as String?,
      athleteNumber: json['athleteNumber'] as String?,
      clubId: json['clubId'] as String?,
      clubName: json['clubName'] as String?,
      categoryId: json['categoryId'] as String?,
      categoryName: json['categoryName'] as String?,
      teamId: json['teamId'] as String?,
      teamName: json['teamName'] as String?,
      status: json['status'] as String? ?? 'pending',
      statusMessage: json['statusMessage'] as String?,
      approvedBy: json['approvedBy'] as String?,
      approvedAt: json['approvedAt'] != null
          ? DateTime.parse(json['approvedAt'] as String)
          : null,
      rejectedBy: json['rejectedBy'] as String?,
      rejectedAt: json['rejectedAt'] != null
          ? DateTime.parse(json['rejectedAt'] as String)
          : null,
      registrationNumber: json['registrationNumber'] as int? ?? 0,
      entryFeePaid: json['entryFeePaid'] as bool? ?? false,
      paymentReference: json['paymentReference'] as String?,
      registeredAt: json['registeredAt'] != null
          ? DateTime.parse(json['registeredAt'] as String)
          : json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : null,
      checkedInAt: json['checkedInAt'] != null
          ? DateTime.parse(json['checkedInAt'] as String)
          : null,
      checkedInBy: json['checkedInBy'] as String?,
      notes: json['notes'] as String?,
      athleteNotes: json['athleteNotes'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  factory Participant.empty() {
    return const Participant(
      id: '',
      competitionId: '',
      athleteId: '',
      athleteName: 'Unknown',
    );
  }

  final String id;
  final String competitionId;
  final String athleteId;
  final String athleteName;
  final String? athleteEmail;
  final String? athleteNumber;
  final String? clubId;
  final String? clubName;
  final String? categoryId;
  final String? categoryName;
  final String? teamId;
  final String? teamName;
  final String status;
  final String? statusMessage;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? rejectedBy;
  final DateTime? rejectedAt;
  final int registrationNumber;
  final bool entryFeePaid;
  final String? paymentReference;
  final DateTime? registeredAt;
  final DateTime? checkedInAt;
  final String? checkedInBy;
  final String? notes;
  final String? athleteNotes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Status helpers
  bool get isPending => status == ParticipantStatus.pending;
  bool get isApproved => status == ParticipantStatus.approved || status == ParticipantStatus.registered;
  bool get isRejected => status == ParticipantStatus.rejected;
  bool get isWithdrawn => status == ParticipantStatus.withdrawn;
  bool get isCheckedIn => status == ParticipantStatus.checkedIn;
  bool get canParticipate => isApproved || isCheckedIn;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'competitionId': competitionId,
      'athleteId': athleteId,
      'athleteName': athleteName,
      'athleteEmail': athleteEmail,
      'athleteNumber': athleteNumber,
      'clubId': clubId,
      'clubName': clubName,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'teamId': teamId,
      'teamName': teamName,
      'status': status,
      'statusMessage': statusMessage,
      'approvedBy': approvedBy,
      'approvedAt': approvedAt?.toIso8601String(),
      'rejectedBy': rejectedBy,
      'rejectedAt': rejectedAt?.toIso8601String(),
      'registrationNumber': registrationNumber,
      'entryFeePaid': entryFeePaid,
      'paymentReference': paymentReference,
      'registeredAt': registeredAt?.toIso8601String(),
      'checkedInAt': checkedInAt?.toIso8601String(),
      'checkedInBy': checkedInBy,
      'notes': notes,
      'athleteNotes': athleteNotes,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  Participant copyWith({
    String? id,
    String? competitionId,
    String? athleteId,
    String? athleteName,
    String? athleteEmail,
    String? athleteNumber,
    String? clubId,
    String? clubName,
    String? categoryId,
    String? categoryName,
    String? teamId,
    String? teamName,
    String? status,
    String? statusMessage,
    String? approvedBy,
    DateTime? approvedAt,
    String? rejectedBy,
    DateTime? rejectedAt,
    int? registrationNumber,
    bool? entryFeePaid,
    String? paymentReference,
    DateTime? registeredAt,
    DateTime? checkedInAt,
    String? checkedInBy,
    String? notes,
    String? athleteNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Participant(
      id: id ?? this.id,
      competitionId: competitionId ?? this.competitionId,
      athleteId: athleteId ?? this.athleteId,
      athleteName: athleteName ?? this.athleteName,
      athleteEmail: athleteEmail ?? this.athleteEmail,
      athleteNumber: athleteNumber ?? this.athleteNumber,
      clubId: clubId ?? this.clubId,
      clubName: clubName ?? this.clubName,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      status: status ?? this.status,
      statusMessage: statusMessage ?? this.statusMessage,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectedBy: rejectedBy ?? this.rejectedBy,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      entryFeePaid: entryFeePaid ?? this.entryFeePaid,
      paymentReference: paymentReference ?? this.paymentReference,
      registeredAt: registeredAt ?? this.registeredAt,
      checkedInAt: checkedInAt ?? this.checkedInAt,
      checkedInBy: checkedInBy ?? this.checkedInBy,
      notes: notes ?? this.notes,
      athleteNotes: athleteNotes ?? this.athleteNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    competitionId,
    athleteId,
    athleteName,
    status,
  ];
}

/// Conteo de participantes por estado
class ParticipantCounts extends Equatable {
  const ParticipantCounts({
    this.pending = 0,
    this.approved = 0,
    this.rejected = 0,
    this.withdrawn = 0,
    this.checkedIn = 0,
    this.total = 0,
  });

  factory ParticipantCounts.fromJson(Map<String, dynamic> json) {
    final pending = (json['pending'] as num?)?.toInt() ?? 0;
    final approved = (json['approved'] as num?)?.toInt() ?? 0;
    final rejected = (json['rejected'] as num?)?.toInt() ?? 0;
    final withdrawn = (json['withdrawn'] as num?)?.toInt() ?? 0;
    final checkedIn = (json['checked_in'] as num?)?.toInt() ?? 0;

    return ParticipantCounts(
      pending: pending,
      approved: approved,
      rejected: rejected,
      withdrawn: withdrawn,
      checkedIn: checkedIn,
      total: (json['total'] as num?)?.toInt() ??
          (pending + approved + rejected + withdrawn + checkedIn),
    );
  }

  final int pending;
  final int approved;
  final int rejected;
  final int withdrawn;
  final int checkedIn;
  final int total;

  int get active => approved + checkedIn;

  @override
  List<Object?> get props =>
      [pending, approved, rejected, withdrawn, checkedIn, total];
}
