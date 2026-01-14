// lib/features/livestreams/widgets/live_badge.dart

import 'package:flutter/material.dart';

/// Reusable "LIVE" badge widget
///
/// Usage:
/// ```dart
/// LiveBadge()
/// LiveBadge(size: BadgeSize.large, animated: true)
/// LiveBadge.compact()
/// ```
class LiveBadge extends StatefulWidget {
  final BadgeSize size;
  final bool animated;
  final Color? color;
  final Color? textColor;

  const LiveBadge({
    super.key,
    this.size = BadgeSize.medium,
    this.animated = true,
    this.color,
    this.textColor,
  });

  /// Compact version (small size, no animation)
  const LiveBadge.compact({
    super.key,
    this.size = BadgeSize.small,
    this.animated = false,
    this.color,
    this.textColor,
  });

  /// Large version with animation
  const LiveBadge.large({
    super.key,
    this.size = BadgeSize.large,
    this.animated = true,
    this.color,
    this.textColor,
  });

  @override
  State<LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<LiveBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.animated) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final badgeColor = widget.color ?? Colors.red;
    final badgeTextColor = widget.textColor ?? Colors.white;

    return AnimatedBuilder(
      animation: _opacityAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: widget.animated ? _opacityAnimation.value : 1.0,
          child: Container(
            padding: _getPadding(),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(_getBorderRadius()),
              boxShadow: [
                BoxShadow(
                  color: badgeColor.withValues(alpha: 0.5),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Pulsing dot
                if (widget.size != BadgeSize.small) ...[
                  Container(
                    width: _getDotSize(),
                    height: _getDotSize(),
                    decoration: BoxDecoration(
                      color: badgeTextColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: _getSpacing()),
                ],
                // Text
                Text(
                  'EN VIVO',
                  style: TextStyle(
                    color: badgeTextColor,
                    fontSize: _getFontSize(),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  EdgeInsets _getPadding() {
    switch (widget.size) {
      case BadgeSize.small:
        return const EdgeInsets.symmetric(horizontal: 6, vertical: 2);
      case BadgeSize.medium:
        return const EdgeInsets.symmetric(horizontal: 8, vertical: 4);
      case BadgeSize.large:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
    }
  }

  double _getBorderRadius() {
    switch (widget.size) {
      case BadgeSize.small:
        return 4;
      case BadgeSize.medium:
        return 6;
      case BadgeSize.large:
        return 8;
    }
  }

  double _getDotSize() {
    switch (widget.size) {
      case BadgeSize.small:
        return 4;
      case BadgeSize.medium:
        return 6;
      case BadgeSize.large:
        return 8;
    }
  }

  double _getSpacing() {
    switch (widget.size) {
      case BadgeSize.small:
        return 3;
      case BadgeSize.medium:
        return 4;
      case BadgeSize.large:
        return 6;
    }
  }

  double _getFontSize() {
    switch (widget.size) {
      case BadgeSize.small:
        return 10;
      case BadgeSize.medium:
        return 12;
      case BadgeSize.large:
        return 14;
    }
  }
}

enum BadgeSize { small, medium, large }
