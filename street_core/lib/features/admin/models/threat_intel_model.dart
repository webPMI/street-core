// lib/admin/models/threat_intel_model.dart

import 'package:equatable/equatable.dart';

/// Threat Intelligence Entity
class ThreatIntel extends Equatable {
  const ThreatIntel({
    required this.ipAddress,
    required this.threatLevel,
    required this.isBlocked,
    required this.firstSeen,
    required this.lastSeen,
    required this.requestCount,
    required this.blockedCount,
    this.country,
    this.city,
    this.isp,
    this.asn,
    this.threatTypes,
    this.reputation,
    this.blockReason,
    this.blockType,
    this.blockedAt,
    this.blockExpiresAt,
    this.blockedBy,
    this.enrichedData,
    this.metadata,
  });

  final String ipAddress;
  final String threatLevel;
  final bool isBlocked;
  final DateTime firstSeen;
  final DateTime lastSeen;
  final int requestCount;
  final int blockedCount;
  final String? country;
  final String? city;
  final String? isp;
  final String? asn;
  final List<String>? threatTypes;
  final int? reputation;
  final String? blockReason;
  final String? blockType;
  final DateTime? blockedAt;
  final DateTime? blockExpiresAt;
  final String? blockedBy;
  final Map<String, dynamic>? enrichedData;
  final Map<String, dynamic>? metadata;

  @override
  List<Object?> get props => [
        ipAddress,
        threatLevel,
        isBlocked,
        firstSeen,
        lastSeen,
        requestCount,
        blockedCount,
        country,
        city,
        isp,
        asn,
        threatTypes,
        reputation,
        blockReason,
        blockType,
        blockedAt,
        blockExpiresAt,
        blockedBy,
        enrichedData,
        metadata,
      ];
}

/// Threat Intelligence Model (Data Transfer Object)
class ThreatIntelModel extends ThreatIntel {
  const ThreatIntelModel({
    required super.ipAddress,
    required super.threatLevel,
    required super.isBlocked,
    required super.firstSeen,
    required super.lastSeen,
    required super.requestCount,
    required super.blockedCount,
    super.country,
    super.city,
    super.isp,
    super.asn,
    super.threatTypes,
    super.reputation,
    super.blockReason,
    super.blockType,
    super.blockedAt,
    super.blockExpiresAt,
    super.blockedBy,
    super.enrichedData,
    super.metadata,
  });

  /// Create from JSON
  factory ThreatIntelModel.fromJson(Map<String, dynamic> json) {
    return ThreatIntelModel(
      ipAddress: json['ip_address'] as String,
      threatLevel: json['threat_level'] as String,
      isBlocked: json['is_blocked'] as bool,
      firstSeen: DateTime.parse(json['first_seen'] as String),
      lastSeen: DateTime.parse(json['last_seen'] as String),
      requestCount: json['request_count'] as int,
      blockedCount: json['blocked_count'] as int,
      country: json['country'] as String?,
      city: json['city'] as String?,
      isp: json['isp'] as String?,
      asn: json['asn'] as String?,
      threatTypes: (json['threat_types'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      reputation: json['reputation'] as int?,
      blockReason: json['block_reason'] as String?,
      blockType: json['block_type'] as String?,
      blockedAt: json['blocked_at'] != null
          ? DateTime.parse(json['blocked_at'] as String)
          : null,
      blockExpiresAt: json['block_expires_at'] != null
          ? DateTime.parse(json['block_expires_at'] as String)
          : null,
      blockedBy: json['blocked_by'] as String?,
      enrichedData: json['enriched_data'] as Map<String, dynamic>?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'ip_address': ipAddress,
      'threat_level': threatLevel,
      'is_blocked': isBlocked,
      'first_seen': firstSeen.toIso8601String(),
      'last_seen': lastSeen.toIso8601String(),
      'request_count': requestCount,
      'blocked_count': blockedCount,
      if (country != null) 'country': country,
      if (city != null) 'city': city,
      if (isp != null) 'isp': isp,
      if (asn != null) 'asn': asn,
      if (threatTypes != null) 'threat_types': threatTypes,
      if (reputation != null) 'reputation': reputation,
      if (blockReason != null) 'block_reason': blockReason,
      if (blockType != null) 'block_type': blockType,
      if (blockedAt != null) 'blocked_at': blockedAt!.toIso8601String(),
      if (blockExpiresAt != null)
        'block_expires_at': blockExpiresAt!.toIso8601String(),
      if (blockedBy != null) 'blocked_by': blockedBy,
      if (enrichedData != null) 'enriched_data': enrichedData,
      if (metadata != null) 'metadata': metadata,
    };
  }

  /// Create a copy with modified fields
  ThreatIntelModel copyWith({
    String? ipAddress,
    String? threatLevel,
    bool? isBlocked,
    DateTime? firstSeen,
    DateTime? lastSeen,
    int? requestCount,
    int? blockedCount,
    String? country,
    String? city,
    String? isp,
    String? asn,
    List<String>? threatTypes,
    int? reputation,
    String? blockReason,
    String? blockType,
    DateTime? blockedAt,
    DateTime? blockExpiresAt,
    String? blockedBy,
    Map<String, dynamic>? enrichedData,
    Map<String, dynamic>? metadata,
  }) {
    return ThreatIntelModel(
      ipAddress: ipAddress ?? this.ipAddress,
      threatLevel: threatLevel ?? this.threatLevel,
      isBlocked: isBlocked ?? this.isBlocked,
      firstSeen: firstSeen ?? this.firstSeen,
      lastSeen: lastSeen ?? this.lastSeen,
      requestCount: requestCount ?? this.requestCount,
      blockedCount: blockedCount ?? this.blockedCount,
      country: country ?? this.country,
      city: city ?? this.city,
      isp: isp ?? this.isp,
      asn: asn ?? this.asn,
      threatTypes: threatTypes ?? this.threatTypes,
      reputation: reputation ?? this.reputation,
      blockReason: blockReason ?? this.blockReason,
      blockType: blockType ?? this.blockType,
      blockedAt: blockedAt ?? this.blockedAt,
      blockExpiresAt: blockExpiresAt ?? this.blockExpiresAt,
      blockedBy: blockedBy ?? this.blockedBy,
      enrichedData: enrichedData ?? this.enrichedData,
      metadata: metadata ?? this.metadata,
    );
  }
}
