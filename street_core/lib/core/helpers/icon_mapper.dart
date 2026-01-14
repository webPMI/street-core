import 'package:flutter/material.dart';

/// Maps string icon names to Material Icons
/// Used for dynamic content from SiteConfig
class IconMapper {
  static IconData fromString(String? iconName, {IconData fallback = Icons.info}) {
    if (iconName == null || iconName.isEmpty) return fallback;

    // Convert to lowercase for case-insensitive matching
    final name = iconName.toLowerCase().trim();

    // Map common icon names to Material Icons
    switch (name) {
      // Sports & Activity
      case 'sports':
      case 'sport':
        return Icons.sports;
      case 'sports.gymnastics':
      case 'gymnastics':
        return Icons.sports_gymnastics_rounded;
      case 'fitness':
      case 'fitness.center':
        return Icons.fitness_center;
      case 'sports.soccer':
      case 'soccer':
        return Icons.sports_soccer;
      case 'sports.basketball':
      case 'basketball':
        return Icons.sports_basketball;
      case 'sports.tennis':
      case 'tennis':
        return Icons.sports_tennis;

      // E-commerce & Market
      case 'store':
      case 'shop':
      case 'market':
        return Icons.store;
      case 'shopping.cart':
      case 'cart':
        return Icons.shopping_cart;
      case 'shopping.bag':
      case 'bag':
        return Icons.shopping_bag;

      // Events & Calendar
      case 'event':
      case 'events':
        return Icons.event;
      case 'calendar':
      case 'calendar.today':
        return Icons.calendar_today;
      case 'schedule':
        return Icons.schedule;

      // Communication
      case 'email':
      case 'mail':
        return Icons.email;
      case 'phone':
      case 'call':
        return Icons.phone;
      case 'chat':
      case 'message':
        return Icons.chat;
      case 'notifications':
      case 'notification':
        return Icons.notifications;

      // People & Groups
      case 'people':
      case 'group':
        return Icons.people;
      case 'person':
      case 'user':
        return Icons.person;
      case 'groups':
        return Icons.groups;
      case 'family':
      case 'family.restroom':
        return Icons.family_restroom;

      // Location & Map
      case 'location':
      case 'location.on':
        return Icons.location_on;
      case 'map':
        return Icons.map;
      case 'place':
        return Icons.place;

      // UI & Navigation
      case 'home':
        return Icons.home;
      case 'star':
        return Icons.star;
      case 'favorite':
      case 'heart':
        return Icons.favorite;
      case 'check':
      case 'check.circle':
        return Icons.check_circle;
      case 'verified':
      case 'verified.user':
        return Icons.verified_user;
      case 'badge':
        return Icons.badge;

      // Content
      case 'article':
      case 'description':
        return Icons.article;
      case 'image':
      case 'photo':
        return Icons.image;
      case 'video':
      case 'videocam':
        return Icons.videocam;
      case 'audio':
      case 'music':
        return Icons.music_note;

      // Finance
      case 'payment':
      case 'credit.card':
        return Icons.credit_card;
      case 'money':
      case 'attach.money':
        return Icons.attach_money;
      case 'account.balance.wallet':
        return Icons.account_balance_wallet;

      // Support & Help
      case 'help':
      case 'help.center':
        return Icons.help;
      case 'support':
      case 'support.agent':
        return Icons.support_agent;
      case 'info':
      case 'information':
        return Icons.info;

      // Security
      case 'security':
      case 'shield':
        return Icons.security;
      case 'lock':
        return Icons.lock;

      // Business
      case 'business':
      case 'business.center':
        return Icons.business_center;
      case 'work':
        return Icons.work;
      case 'trending.up':
      case 'growth':
        return Icons.trending_up;

      // Tech & Features
      case 'dashboard':
        return Icons.dashboard;
      case 'settings':
        return Icons.settings;
      case 'analytics':
      case 'insights':
        return Icons.insights;
      case 'cloud':
      case 'cloud.upload':
        return Icons.cloud_upload;
      case 'speed':
      case 'performance':
        return Icons.speed;
      case 'lightbulb':
      case 'idea':
        return Icons.lightbulb;

      // Social
      case 'share':
        return Icons.share;
      case 'thumb.up':
      case 'like':
        return Icons.thumb_up;
      case 'comment':
        return Icons.comment;

      // Time
      case 'access.time':
      case 'time':
        return Icons.access_time;
      case 'timer':
        return Icons.timer;
      case 'today':
        return Icons.today;

      // Miscellaneous
      case 'diamond':
      case 'premium':
        return Icons.diamond;
      case 'rocket':
      case 'rocket.launch':
        return Icons.rocket_launch;
      case 'emoji.events':
      case 'trophy':
        return Icons.emoji_events;
      case 'celebration':
      case 'party':
        return Icons.celebration;

      default:
        return fallback;
    }
  }

  /// Get icon name from IconData (for reverse mapping if needed)
  static String? toIconName(IconData icon) {
    // This is a simplified reverse mapping for common icons
    if (icon == Icons.sports) return 'sports';
    if (icon == Icons.store) return 'store';
    if (icon == Icons.event) return 'event';
    if (icon == Icons.people) return 'people';
    if (icon == Icons.email) return 'email';
    if (icon == Icons.phone) return 'phone';
    return null;
  }
}
