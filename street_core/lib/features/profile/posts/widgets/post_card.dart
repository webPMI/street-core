// lib/presentation/dashboard/posts/widgets/post_card.dart

import '../../models/post_model.dart';
import 'post_actions.dart';
import 'post_caption.dart';
import 'post_engagement.dart';
import 'post_header.dart';
import 'post_media_carousel.dart';
import 'package:flutter/material.dart';

/// Widget principal para mostrar un post completo
class PostCard extends StatelessWidget {
  const PostCard({
    super.key,
    required this.post,
    this.onLike,
    this.onComment,
    this.onShare,
    this.onSave,
    this.onDelete,
    this.onUserTap,
    this.onPostTap,
    this.onLikesTap,
  });
  final PostModel post;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final VoidCallback? onSave;
  final VoidCallback? onDelete;
  final VoidCallback? onUserTap;
  final VoidCallback? onPostTap;
  final VoidCallback? onLikesTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: User info
          PostHeader(
            userName: post.userName,
            userAvatar: post.userAvatar,
            location: post.location,
            createdAt: post.createdAt,
            onUserTap: onUserTap,
            onMoreTap: onDelete,
          ),

          // Media carousel (si tiene imágenes/videos)
          if (post.hasMedia)
            PostMediaCarousel(
              mediaUrls: post.mediaUrls,
              mediaType: post.mediaType,
              onTap: onPostTap,
            ),

          // Engagement: likes y comments count
          PostEngagement(
            likesCount: post.likesCount,
            commentsCount: post.commentsCount,
            onLikesTap: onLikesTap,
            onCommentsTap: onComment,
          ),

          // Actions: like, comment, share, save
          PostActions(
            isLiked: post.isLikedByCurrentUser,
            isSaved: post.isSavedByCurrentUser,
            onLike: onLike,
            onComment: onComment,
            onShare: onShare,
            onSave: onSave,
          ),

          // Caption con hashtags y menciones
          if (post.caption.isNotEmpty)
            PostCaption(
              userName: post.userName,
              caption: post.caption,
              tags: post.tags,
              mentions: post.mentions,
            ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
