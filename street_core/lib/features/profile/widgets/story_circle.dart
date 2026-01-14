// lib/features/profile/widgets/story_circle.dart

import 'package:flutter/material.dart';

/// Widget showing a circular avatar with a colored border for stories
/// Used in profile pages to display user stories
class StoryCircle extends StatelessWidget {
  const StoryCircle({
    required this.userId,
    required this.profilePicture,
    required this.hasStory,
    this.viewed = false,
    this.size = 60.0,
    this.borderWidth = 2.5,
    this.onTap,
    super.key,
  });

  final String userId;
  final String profilePicture;
  final bool hasStory;
  final bool viewed;
  final double size;
  final double borderWidth;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: hasStory
              ? LinearGradient(
                  colors: viewed
                      ? [Colors.grey.shade400, Colors.grey.shade600]
                      : [
                          theme.primaryColor,
                          theme.primaryColorLight,
                          theme.colorScheme.secondary,
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          border: !hasStory
              ? Border.all(
                  color: Colors.grey.shade300,
                  width: 1.0,
                )
              : null,
        ),
        padding: EdgeInsets.all(borderWidth),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: theme.scaffoldBackgroundColor,
              width: 2.0,
            ),
          ),
          child: ClipOval(
            child: profilePicture.isNotEmpty
                ? Image.network(
                    profilePicture,
                    fit: BoxFit.cover,
                    width: size - (borderWidth * 2) - 4,
                    height: size - (borderWidth * 2) - 4,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildPlaceholder(theme);
                    },
                  )
                : _buildPlaceholder(theme),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(ThemeData theme) {
    return Container(
      width: size - (borderWidth * 2) - 4,
      height: size - (borderWidth * 2) - 4,
      color: Colors.grey.shade300,
      child: Icon(
        Icons.person,
        size: (size - (borderWidth * 2) - 4) * 0.6,
        color: Colors.grey.shade600,
      ),
    );
  }
}
