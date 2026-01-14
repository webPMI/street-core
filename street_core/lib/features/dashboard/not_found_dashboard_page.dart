import 'package:street_core/features/competitions/competition_routes.dart';
import 'package:street_core/features/profile/profile_routes.dart';

import '../../../core/helpers/responsive/responsive_builder.dart';
import '../../../core/lang/context_tr.dart';
import '../../../core/lang/locale_keys.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/widgets/my_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth.dart';

/// 404 Page for Dashboard Layout (authenticated users)
///
/// Features:
/// - Shows user information (avatar, name)
/// - Quick navigation links
/// - Professional yet fun design
/// - Responsive design (mobile, tablet, desktop)
/// - Compatible with all 8 theme variants
class NotFoundDashboardPage extends StatefulWidget {
  const NotFoundDashboardPage({super.key});

  @override
  State<NotFoundDashboardPage> createState() => _NotFoundDashboardPageState();
}

class _NotFoundDashboardPageState extends State<NotFoundDashboardPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isMobile = context.isMobile;
    final isTablet = context.isTablet;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.error_outline),
            const SizedBox(width: 8),
            const MyText(LocaleKeys.appTitle),
          ],
        ),
      ),
      //  drawer: MyDrawer(),
      body: BlocBuilder<UserCubit, UserState>(
        builder: (context, userState) {
          final userName = userState is UserLoaded
              ? (userState.user.firstName.isNotEmpty
                    ? userState.user.firstName
                    : context.tr(LocaleKeys.userDefaultName))
              : context.tr(LocaleKeys.userDefaultName);

          return Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 20 : 40),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon with animation
                        TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 1500),
                          tween: Tween(begin: 0.0, end: 1.0),
                          curve: Curves.elasticOut,
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: value,
                              child: Container(
                                padding: EdgeInsets.all(isMobile ? 24 : 32),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: colorScheme.primary.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.explore_off_rounded,
                                  size: isMobile ? 60 : (isTablet ? 80 : 100),
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              ),
                            );
                          },
                        ),

                        SizedBox(height: isMobile ? 24 : 32),

                        // 404 Code
                        MyText(
                          '404',
                          style: theme.textTheme.displayLarge?.copyWith(
                            fontSize: isMobile ? 72 : (isTablet ? 96 : 120),
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                            height: 1.0,
                          ),
                        ),

                        SizedBox(height: isMobile ? 12 : 16),

                        // Personalized greeting
                        MyText(
                          context
                              .tr('page.not.found')
                              .replaceAll('{name}', userName),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontSize: isMobile ? 24 : 28,
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 8),

                        SizedBox(height: isMobile ? 16 : 20),

                        // Fun message
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 0 : 40,
                          ),
                          child: Text(
                            context.tr(LocaleKeys.pageNotFoundMessage),
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontSize: isMobile ? 14 : 16,
                              color: colorScheme.onSurfaceVariant,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                        SizedBox(height: isMobile ? 32 : 40),

                        // Quick Links Grid
                        SizedBox(
                          child: _QuickLinksGrid(
                            isMobile: isMobile,
                            isTablet: isTablet,
                          ),
                        ),

                        SizedBox(height: isMobile ? 32 : 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ============================================================================
// QUICK LINKS GRID
// ============================================================================

class _QuickLinksGrid extends StatelessWidget {
  const _QuickLinksGrid({required this.isMobile, required this.isTablet});

  final bool isMobile;
  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    final quickLinks = [
      _QuickLinkData(
        icon: Icons.dashboard_rounded,
        labelKey: 'dashboard',
        route: AppRoutes.dashboard,
      ),
      _QuickLinkData(
        icon: Icons.emoji_events_rounded,
        labelKey: 'competitions',
        route: CompetitionRoutes.competitionsList,
      ),
      _QuickLinkData(
        icon: Icons.person_rounded,
        labelKey: 'profile',
        route: ProfileRoutes.profile,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = isMobile ? 2 : 4;
        final childAspectRatio = isMobile ? 1.2 : 1.3;

        return Center(
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: childAspectRatio,
              crossAxisSpacing: isMobile ? 12 : 16,
              mainAxisSpacing: isMobile ? 12 : 16,
            ),
            itemCount: quickLinks.length,

            itemBuilder: (context, index) {
              return TweenAnimationBuilder<double>(
                duration: Duration(milliseconds: 1400 + (index * 100)),
                tween: Tween(begin: 0.0, end: 1.0),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.scale(
                      scale: 0.8 + (0.2 * value),
                      child: _QuickLinkCard(
                        data: quickLinks[index],
                        isMobile: isMobile,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

// ============================================================================
// QUICK LINK CARD
// ============================================================================

class _QuickLinkCard extends StatefulWidget {
  const _QuickLinkCard({required this.data, required this.isMobile});

  final _QuickLinkData data;
  final bool isMobile;

  @override
  State<_QuickLinkCard> createState() => _QuickLinkCardState();
}

class _QuickLinkCardState extends State<_QuickLinkCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: _isHovered
            ? Matrix4.translationValues(0.0, -4.0, 0.0)
            : Matrix4.identity(),
        child: Material(
          color: _isHovered
              ? colorScheme.secondaryContainer
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          elevation: _isHovered ? 8 : 2,
          shadowColor: colorScheme.shadow.withValues(alpha: 0.2),
          child: InkWell(
            onTap: () => context.go(widget.data.route),
            borderRadius: BorderRadius.circular(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.data.icon,
                  size: widget.isMobile ? 32 : 40,
                  color: _isHovered
                      ? colorScheme.onSecondaryContainer
                      : colorScheme.primary,
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr(widget.data.labelKey),
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontSize: widget.isMobile ? 12 : 14,
                    color: _isHovered
                        ? colorScheme.onSecondaryContainer
                        : colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// DATA MODELS
// ============================================================================

class _QuickLinkData {
  final IconData icon;
  final String labelKey;
  final String route;

  _QuickLinkData({
    required this.icon,
    required this.labelKey,
    required this.route,
  });
}
