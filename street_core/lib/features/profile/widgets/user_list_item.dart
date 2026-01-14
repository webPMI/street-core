import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/router/navigation_service.dart';
import '../../../core/widgets/my_text.dart';
import '../../../data/models/user_model.dart';
import 'premium_badge.dart';
import 'package:flutter/material.dart';

/// User List Item Widget
/// Displays a user in a list (for followers/following pages)
class UserListItem extends StatelessWidget {
  const UserListItem({super.key, required this.user});
  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: GestureDetector(
        onTap: () => _navigateToProfile(context),
        child: CircleAvatar(
          radius: 28,
          backgroundColor: theme.colorScheme.primaryContainer,
          backgroundImage: user.imageUrl != null && user.imageUrl!.isNotEmpty
              ? CachedNetworkImageProvider(user.imageUrl!)
              : null,
          child: user.imageUrl == null || user.imageUrl!.isEmpty
              ? Icon(
                  Icons.person,
                  size: 28,
                  color: theme.colorScheme.onPrimaryContainer,
                )
              : null,
        ),
      ),
      title: GestureDetector(
        onTap: () => _navigateToProfile(context),
        child: Row(
          children: [
            Flexible(
              child: MyText(
                user.firstName,
                istitle: true,
                fontSize: 16,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            if (user.isVerified)
              Icon(Icons.verified, size: 16, color: theme.colorScheme.primary),
            if (user.isPremium) ...[
              const SizedBox(width: 4),
              const PremiumBadge(variant: BadgeVariant.small),
            ],
          ],
        ),
      ),
      subtitle: user.nickName != null && user.nickName!.isNotEmpty
          ? GestureDetector(
              onTap: () => _navigateToProfile(context),
              child: MyText(
                '@${user.nickName}',
                fontSize: 14,
                color: theme.colorScheme.onSurfaceVariant,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            )
          : null,
      trailing: IconButton(
        icon: const Icon(Icons.chevron_right),
        onPressed: () => _navigateToProfile(context),
      ),
      onTap: () => _navigateToProfile(context),
    );
  }

  void _navigateToProfile(BuildContext context) {
    NavigationService().go(
      context,
      '${AppRoutes.dashboard}/profile/${user.id}',
    );
  }
}
