// lib/presentation/dashboard/posts/widgets/post_engagement.dart

import 'package:flutter/material.dart';

import '../../../../core/widgets/my_text.dart';

/// Widget para mostrar el engagement (likes y comentarios)
class PostEngagement extends StatelessWidget {

  const PostEngagement({
    super.key,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.onLikesTap,
    this.onCommentsTap,
  });
  final int likesCount;
  final int commentsCount;
  final VoidCallback? onLikesTap;
  final VoidCallback? onCommentsTap;

  @override
  Widget build(BuildContext context) {
    if (likesCount == 0 && commentsCount == 0) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          // Likes count
          if (likesCount > 0)
            GestureDetector(
              onTap: onLikesTap,
              child: MyText(
                _formatCount(likesCount, 'like'),
                selectable: false,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),

          if (likesCount > 0 && commentsCount > 0)
            const SizedBox(width: 16),

          // Comments count
          if (commentsCount > 0)
            GestureDetector(
              onTap: onCommentsTap,
              child: MyText(
                _formatCount(commentsCount, 'comment'),
                selectable: false,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatCount(int count, String type) {
    if (count == 0) return '';

    final countStr = count > 999 ? '${(count / 1000).toStringAsFixed(1)}k' : '$count';

    if (type == 'like') {
      return '$countStr ${count == 1 ? 'like' : 'likes'}';
    } else {
      return '$countStr ${count == 1 ? 'comment' : 'comments'}';
    }
  }
}
