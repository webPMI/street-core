// lib/features/social/like/widgets/like_button.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/helpers/logger.dart';
import '../../../../core/helpers/snackbar_helper.dart';
import '../like_cubit.dart';
import '../like_state.dart';

/// Reusable like button widget with animation and count
/// Now supports ANY entity type (posts, competitions, events, clubs, etc.)
///
/// Usage examples:
/// ```dart
/// // For posts
/// LikeButton(
///   entityType: 'post',
///   entityId: post.id,
///   isLiked: post.isLikedByCurrentUser,
///   likesCount: post.likesCount,
/// )
///
/// // For competitions
/// LikeButton(
///   entityType: 'competition',
///   entityId: competition.id,
///   isLiked: competition.isLikedByCurrentUser,
///   likesCount: competition.likesCount,
/// )
///
/// // For events
/// LikeButton(
///   entityType: 'event',
///   entityId: event.id,
///   isLiked: event.isLikedByCurrentUser,
///   likesCount: event.likesCount,
/// )
/// ```
class LikeButton extends StatelessWidget {
  const LikeButton({
    super.key,
    required this.entityType,
    required this.entityId,
    required this.isLiked,
    required this.likesCount,
    this.size = 24.0,
    this.showCount = true,
    this.likedColor,
    this.unlikedColor,
    this.onLikeChanged,
  });

  final String entityType; // 'post', 'competition', 'event', etc.
  final String entityId;
  final bool isLiked;
  final int likesCount;
  final double size;
  final bool showCount;
  final Color? likedColor;
  final Color? unlikedColor;
  final ValueChanged<bool>? onLikeChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveLikedColor = likedColor ?? Colors.red;
    final effectiveUnlikedColor =
        unlikedColor ?? theme.iconTheme.color ?? Colors.grey;

    return BlocProvider(
      create: (_) => GetIt.instance<LikeCubit>(),
      child: BlocConsumer<LikeCubit, LikeState>(
        listener: (context, state) {
          if (state is LikeSuccess && onLikeChanged != null) {
            onLikeChanged!(state.isLiked);
          }

          // ERROR HANDLING: Show error message to user
          if (state is LikeError) {
            AppLogger.error(
              'Like error displayed to user: ${state.message}',
              tag: 'LikeButton',
            );

            SnackBarHelper.showError(
              context,
              'error.like_operation_failed',
            );
          }
        },
        builder: (context, state) {
          final currentIsLiked = state is LikeSuccess ? state.isLiked : isLiked;
          final currentCount =
              state is LikeSuccess ? state.likesCount : likesCount;

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () {
                  AppLogger.debug(
                    'User tapped like button for $entityType: $entityId',
                    tag: 'LikeButton',
                  );

                  context.read<LikeCubit>().toggleLikeEntity(
                        entityType: entityType,
                        entityId: entityId,
                        isCurrentlyLiked: currentIsLiked,
                        currentCount: currentCount,
                      );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    currentIsLiked ? Icons.favorite : Icons.favorite_border,
                    size: size,
                    color: currentIsLiked
                        ? effectiveLikedColor
                        : effectiveUnlikedColor,
                  ),
                ),
              ),
              if (showCount) ...[
                const SizedBox(width: 4),
                Text(
                  _formatCount(currentCount),
                  style: TextStyle(
                    fontSize: size * 0.6,
                    fontWeight: FontWeight.w500,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}

/// Animated like button with scale animation
/// Now supports ANY entity type (posts, competitions, events, clubs, etc.)
///
/// Usage examples:
/// ```dart
/// // For posts
/// AnimatedLikeButton(
///   entityType: 'post',
///   entityId: post.id,
///   isLiked: post.isLikedByCurrentUser,
///   likesCount: post.likesCount,
///   size: 28.0,
/// )
///
/// // For competitions
/// AnimatedLikeButton(
///   entityType: 'competition',
///   entityId: competition.id,
///   isLiked: competition.isLikedByCurrentUser,
///   likesCount: competition.likesCount,
/// )
/// ```
class AnimatedLikeButton extends StatefulWidget {
  const AnimatedLikeButton({
    super.key,
    required this.entityType,
    required this.entityId,
    required this.isLiked,
    required this.likesCount,
    this.size = 24.0,
    this.showCount = true,
    this.likedColor,
    this.unlikedColor,
  });

  final String entityType; // 'post', 'competition', 'event', etc.
  final String entityId;
  final bool isLiked;
  final int likesCount;
  final double size;
  final bool showCount;
  final Color? likedColor;
  final Color? unlikedColor;

  @override
  State<AnimatedLikeButton> createState() => _AnimatedLikeButtonState();
}

class _AnimatedLikeButtonState extends State<AnimatedLikeButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onLikeChanged(bool newIsLiked) {
    if (newIsLiked) {
      _controller.forward().then((_) => _controller.reverse());
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: LikeButton(
        entityType: widget.entityType,
        entityId: widget.entityId,
        isLiked: widget.isLiked,
        likesCount: widget.likesCount,
        size: widget.size,
        showCount: widget.showCount,
        likedColor: widget.likedColor,
        unlikedColor: widget.unlikedColor,
        onLikeChanged: _onLikeChanged,
      ),
    );
  }
}
