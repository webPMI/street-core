// lib/features/profile/widgets/profile_header.dart
import '../../../core/widgets/my_text.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../data/models/user_model.dart';
import 'premium_badge.dart';
import 'package:flutter/material.dart';

/// Profile Header Widget
/// Displays user's name, nickname, badges, bio, and member since date
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key, required this.user});
  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserAvatar(
            size: 60,
            imageUrl: user.imageUrl,
            fallbackText: user.firstName,
          ),
          // Username with large premium badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  MyText(
                    user.nickName ?? user.firstName,
                    istitle: true,
                    fontSize: 20,
                    noTranslation: true,
                  ),
                  if (user.isPremium) ...[
                    const SizedBox(width: 8),
                    const PremiumBadge(),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Full name with badges (verified, pro)

          // Bio
          if (user.bio != null && user.bio!.isNotEmpty) ...[
            const SizedBox(height: 4),
            MyText(user.bio!, noTranslation: true, maxLines: 3),
          ],

          // Member since date
          if (user.createdAt != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                MyText(
                  'member.since',
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatMemberSince(user.createdAt!),
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatMemberSince(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}
