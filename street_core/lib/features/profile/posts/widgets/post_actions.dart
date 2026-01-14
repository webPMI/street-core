// lib/presentation/dashboard/posts/widgets/post_actions.dart

import 'package:flutter/material.dart';

/// Widget para las acciones del post (like, comment, share, save)
class PostActions extends StatelessWidget {

  const PostActions({
    super.key,
    this.isLiked = false,
    this.isSaved = false,
    this.onLike,
    this.onComment,
    this.onShare,
    this.onSave,
  });
  final bool isLiked;
  final bool isSaved;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // Like button
          IconButton(
            icon: Icon(
              isLiked ? Icons.favorite : Icons.favorite_border,
              color: isLiked ? Colors.red : null,
            ),
            onPressed: onLike,
            iconSize: 26,
          ),

          // Comment button
          IconButton(
            icon: const Icon(Icons.mode_comment_outlined),
            onPressed: onComment,
            iconSize: 26,
          ),

          // Share button
          IconButton(
            icon: const Icon(Icons.send_outlined),
            onPressed: onShare,
            iconSize: 26,
          ),

          const Spacer(),

          // Save button
          IconButton(
            icon: Icon(
              isSaved ? Icons.bookmark : Icons.bookmark_border,
              color: isSaved ? Colors.amber : null,
            ),
            onPressed: onSave,
            iconSize: 26,
          ),
        ],
      ),
    );
  }
}
