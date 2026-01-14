import '../../../core/seo/seo_meta_tags.dart';
import '../models/competition.dart';
import 'package:flutter/material.dart';

/// Widget that wraps competition pages with SEO metadata
///
/// This widget automatically updates page meta tags when the competition
/// data changes, ensuring proper SEO and social media sharing previews.
///
/// Usage:
/// ```dart
/// CompetitionSEOWrapper(
///   competition: competition,
///   child: CompetitionDetailsPage(competition: competition),
/// )
/// ```
class CompetitionSEOWrapper extends StatefulWidget {

  const CompetitionSEOWrapper({
    super.key,
    required this.competition,
    required this.child,
    this.baseUrl = 'https://fitriders.com',
  });
  final Competition competition;
  final Widget child;
  final String? baseUrl;

  @override
  State<CompetitionSEOWrapper> createState() => _CompetitionSEOWrapperState();
}

class _CompetitionSEOWrapperState extends State<CompetitionSEOWrapper> {
  @override
  void initState() {
    super.initState();
    _updateSEOMetadata();
  }

  @override
  void didUpdateWidget(CompetitionSEOWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.competition.id != widget.competition.id) {
      _updateSEOMetadata();
    }
  }

  void _updateSEOMetadata() {
    final comp = widget.competition;

    // Generate optimized title (50-60 chars)
    final title = _generateTitle(comp);

    // Generate optimized description (150-160 chars)
    final description = _generateDescription(comp);

    // Generate canonical URL
    final canonicalUrl = _generateCanonicalUrl(comp);

    // Generate keywords
    final keywords = _generateKeywords(comp);

    // Select best image
    final imageUrl =
        comp.bannerUrl ??
        (comp.imageUrls?.isNotEmpty ?? false ? comp.imageUrls!.first : null);

    // Update meta tags
    SEOMetaTags.updateCompetitionMeta(
      title: title,
      description: description,
      canonicalUrl: canonicalUrl,
      imageUrl: imageUrl,
      keywords: keywords,
    );

    // Add structured data
    final structuredData = CompetitionStructuredData.generateSportsEvent(
      id: '${widget.baseUrl}/competitions/${comp.id}',
      name: comp.title,
      description: comp.description,
      startDate: comp.startDate,
      endDate: comp.endDate,
      venue: comp.venue,
      city: comp.city,
      country: comp.country,
      imageUrl: imageUrl,
      organizerName: comp.organizerName,
      status: comp.status,
    );

    SEOMetaTags.addStructuredData(structuredData);

    // Add breadcrumb structured data
    final breadcrumbs = CompetitionStructuredData.generateBreadcrumbs(
      baseUrl: widget.baseUrl!,
      items: [
        BreadcrumbItem(name: 'Home', url: '/'),
        BreadcrumbItem(name: 'Competitions', url: '/competitions'),
        BreadcrumbItem(name: comp.title, url: '/competitions/${comp.id}'),
      ],
    );

    SEOMetaTags.addStructuredData(breadcrumbs);
  }

  String _generateTitle(Competition comp) {
    // Format: "[Competition Name] - [Discipline] | Street Core"
    final baseTitle = '${comp.title} - ${comp.discipline ?? "Competition"}';
    final fullTitle = '$baseTitle | Street Core';

    // Ensure optimal length (50-60 chars)
    if (fullTitle.length > 60) {
      final shortened = baseTitle.length > 47
          ? '${baseTitle.substring(0, 47)}...'
          : baseTitle;
      return '$shortened | Street Core';
    }

    return fullTitle;
  }

  String _generateDescription(Competition comp) {
    final description = StringBuffer();

    // Start with competition type and status
    if (comp.competitionType != null) {
      description.write('${_formatCompetitionType(comp.competitionType!)} ');
    }
    description.write(comp.discipline ?? 'Competition');

    // Add location if available
    if (comp.city != null && comp.country != null) {
      description.write(' in ${comp.city}, ${comp.country}');
    } else if (comp.city != null) {
      description.write(' in ${comp.city}');
    }

    // Add date info
    final dateStr = _formatDateRange(comp.startDate, comp.endDate);
    description.write(' on $dateStr');

    // Add registration status if relevant
    if (comp.status == 'upcoming' && comp.participantStatus == 'open') {
      description.write('. Registration open');
      if (comp.maxParticipants > 0) {
        final spotsLeft = comp.maxParticipants - comp.currentParticipants;
        if (spotsLeft > 0) {
          description.write(' - $spotsLeft spots left');
        }
      }
    }

    // Add prize info if available
    if (comp.prizePool != null && comp.prizePool!.totalAmount > 0) {
      description.write(
        '. Prize pool: ${comp.prizePool!.currency} ${comp.prizePool!.totalAmount}',
      );
    }

    // Ensure optimal length (150-160 chars)
    final result = description.toString();
    if (result.length > 160) {
      return '${result.substring(0, 157)}...';
    }

    return result;
  }

  String _generateCanonicalUrl(Competition comp) {
    final slug = _generateSlug(comp.title);
    return '${widget.baseUrl}/competitions/${comp.id}/$slug';
  }

  List<String> _generateKeywords(Competition comp) {
    final keywords = <String>['competition', 'sports event', 'street core'];

    // Add discipline
    if (comp.discipline != null && comp.discipline!.isNotEmpty) {
      keywords.add(comp.discipline!.toLowerCase());
    }

    // Add competition type
    if (comp.competitionType != null) {
      keywords.add(comp.competitionType!.toLowerCase());
    }

    // Add discipline
    if (comp.discipline != null && comp.discipline!.isNotEmpty) {
      keywords.add(comp.discipline!.toLowerCase());
    }

    // Add location
    if (comp.city != null && comp.city!.isNotEmpty) {
      keywords.add(comp.city!.toLowerCase());
    }
    if (comp.country != null && comp.country!.isNotEmpty) {
      keywords.add(comp.country!.toLowerCase());
    }

    // Add category
    if (comp.category != null && comp.category!.isNotEmpty) {
      keywords.add(comp.category!.toLowerCase());
    }

    // Add tags
    if (comp.tags != null) {
      keywords.addAll(comp.tags!.map((t) => t.toLowerCase()));
    }

    return keywords.take(10).toList(); // Limit to 10 keywords
  }

  String _formatCompetitionType(String type) {
    switch (type.toLowerCase()) {
      case 'individual':
        return 'Individual';
      case 'team':
        return 'Team';
      case 'both':
        return 'Individual & Team';
      default:
        return type;
    }
  }

  String _formatDateRange(DateTime start, DateTime end) {
    final startStr = '${start.day}/${start.month}/${start.year}';

    // If same day, return single date
    if (start.year == end.year &&
        start.month == end.month &&
        start.day == end.day) {
      return startStr;
    }

    // If same month and year
    if (start.year == end.year && start.month == end.month) {
      return '${start.day}-${end.day}/${start.month}/${start.year}';
    }

    // Full date range
    return '$startStr - ${end.day}/${end.month}/${end.year}';
  }

  String _generateSlug(String title) {
    return title
        .toLowerCase()
        .replaceAll(RegExp('[^a-z0-9]+'), '-')
        .replaceAll(RegExp('-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// List page SEO wrapper
class CompetitionsListSEOWrapper extends StatefulWidget {

  const CompetitionsListSEOWrapper({
    super.key,
    required this.child,
    this.filter,
    this.baseUrl = 'https://fitriders.com',
  });
  final Widget child;
  final String? filter; // e.g., "upcoming", "live"
  final String? baseUrl;

  @override
  State<CompetitionsListSEOWrapper> createState() =>
      _CompetitionsListSEOWrapperState();
}

class _CompetitionsListSEOWrapperState
    extends State<CompetitionsListSEOWrapper> {
  @override
  void initState() {
    super.initState();
    _updateSEOMetadata();
  }

  @override
  void didUpdateWidget(CompetitionsListSEOWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filter != widget.filter) {
      _updateSEOMetadata();
    }
  }

  void _updateSEOMetadata() {
    final filter = widget.filter;

    String title;
    String description;
    String canonicalUrl;

    if (filter == 'upcoming') {
      title = 'Upcoming Competitions | Street Core';
      description =
          'Discover upcoming fitness competitions and events. '
          'Register for competitions, connect with athletes, and showcase your skills.';
      canonicalUrl = '${widget.baseUrl}/competitions/upcoming';
    } else if (filter == 'live') {
      title = 'Live Competitions | Street Core';
      description =
          'Watch live competitions and real-time leaderboards. '
          'Follow your favorite athletes as they compete in events around the world.';
      canonicalUrl = '${widget.baseUrl}/competitions/live';
    } else {
      title = 'Competitions & Events | Street Core';
      description =
          'Browse all fitness competitions and events on Street Core. '
          'Find competitions near you, register to compete, and track results.';
      canonicalUrl = '${widget.baseUrl}/competitions';
    }

    SEOMetaTags.updateTitle(title);
    SEOMetaTags.updateDescription(description);
    SEOMetaTags.updateCanonicalUrl(canonicalUrl);
    SEOMetaTags.updateOGType('website');
    SEOMetaTags.updateKeywords([
      'fitness competitions',
      'sports events',
      'athlete competitions',
      'competition registration',
      'sports leaderboard',
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
