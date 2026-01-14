/// Social Media Links Model
///
/// Contains social media profile URLs for the organization.
class SocialMedia {
  SocialMedia({
    this.facebook,
    this.instagram,
    this.twitter,
    this.youtube,
    this.tiktok,
    this.linkedin,
    this.discord,
    this.telegram,
  });

  factory SocialMedia.fromJson(Map<String, dynamic> json) {
    return SocialMedia(
      facebook: json['facebook'],
      instagram: json['instagram'],
      twitter: json['twitter'],
      youtube: json['youtube'],
      tiktok: json['tiktok'],
      linkedin: json['linkedin'],
      discord: json['discord'],
      telegram: json['telegram'],
    );
  }

  factory SocialMedia.empty() => SocialMedia();

  final String? facebook;
  final String? instagram;
  final String? twitter;
  final String? youtube;
  final String? tiktok;
  final String? linkedin;
  final String? discord;
  final String? telegram;

  // Convenience getters
  String get safeFacebook => facebook ?? '';
  String get safeInstagram => instagram ?? '';
  String get safeTwitter => twitter ?? '';
  String get safeYouTube => youtube ?? '';
  String get safeTikTok => tiktok ?? '';
  String get safeLinkedIn => linkedin ?? '';
  String get safeDiscord => discord ?? '';
  String get safeTelegram => telegram ?? '';

  Map<String, dynamic> toJson() => {
        if (facebook != null) 'facebook': facebook,
        if (instagram != null) 'instagram': instagram,
        if (twitter != null) 'twitter': twitter,
        if (youtube != null) 'youtube': youtube,
        if (tiktok != null) 'tiktok': tiktok,
        if (linkedin != null) 'linkedin': linkedin,
        if (discord != null) 'discord': discord,
        if (telegram != null) 'telegram': telegram,
      };
}
