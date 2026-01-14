/// Unified Competition Card Widget
/// Ultra-simplified version with description always visible
/// Following Monolith-by-Features architecture (ADR-005).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/helpers/responsive/responsive.dart';
import '../../../core/widgets/images/optimized_image.dart';
import '../../../core/widgets/my_text.dart';
import '../competition_routes.dart';
import '../models/competition.dart';
import 'competition_status_badge.dart';

/// Layout type for competition card
enum CompetitionCardLayout {
  /// Simple card with basic info
  simple,

  /// List view card with detailed info
  list,

  /// Grid view card (compact)
  grid,
}

/// Unified competition card widget - displays competition info in different layouts
class UnifiedCompetitionCard extends StatelessWidget {
  const UnifiedCompetitionCard({
    super.key,
    required this.competition,
    this.layout = CompetitionCardLayout.simple,
    this.onTap,
    this.isCompact = false,
    this.showBanner = true,
  });

  final Competition competition;
  final CompetitionCardLayout layout;
  final VoidCallback? onTap;
  final bool isCompact;
  final bool showBanner;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final borderRadius = ResponsiveBreakpoints.getBorderRadius(screenWidth);
    final spacing = ResponsiveBreakpoints.getSpacing(screenWidth);
    final isMobile = ResponsiveBreakpoints.isMobile(screenWidth);

    // Determine layout parameters
    final bool isGridLayout = layout == CompetitionCardLayout.grid;
    final bool isListLayout = layout == CompetitionCardLayout.list;
    final double cardPadding = isCompact ? 12 : 16;

