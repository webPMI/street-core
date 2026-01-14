import 'package:equatable/equatable.dart';

/// Privacy Settings Model
/// Represents user privacy and security preferences
class PrivacySettings extends Equatable {

  const PrivacySettings({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    required this.profileVisibility,
    required this.showEmail,
    required this.showPhone,
    required this.showBirthdate,
    required this.showOnlineStatus,
    required this.showLastSeen,
    required this.showActivityFeed,
    required this.allowTagging,
    required this.allowMentions,
    required this.whoCanMessage,
    required this.whoCanComment,
    required this.whoCanFollow,
    required this.requireFollowApproval,
    required this.allowDataCollection,
    required this.allowPersonalizedAds,
    required this.allowThirdPartySharing,
    required this.blockedUserIds,
  });

  factory PrivacySettings.fromJson(Map<String, dynamic> json) {
    return PrivacySettings(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'].toString())
          : DateTime.now(),
      profileVisibility: json['profileVisibility']?.toString() ?? 'public',
      showEmail: json['showEmail'] as bool? ?? false,
      showPhone: json['showPhone'] as bool? ?? false,
      showBirthdate: json['showBirthdate'] as bool? ?? false,
      showOnlineStatus: json['showOnlineStatus'] as bool? ?? true,
      showLastSeen: json['showLastSeen'] as bool? ?? true,
      showActivityFeed: json['showActivityFeed'] as bool? ?? true,
      allowTagging: json['allowTagging'] as bool? ?? true,
      allowMentions: json['allowMentions'] as bool? ?? true,
      whoCanMessage: json['whoCanMessage']?.toString() ?? 'everyone',
      whoCanComment: json['whoCanComment']?.toString() ?? 'everyone',
      whoCanFollow: json['whoCanFollow']?.toString() ?? 'everyone',
      requireFollowApproval: json['requireFollowApproval'] as bool? ?? false,
      allowDataCollection: json['allowDataCollection'] as bool? ?? true,
      allowPersonalizedAds: json['allowPersonalizedAds'] as bool? ?? true,
      allowThirdPartySharing: json['allowThirdPartySharing'] as bool? ?? false,
      blockedUserIds: json['blockedUserIds'] != null
          ? List<String>.from(json['blockedUserIds'] as List)
          : [],
    );
  }
  final String id;
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Profile Visibility
  final String profileVisibility; // public, private, friends
  final bool showEmail;
  final bool showPhone;
  final bool showBirthdate;

  // Activity Privacy
  final bool showOnlineStatus;
  final bool showLastSeen;
  final bool showActivityFeed;
  final bool allowTagging;
  final bool allowMentions;

  // Interaction Privacy
  final String whoCanMessage; // everyone, friends, nobody
  final String whoCanComment; // everyone, friends, nobody
  final String whoCanFollow; // everyone, nobody
  final bool requireFollowApproval;

  // Data Privacy
  final bool allowDataCollection;
  final bool allowPersonalizedAds;
  final bool allowThirdPartySharing;

  // Blocked Users
  final List<String> blockedUserIds;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'profileVisibility': profileVisibility,
      'showEmail': showEmail,
      'showPhone': showPhone,
      'showBirthdate': showBirthdate,
      'showOnlineStatus': showOnlineStatus,
      'showLastSeen': showLastSeen,
      'showActivityFeed': showActivityFeed,
      'allowTagging': allowTagging,
      'allowMentions': allowMentions,
      'whoCanMessage': whoCanMessage,
      'whoCanComment': whoCanComment,
      'whoCanFollow': whoCanFollow,
      'requireFollowApproval': requireFollowApproval,
      'allowDataCollection': allowDataCollection,
      'allowPersonalizedAds': allowPersonalizedAds,
      'allowThirdPartySharing': allowThirdPartySharing,
      'blockedUserIds': blockedUserIds,
    };
  }

  PrivacySettings copyWith({
    String? id,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? profileVisibility,
    bool? showEmail,
    bool? showPhone,
    bool? showBirthdate,
    bool? showOnlineStatus,
    bool? showLastSeen,
    bool? showActivityFeed,
    bool? allowTagging,
    bool? allowMentions,
    String? whoCanMessage,
    String? whoCanComment,
    String? whoCanFollow,
    bool? requireFollowApproval,
    bool? allowDataCollection,
    bool? allowPersonalizedAds,
    bool? allowThirdPartySharing,
    List<String>? blockedUserIds,
  }) {
    return PrivacySettings(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      profileVisibility: profileVisibility ?? this.profileVisibility,
      showEmail: showEmail ?? this.showEmail,
      showPhone: showPhone ?? this.showPhone,
      showBirthdate: showBirthdate ?? this.showBirthdate,
      showOnlineStatus: showOnlineStatus ?? this.showOnlineStatus,
      showLastSeen: showLastSeen ?? this.showLastSeen,
      showActivityFeed: showActivityFeed ?? this.showActivityFeed,
      allowTagging: allowTagging ?? this.allowTagging,
      allowMentions: allowMentions ?? this.allowMentions,
      whoCanMessage: whoCanMessage ?? this.whoCanMessage,
      whoCanComment: whoCanComment ?? this.whoCanComment,
      whoCanFollow: whoCanFollow ?? this.whoCanFollow,
      requireFollowApproval: requireFollowApproval ?? this.requireFollowApproval,
      allowDataCollection: allowDataCollection ?? this.allowDataCollection,
      allowPersonalizedAds: allowPersonalizedAds ?? this.allowPersonalizedAds,
      allowThirdPartySharing: allowThirdPartySharing ?? this.allowThirdPartySharing,
      blockedUserIds: blockedUserIds ?? this.blockedUserIds,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        createdAt,
        updatedAt,
        profileVisibility,
        showEmail,
        showPhone,
        showBirthdate,
        showOnlineStatus,
        showLastSeen,
        showActivityFeed,
        allowTagging,
        allowMentions,
        whoCanMessage,
        whoCanComment,
        whoCanFollow,
        requireFollowApproval,
        allowDataCollection,
        allowPersonalizedAds,
        allowThirdPartySharing,
        blockedUserIds,
      ];
}
