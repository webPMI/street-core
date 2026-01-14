// lib/features/livestreams/widgets/stream_reaction_button.dart

import 'package:flutter/material.dart';
import 'package:street_core/features/livestreams/models/models.dart';

/// Reusable reaction button widget
///
/// Usage:
/// ```dart
/// StreamReactionButton(
///   type: ReactionType.heart,
///   onTap: () => sendReaction(ReactionType.heart),
/// )
///
/// StreamReactionButton.compact(
///   type: ReactionType.fire,
///   onTap: () => sendReaction(ReactionType.fire),
/// )
/// ```
class StreamReactionButton extends StatefulWidget {
  final ReactionType type;
  final VoidCallback? onTap;
  final bool isCompact;
  final bool showLabel;
  final Color? backgroundColor;
  final double? size;

  const StreamReactionButton({
    super.key,
    required this.type,
    this.onTap,
    this.isCompact = false,
    this.showLabel = true,
    this.backgroundColor,
    this.size,
  });

  /// Compact version (no label)
  const StreamReactionButton.compact({
    super.key,
    required this.type,
    this.onTap,
    this.backgroundColor,
    this.size,
  })  : isCompact = true,
        showLabel = false;

  @override
  State<StreamReactionButton> createState() => _StreamReactionButtonState();
}

class _StreamReactionButtonState extends State<StreamReactionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    setState(() => _isPressed = true);
    _controller.forward().then((_) {
      _controller.reverse();
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          setState(() => _isPressed = false);
        }
      });
    });
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size ?? (widget.isCompact ? 40.0 : 50.0);
    final backgroundColor = widget.backgroundColor ??
        Theme.of(context).colorScheme.surface.withValues(alpha: 0.9);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ScaleTransition(
          scale: _scaleAnimation,
          child: Material(
            color: backgroundColor,
            shape: const CircleBorder(),
            elevation: _isPressed ? 8 : 4,
            child: InkWell(
              onTap: _handleTap,
              customBorder: const CircleBorder(),
              child: Container(
                width: size,
                height: size,
                alignment: Alignment.center,
                child: Text(
                  widget.type.emoji,
                  style: TextStyle(
                    fontSize: size * 0.5,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (widget.showLabel && !widget.isCompact) ...[
          const SizedBox(height: 4),
          Text(
            widget.type.displayName,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

/// Reaction bar with all reaction types
///
/// Usage:
/// ```dart
/// StreamReactionBar(
///   onReaction: (type) => sendReaction(type),
/// )
/// ```
class StreamReactionBar extends StatelessWidget {
  final Function(ReactionType) onReaction;
  final bool isCompact;
  final Axis direction;
  final List<ReactionType> reactions;

  const StreamReactionBar({
    super.key,
    required this.onReaction,
    this.isCompact = false,
    this.direction = Axis.horizontal,
    this.reactions = const [
      ReactionType.heart,
      ReactionType.fire,
      ReactionType.thumbsup,
      ReactionType.clap,
      ReactionType.star,
    ],
  });

  @override
  Widget build(BuildContext context) {
    final buttons = reactions
        .map(
          (type) => StreamReactionButton(
            type: type,
            onTap: () => onReaction(type),
            isCompact: isCompact,
            showLabel: !isCompact,
          ),
        )
        .toList();

    if (direction == Axis.horizontal) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: _intersperse(
          buttons,
          const SizedBox(width: 8),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: _intersperse(
        buttons,
        const SizedBox(height: 8),
      ),
    );
  }

  List<Widget> _intersperse(List<Widget> widgets, Widget separator) {
    if (widgets.isEmpty) return [];

    final result = <Widget>[widgets.first];
    for (var i = 1; i < widgets.length; i++) {
      result.add(separator);
      result.add(widgets[i]);
    }
    return result;
  }
}