    return Card(
      margin: EdgeInsets.only(bottom: isListLayout ? spacing : 16),
      elevation: competition.isLive ? 4 : 2,
      clipBehavior: isGridLayout ? Clip.antiAlias : Clip.none,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isGridLayout ? borderRadius : 12),
        side: competition.isLive && !isGridLayout
            ? const BorderSide(color: Colors.green, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _handleTap(context),
        borderRadius: BorderRadius.circular(isGridLayout ? borderRadius : 12),
        child: isGridLayout
            ? _buildGridLayout(context, theme, isMobile)
            : _buildVerticalLayout(context, theme, cardPadding, borderRadius),
      ),
    );
  }

  /// Grid layout (image on top, content below)
  Widget _buildGridLayout(
    BuildContext context,
    ThemeData theme,
    bool isMobile,
  ) {
    final (statusColor, statusIcon) = _getStatusStyle(competition.status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image section with status badge overlay
        Expanded(
          flex: 2,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildBanner(context),
              Positioned(
                top: 8,
                right: 8,
                child: _buildCompactStatusBadge(statusColor, statusIcon),
              ),
            ],
          ),
        ),
        // Content section
        Expanded(
          flex: 3,
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 10 : 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                MyText(
                  competition.title,
                  istitle: true,
                  maxLines: 1,
                  style: TextStyle(fontSize: isMobile ? 14 : 16),
                ),
                const SizedBox(height: 4),
                // Description - ALWAYS SHOWN
                if (competition.description.isNotEmpty)
                  Expanded(
                    child: MyText(
                      competition.description,
                      selectable: false,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                const Spacer(),
                // Date
                _buildDateRow(
                  context,
                  shortFormat: true,
                  iconSize: isMobile ? 12 : 14,
                ),
                const SizedBox(height: 4),
                // Participants & Fee
                _buildStatsRow(
                  context,
                  compact: true,
                  fontSize: isMobile ? 11 : 13,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Vertical layout (for simple and list)
  Widget _buildVerticalLayout(
    BuildContext context,
    ThemeData theme,
    double padding,
    double borderRadius,
  ) {
    final bool shouldShowBanner =
        showBanner && (layout != CompetitionCardLayout.list || !isCompact);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Banner
        if (shouldShowBanner)
          _buildBanner(
            context,
            height: layout == CompetitionCardLayout.simple ? 140 : null,
            aspectRatio: layout == CompetitionCardLayout.list ? 21 / 9 : null,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(borderRadius),
            ),
          ),
        // Content
        Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title & Status
              Row(
                children: [
                  Expanded(
                    child: MyText(
                      competition.title,
                      istitle: true,
                   
                      selectable: false,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  CompetitionStatusBadge(status: competition.status),
                ],
              ),
              // Description - ALWAYS SHOWN
              if (competition.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                MyText(
                  competition.description,
                  selectable: false,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              // Discipline & Format chips (only in list mode)
              if (layout == CompetitionCardLayout.list &&
                  (competition.discipline != null ||
                      competition.format != null))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Wrap(
                    spacing: 8,
                    children: [
                      if (competition.discipline != null)
                        Chip(
                          label: MyText(competition.discipline!.toUpperCase()),
                          visualDensity: VisualDensity.compact,
                        ),
                      if (competition.format != null)
                        Chip(
                          label: MyText(competition.format!),
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                ),
              // Date
              _buildDateRow(context),
              // Location
              if (competition.venue != null || competition.city != null) ...[
                const SizedBox(height: 6),
                _buildLocationRow(context),
              ],
              const SizedBox(height: 12),
              // Stats
              if (layout == CompetitionCardLayout.list)
                _buildStatsRowDetailed(context)
              else
                Row(
                  children: [
                    Expanded(child: _buildParticipantsRow(context)),
                    if (competition.category != null)
                      _buildCategoryChip(context),
                  ],
                ),
              // Live indicator
              if (competition.isLive) _buildLiveIndicator(),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // SHARED COMPONENTS
  // ===========================================================================

  Widget _buildBanner(
    BuildContext context, {
    double? height,
    double? aspectRatio,
    BorderRadius? borderRadius,
  }) {
    if (!showBanner) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final imageUrl =
        competition.bannerUrl ??
        (competition.imageUrls?.isNotEmpty == true
            ? competition.imageUrls!.first
            : null);

    Widget banner = imageUrl != null
        ? OptimizedImage(
            imageUrl: imageUrl,
            height: height,
            width: double.infinity,
            fit: BoxFit.cover,
            semanticLabel: 'Banner de ${competition.title}',
            errorWidget: _buildPlaceholder(theme),
            placeholder: _buildPlaceholder(theme),
          )
        : _buildPlaceholder(theme);

    if (aspectRatio != null) {
      banner = AspectRatio(aspectRatio: aspectRatio, child: banner);
    }

    if (borderRadius != null) {
      banner = ClipRRect(borderRadius: borderRadius, child: banner);
    }

    return banner;
  }

  Widget _buildPlaceholder(ThemeData theme) {
    return ColoredBox(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.emoji_events,
        size: 50,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildDateRow(
    BuildContext context, {
    bool shortFormat = false,
    double iconSize = 16,
  }) {
    final theme = Theme.of(context);
    final formatter = DateFormat(shortFormat ? 'dd MMM' : 'dd MMM yyyy');
    final start = formatter.format(competition.startDate);
    final end = formatter.format(competition.endDate);
    final dateText = shortFormat
        ? start
        : (start == end ? start : '$start - $end');

    return Row(
      children: [
        Icon(
          Icons.calendar_today,
          size: iconSize,
          color: theme.colorScheme.primary.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            dateText,
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationRow(BuildContext context) {
    final theme = Theme.of(context);
    final location = [
      competition.venue,
      competition.city,
      if (competition.venue == null && competition.city == null)
        competition.country,
    ].whereType<String>().join(', ');

    if (location.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        Icon(
          Icons.location_on,
          size: 16,
          color: theme.colorScheme.primary.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            location,
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildParticipantsRow(BuildContext context, {bool compact = false}) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(
          Icons.people,
          size: compact ? 14 : 16,
          color: theme.colorScheme.primary.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 4),
        MyText(
          '${competition.currentParticipants}/${competition.maxParticipants}',
          selectable: false,
          style: TextStyle(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: compact ? 12 : 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(
    BuildContext context, {
    bool compact = false,
    double fontSize = 13,
  }) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildParticipantsRow(context, compact: compact),
        if (competition.entryFee != null)
          Flexible(
            child: MyText(
              '${competition.entryFee} ${competition.currency ?? ""}',
              color: theme.colorScheme.primary,
              istitle: true,
              style: TextStyle(fontSize: fontSize),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }

  Widget _buildStatsRowDetailed(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatColumn(
          theme,
          Icons.people,
          '${competition.currentParticipants}/${competition.maxParticipants}',
        ),
        _buildStatColumn(
          theme,
          Icons.sports_score,
          '${competition.totalRounds}',
        ),
        if (competition.entryFee != null)
          _buildStatColumn(
            theme,
            Icons.attach_money,
            '${competition.entryFee} ${competition.currency ?? ""}',
          ),
      ],
    );
  }

  Widget _buildStatColumn(ThemeData theme, IconData icon, String value) {
    return Column(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(height: 4),
        MyText(value, selectable: false),
      ],
    );
  }

  Widget _buildCategoryChip(BuildContext context) {
    if (competition.category == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.primaryColor.withAlpha(26),
        borderRadius: BorderRadius.circular(8),
      ),
      child: MyText(
        competition.category!,
        selectable: false,
        style: TextStyle(
          color: theme.primaryColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCompactStatusBadge(Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: Colors.white),
          const SizedBox(width: 4),
          MyText(
            competition.status.toUpperCase(),
            selectable: false,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveIndicator() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'Competición en vivo',
            style: TextStyle(
              color: Colors.red,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // HELPERS
  // ===========================================================================

  void _handleTap(BuildContext context) {
    if (onTap != null) {
      onTap!();
    } else {
      context.push(CompetitionRoutes.getCompetitionDetail(competition.id));
    }
  }

  (Color, IconData) _getStatusStyle(String status) {
    return switch (status) {
      'live' => (Colors.red, Icons.circle),
      'upcoming' => (Colors.blue, Icons.schedule),
      'completed' => (Colors.green, Icons.check_circle),
      _ => (Colors.grey, Icons.info),
    };
  }
}
