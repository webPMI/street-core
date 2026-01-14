import '../../../core/widgets/my_text.dart';
import 'package:flutter/material.dart';

/// Profile Stats Widget
/// Displays a single stat column (posts, followers, following)
class ProfileStatColumn extends StatelessWidget {

  const ProfileStatColumn({
    super.key,
    required this.label,
    required this.count,
    this.onTap,
  });
  final String label;
  final String count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MyText(
            count,
            istitle: true,
            fontSize: 18,
            noTranslation: true,
            selectable: false,
          ),
          const SizedBox(height: 4),
          MyText(label, fontSize: 12, selectable: false),
        ],
      ),
    );
  }
}

/// Profile Stats Row
/// Displays all three stats in a row
class ProfileStatsRow extends StatelessWidget {

  const ProfileStatsRow({
    super.key,
    required this.postsCount,
    required this.followersCount,
    required this.followingCount,
    this.onFollowersTap,
    this.onFollowingTap,
  });
  final String postsCount;
  final String followersCount;
  final String followingCount;
  final VoidCallback? onFollowersTap;
  final VoidCallback? onFollowingTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ProfileStatColumn(
          label: 'posts',
          count: postsCount,
        ),
        ProfileStatColumn(
          label: 'followers',
          count: followersCount,
          onTap: onFollowersTap,
        ),
        ProfileStatColumn(
          label: 'following',
          count: followingCount,
          onTap: onFollowingTap,
        ),
      ],
    );
  }
}
