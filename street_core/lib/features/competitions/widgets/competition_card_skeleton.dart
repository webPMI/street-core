/// Widget de Skeleton Loading para Tarjetas de Competición
/// Muestra un shimmer effect mientras se cargan las competiciones.
/// Siguiendo la arquitectura Monolith-by-Features (ADR-005).

import 'package:flutter/material.dart';

class CompetitionCardSkeleton extends StatefulWidget {
  const CompetitionCardSkeleton({super.key});

  @override
  State<CompetitionCardSkeleton> createState() =>
      _CompetitionCardSkeletonState();
}

class _CompetitionCardSkeletonState extends State<CompetitionCardSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _shimmerAnimation = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return SizedBox(
          width: 400,
          height: 450,
          child: Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Image skeleton
                Expanded(
                  flex: 1,
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              theme.colorScheme.surfaceContainerHighest,
                              theme.colorScheme.surfaceContainerHigh,
                            ],
                            transform: GradientRotation(
                              _shimmerAnimation.value,
                            ),
                          ),
                        ),
                      ),
                      // Shimmer overlay
                      Positioned.fill(
                        child: ClipRect(
                          child: Transform.translate(
                            offset: Offset(_shimmerAnimation.value * 200, 0),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    Colors.white.withValues(alpha: 0.2),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 0.5, 1.0],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Badge placeholders
                      Positioned(
                        top: 12,
                        right: 12,
                        child: _buildSkeletonBox(
                          width: 80,
                          height: 28,
                          theme: theme,
                        ),
                      ),
                      Positioned(
                        top: 12,
                        left: 12,
                        child: _buildSkeletonBox(
                          width: 70,
                          height: 28,
                          theme: theme,
                        ),
                      ),
                    ],
                  ),
                ),

                // Info skeleton
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title placeholder
                            _buildSkeletonBox(
                              width: double.infinity,
                              height: 20,
                              theme: theme,
                            ),
                            const SizedBox(height: 8),
                            _buildSkeletonBox(
                              width: 150,
                              height: 16,
                              theme: theme,
                            ),
                            const SizedBox(height: 12),
                            // Location placeholder
                            _buildSkeletonBox(
                              width: 120,
                              height: 14,
                              theme: theme,
                            ),
                          ],
                        ),
                        // Stats row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildSkeletonBox(
                              width: 80,
                              height: 32,
                              theme: theme,
                            ),
                            _buildSkeletonBox(
                              width: 90,
                              height: 32,
                              theme: theme,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSkeletonBox({
    required double width,
    required double height,
    required ThemeData theme,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
