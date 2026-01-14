/// Modelo de Invitacion de Juez - Representa una invitacion para juzgar una competicion.
/// Following Monolith-by-Features architecture (ADR-005).
///
/// Schema aligned with backend DTO: JudgeInvitationResponse

import 'package:equatable/equatable.dart';

/// Invitation status constants - matches backend constants
class InvitationStatus {
  static const String pending = 'pending';
  static const String accepted = 'accepted';
  static const String declined = 'declined';
  static const String expired = 'expired';

  /// Alias for declined for backward compatibility
  static const String rejected = declined;

  static List<String> get all => [pending, accepted, declined, expired];
  static bool isValid(String status) => all.contains(status);
}

/// Invitacion para que un juez participe en una competicion.
class JudgeInvitation extends Equatable {
  const JudgeInvitation({
    required this.id,
    required this.competitionId,
    this.categoryId,
    required this.invitedUserId,
    required this.invitedById,
    this.invitedUserName = '',
    this.invitedByName = '',
    this.invitedUserEmail,
    this.message,
    required this.status,
    this.expiresAt,
    this.respondedAt,
    this.response,
    required this.createdAt,
    required this.updatedAt,
    this.competitionName = '',
    this.categoryName = '',
  });

  /// Parse from backend JSON response
  factory JudgeInvitation.fromJson(Map<String, dynamic> json) {
    return JudgeInvitation(
      id: json['id'] as String,
      competitionId: json['competitionId'] as String,
      categoryId: json['categoryId'] as String?,
      invitedUserId: json['invitedUserId'] as String? ?? '',
      invitedById: json['invitedById'] as String? ?? '',
      invitedUserName: json['invitedUserName'] as String? ?? '',
      invitedByName: json['invitedByName'] as String? ?? '',
      invitedUserEmail: json['invitedUserEmail'] as String?,
      message: json['message'] as String?,
      status: json['status'] as String? ?? InvitationStatus.pending,
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      respondedAt: json['respondedAt'] != null
          ? DateTime.parse(json['respondedAt'] as String)
          : null,
      response: json['response'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
      competitionName: json['competitionName'] as String? ?? '',
      categoryName: json['categoryName'] as String? ?? '',
    );
  }

  // Core fields from backend
  final String id;
  final String competitionId;
  final String? categoryId;
  final String invitedUserId;
  final String invitedById;
  final String invitedUserName;
  final String invitedByName;
  final String? invitedUserEmail;
  final String? message;
  final String status;
  final DateTime? expiresAt;
  final DateTime? respondedAt;
  final String? response;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Display fields
  final String competitionName;
  final String categoryName;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'competitionId': competitionId,
      if (categoryId != null) 'categoryId': categoryId,
      'invitedUserId': invitedUserId,
      'invitedById': invitedById,
      'invitedUserName': invitedUserName,
      'invitedByName': invitedByName,
      if (invitedUserEmail != null) 'invitedUserEmail': invitedUserEmail,
      if (message != null) 'message': message,
      'status': status,
      if (expiresAt != null) 'expiresAt': expiresAt!.toIso8601String(),
      if (respondedAt != null) 'respondedAt': respondedAt!.toIso8601String(),
      if (response != null) 'response': response,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'competitionName': competitionName,
      'categoryName': categoryName,
    };
  }

  bool get isPending => status == InvitationStatus.pending;
  bool get isAccepted => status == InvitationStatus.accepted;
  bool get isDeclined => status == InvitationStatus.declined;
  bool get isRejected => isDeclined;
  bool get isExpired =>
      status == InvitationStatus.expired ||
      (expiresAt != null && expiresAt!.isBefore(DateTime.now()));
  bool get canRespond => isPending && !isExpired;

  String get statusDisplay {
    if (isExpired && status == InvitationStatus.pending) return 'Expirada';
    switch (status) {
      case InvitationStatus.pending: return 'Pendiente';
      case InvitationStatus.accepted: return 'Aceptada';
      case InvitationStatus.declined: return 'Rechazada';
      case InvitationStatus.expired: return 'Expirada';
      default: return status;
    }
  }

  JudgeInvitation copyWith({
    String? id,
    String? competitionId,
    String? categoryId,
    String? invitedUserId,
    String? invitedById,
    String? invitedUserName,
    String? invitedByName,
    String? invitedUserEmail,
    String? message,
    String? status,
    DateTime? expiresAt,
    DateTime? respondedAt,
    String? response,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? competitionName,
    String? categoryName,
  }) {
    return JudgeInvitation(
      id: id ?? this.id,
      competitionId: competitionId ?? this.competitionId,
      categoryId: categoryId ?? this.categoryId,
      invitedUserId: invitedUserId ?? this.invitedUserId,
      invitedById: invitedById ?? this.invitedById,
      invitedUserName: invitedUserName ?? this.invitedUserName,
      invitedByName: invitedByName ?? this.invitedByName,
      invitedUserEmail: invitedUserEmail ?? this.invitedUserEmail,
      message: message ?? this.message,
      status: status ?? this.status,
      expiresAt: expiresAt ?? this.expiresAt,
      respondedAt: respondedAt ?? this.respondedAt,
      response: response ?? this.response,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      competitionName: competitionName ?? this.competitionName,
      categoryName: categoryName ?? this.categoryName,
    );
  }

  @override
  List<Object?> get props => [id, competitionId, categoryId, invitedUserId, status, createdAt];

  @override
  String toString() => 'JudgeInvitation(id: $id, status: $status, competition: $competitionName)';
}
