// lib/features/livestreams/widgets/floating_reactions_overlay.dart

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:street_core/features/livestreams/models/models.dart';

/// Floating reactions overlay with animations
///
/// Shows reactions floating up the screen with physics-based animations.
///
/// Usage:
/// ```dart
/// FloatingReactionsOverlay(
///   reactions: reactionsList,
/// )
/// ```
class FloatingReactionsOverlay extends StatelessWidget {
  final List<AnimatedReaction> reactions;
  final Duration animationDuration;

  const FloatingReactionsOverlay({
    super.key,
    required this.reactions,
    this.animationDuration = const Duration(milliseconds: 3000),
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: reactions
            .where((reaction) => !reaction.isExpired)
            .map(
              (reaction) => _FloatingReaction(
                reaction: reaction,
                animationDuration: animationDuration,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _FloatingReaction extends StatefulWidget {
  final AnimatedReaction reaction;
  final Duration animationDuration;

  const _FloatingReaction({
    required this.reaction,
    required this.animationDuration,
  });

  @override
  State<_FloatingReaction> createState() => _FloatingReactionState();
}

class _FloatingReactionState extends State<_FloatingReaction>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _positionAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;
  late double _randomX;
  late double _randomRotation;

  @override
  void initState() {
    super.initState();

    // Random values for variation
    final random = Random();
    _randomX = (random.nextDouble() - 0.5) * 100; // -50 to 50
    _randomRotation = (random.nextDouble() - 0.5) * 0.5; // -0.25 to 0.25 radians

    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    // Position animation (move up)
    _positionAnimation = Tween<double>(
      begin: 0.0,
      end: -300.0, // Move up 300 pixels
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    // Opacity animation (fade out towards the end)
    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        weight: 10,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.0),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0),
        weight: 30,
      ),
    ]).animate(_controller);

    // Scale animation (pulse effect)
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.5, end: 1.2),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.0),
        weight: 60,
      ),
    ]).animate(_controller);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          left: widget.reaction.x + _randomX * _controller.value,
          top: widget.reaction.y + _positionAnimation.value,
          child: Transform.rotate(
            angle: _randomRotation * _controller.value,
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Text(
                  widget.reaction.emoji,
                  style: const TextStyle(
                    fontSize: 32,
                    shadows: [
                      Shadow(
                        blurRadius: 4,
                        color: Colors.black26,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Reaction burst effect (multiple reactions at once)
///
/// Usage:
/// ```dart
/// ReactionBurst(
///   type: ReactionType.heart,
///   count: 5,
///   centerX: tapX,
///   centerY: tapY,
/// )
/// ```
class ReactionBurst extends StatefulWidget {
  final ReactionType type;
  final int count;
  final double centerX;
  final double centerY;
  final Duration burstDuration;

  const ReactionBurst({
    super.key,
    required this.type,
    this.count = 5,
    required this.centerX,
    required this.centerY,
    this.burstDuration = const Duration(milliseconds: 500),
  });

  @override
  State<ReactionBurst> createState() => _ReactionBurstState();
}

class _ReactionBurstState extends State<ReactionBurst>
    with TickerProviderStateMixin {
  final List<AnimationController> _controllers = [];
  final List<Animation<Offset>> _offsetAnimations = [];
  final List<Animation<double>> _opacityAnimations = [];

  @override
  void initState() {
    super.initState();

    final random = Random();

    for (var i = 0; i < widget.count; i++) {
      final controller = AnimationController(
        duration: widget.burstDuration,
        vsync: this,
      );

      // Random direction for burst
      final angle = (2 * pi * i) / widget.count + random.nextDouble() * 0.5;
      final distance = 50.0 + random.nextDouble() * 50.0;
      final dx = cos(angle) * distance;
      final dy = sin(angle) * distance;

      final offsetAnimation = Tween<Offset>(
        begin: Offset.zero,
        end: Offset(dx, dy),
      ).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.easeOut,
        ),
      );

      final opacityAnimation = Tween<double>(
        begin: 1.0,
        end: 0.0,
      ).animate(
        CurvedAnimation(
          parent: controller,
          curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
        ),
      );

      _controllers.add(controller);
      _offsetAnimations.add(offsetAnimation);
      _opacityAnimations.add(opacityAnimation);

      controller.forward();
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: List.generate(
        widget.count,
        (index) => AnimatedBuilder(
          animation: _controllers[index],
          builder: (context, child) {
            final offset = _offsetAnimations[index].value;
            return Positioned(
              left: widget.centerX + offset.dx,
              top: widget.centerY + offset.dy,
              child: Opacity(
                opacity: _opacityAnimations[index].value,
                child: Text(
                  widget.type.emoji,
                  style: const TextStyle(
                    fontSize: 24,
                    shadows: [
                      Shadow(
                        blurRadius: 4,
                        color: Colors.black26,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
