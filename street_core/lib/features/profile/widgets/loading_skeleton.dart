// lib/features/profile/widgets/loading_skeleton.dart

import 'package:flutter/material.dart';

/// Loading skeleton widget with shimmer effect
/// Used to show loading placeholders for content
class LoadingSkeleton extends StatefulWidget {
  const LoadingSkeleton({
    this.width = double.infinity,
    this.height = 20.0,
    this.borderRadius,
    this.baseColor,
    this.highlightColor,
    super.key,
  });

  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final Color? baseColor;
  final Color? highlightColor;

  @override
  State<LoadingSkeleton> createState() => _LoadingSkeletonState();
}

class _LoadingSkeletonState extends State<LoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.baseColor ?? Colors.grey.shade300;
    final highlightColor = widget.highlightColor ?? Colors.grey.shade100;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(4.0),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ].map((stop) => stop.clamp(0.0, 1.0)).toList(),
            ),
          ),
        );
      },
    );
  }
}

/// Shimmer container for complex loading layouts
class ShimmerContainer extends StatelessWidget {
  const ShimmerContainer({
    required this.child,
    this.enabled = true,
    super.key,
  });

  final Widget child;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return child;
    }

    return AnimatedOpacity(
      opacity: 0.6,
      duration: const Duration(milliseconds: 500),
      child: child,
    );
  }
}

/// Pre-built skeleton layouts
class ProfileSkeletonLoader extends StatelessWidget {
  const ProfileSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        // Profile picture skeleton
        const LoadingSkeleton(
          width: 100,
          height: 100,
          borderRadius: BorderRadius.all(Radius.circular(50)),
        ),
        const SizedBox(height: 16),
        // Name skeleton
        const LoadingSkeleton(width: 150, height: 20),
        const SizedBox(height: 8),
        // Username skeleton
        LoadingSkeleton(
          width: 100,
          height: 14,
          baseColor: Colors.grey.shade200,
        ),
        const SizedBox(height: 16),
        // Stats skeleton
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(
            3,
            (index) => Column(
              children: const [
                LoadingSkeleton(width: 60, height: 24),
                SizedBox(height: 4),
                LoadingSkeleton(width: 80, height: 14),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class PostGridSkeletonLoader extends StatelessWidget {
  const PostGridSkeletonLoader({this.itemCount = 9, super.key});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return const LoadingSkeleton(
          width: double.infinity,
          height: double.infinity,
          borderRadius: BorderRadius.zero,
        );
      },
    );
  }
}

class PostCardSkeletonLoader extends StatelessWidget {
  const PostCardSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const LoadingSkeleton(
                width: 40,
                height: 40,
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  LoadingSkeleton(width: 120, height: 14),
                  SizedBox(height: 4),
                  LoadingSkeleton(width: 80, height: 12),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Image
          const LoadingSkeleton(
            width: double.infinity,
            height: 300,
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          const SizedBox(height: 12),
          // Actions
          Row(
            children: const [
              LoadingSkeleton(width: 24, height: 24),
              SizedBox(width: 16),
              LoadingSkeleton(width: 24, height: 24),
              SizedBox(width: 16),
              LoadingSkeleton(width: 24, height: 24),
            ],
          ),
          const SizedBox(height: 8),
          // Caption
          const LoadingSkeleton(width: double.infinity, height: 14),
          const SizedBox(height: 4),
          const LoadingSkeleton(width: 200, height: 14),
        ],
      ),
    );
  }
}
