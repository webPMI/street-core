// lib/features/livestreams/widgets/stream_chat_bubble.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:street_core/core/theme/app_spacing.dart';
import 'package:street_core/features/livestreams/models/models.dart';
import 'package:timeago/timeago.dart' as timeago;

/// Reusable chat message bubble
///
/// Usage:
/// ```dart
/// StreamChatBubble(
///   message: chatMessage,
///   onLongPress: () => showOptions(),
/// )
///
/// StreamChatBubble.compact(message: chatMessage)
/// ```
class StreamChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool showAvatar;
  final bool showTimestamp;
  final bool isCompact;
  final VoidCallback? onLongPress;
  final VoidCallback? onAvatarTap;
  final Color? backgroundColor;
  final Color? textColor;

  const StreamChatBubble({
    super.key,
    required this.message,
    this.showAvatar = true,
    this.showTimestamp = true,
    this.isCompact = false,
    this.onLongPress,
    this.onAvatarTap,
    this.backgroundColor,
    this.textColor,
  });

  /// Compact version (no avatar, smaller padding)
  const StreamChatBubble.compact({
    super.key,
    required this.message,
    this.showTimestamp = false,
    this.onLongPress,
    this.onAvatarTap,
    this.backgroundColor,
    this.textColor,
  })  : showAvatar = false,
        isCompact = true;

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ??
        (message.isPinned
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surface.withValues(alpha: 0.8));

    final txtColor = textColor ??
        (message.isPinned
            ? Theme.of(context).colorScheme.onPrimaryContainer
            : Theme.of(context).colorScheme.onSurface);

    return InkWell(
      onLongPress: onLongPress,
      child: Container(
        padding: EdgeInsets.all(isCompact ? AppSpacing.xs : AppSpacing.sm),
        margin: EdgeInsets.only(bottom: isCompact ? 2 : 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(isCompact ? 4 : 8),
          border: message.isPinned
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                )
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            if (showAvatar) ...[
              GestureDetector(
                onTap: onAvatarTap,
                child: _buildAvatar(),
              ),
              SizedBox(width: AppSpacing.sm),
            ],

            // Message content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header (username + timestamp)
                  Row(
                    children: [
                      // Username
                      Flexible(
                        child: Text(
                          message.username,
                          style: TextStyle(
                            color: txtColor,
                            fontWeight: FontWeight.bold,
                            fontSize: isCompact ? 12 : 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // Pinned indicator
                      if (message.isPinned) ...[
                        SizedBox(width: AppSpacing.xs),
                        Icon(
                          Icons.push_pin,
                          size: 14,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ],

                      // Timestamp
                      if (showTimestamp) ...[
                        SizedBox(width: AppSpacing.xs),
                        Text(
                          timeago.format(message.createdAt, locale: 'es'),
                          style: TextStyle(
                            color: txtColor.withValues(alpha: 0.6),
                            fontSize: isCompact ? 10 : 11,
                          ),
                        ),
                      ],
                    ],
                  ),

                  SizedBox(height: isCompact ? 2 : 4),

                  // Message text
                  Text(
                    message.message,
                    style: TextStyle(
                      color: txtColor,
                      fontSize: isCompact ? 13 : 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    final size = isCompact ? 28.0 : 36.0;

    if (message.avatarUrl != null && message.avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: CachedNetworkImageProvider(message.avatarUrl!),
        onBackgroundImageError: (_, __) {},
        child: Container(), // Empty container for error fallback
      );
    }

    // Fallback to initials
    final initials = message.username.isNotEmpty
        ? message.username.substring(0, 1).toUpperCase()
        : '?';

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: _getColorFromUsername(message.username),
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: isCompact ? 14 : 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getColorFromUsername(String username) {
    // Generate consistent color from username
    final hash = username.hashCode;
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      Colors.teal,
      Colors.indigo,
      Colors.cyan,
    ];
    return colors[hash.abs() % colors.length];
  }
}

/// Pinned message banner
///
/// Shows pinned message at the top of chat
///
/// Usage:
/// ```dart
/// PinnedMessageBanner(
///   message: pinnedMessage,
///   onTap: () => scrollToMessage(),
///   onUnpin: () => unpinMessage(),
/// )
/// ```
class PinnedMessageBanner extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onTap;
  final VoidCallback? onUnpin;

  const PinnedMessageBanner({
    super.key,
    required this.message,
    this.onTap,
    this.onUnpin,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.primaryContainer,
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: [
              Icon(
                Icons.push_pin,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Mensaje fijado',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${message.username}: ${message.message}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (onUnpin != null) ...[
                SizedBox(width: AppSpacing.sm),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: onUnpin,
                  color: Theme.of(context).colorScheme.primary,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
