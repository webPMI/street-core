// lib/presentation/dashboard/posts/widgets/post_header.dart

import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../core/widgets/my_text.dart';
import '../../../../core/widgets/user_avatar.dart';

/// Widget para el encabezado del post (info del usuario)
class PostHeader extends StatelessWidget {
  const PostHeader({
    super.key,
    required this.userName,
    this.userAvatar,
    this.location,
    required this.createdAt,
    this.onUserTap,
    this.onMoreTap,
  });
  final String userName;
  final String? userAvatar;
  final String? location;
  final DateTime createdAt;
  final VoidCallback? onUserTap;
  final VoidCallback? onMoreTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // Avatar
          GestureDetector(
            onTap: onUserTap,
            child: UserAvatar(
              size: 20,
              imageUrl: userAvatar,
              fallbackText: userName.isNotEmpty ? userName : 'U',
              onTap: () {},
            ),
          ),

          const SizedBox(width: 12),

          // User info
          Expanded(
            child: GestureDetector(
              onTap: onUserTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Username
                  MyText(
                    userName,
                    noTranslation: true,
                    selectable: false,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),

                  // Location y timestamp
                  Row(
                    children: [
                      if (location != null && location!.isNotEmpty) ...[
                        MyText(
                          location!,
                          noTranslation: true,
                          selectable: false,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const MyText(' · ', noTranslation: true, selectable: false),
                      ],
                      MyText(
                        timeago.format(createdAt, locale: 'es'),
                        noTranslation: true,
                        selectable: false,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // More options button
          if (onMoreTap != null)
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: onMoreTap,
              iconSize: 20,
            ),
        ],
      ),
    );
  }
}
