// lib/core/widgets/help_guide/services/guide_service.dart

import '../models/guide_config.dart';
import '../models/guide_step.dart';

/// Service that provides guide configurations for different routes
class GuideService {
  /// Map of route paths to their guide configurations
  static final Map<String, GuideConfig> _guides = {
    // Competition Create Guide
    '/competitions/create': GuideConfig(
      routePath: '/competitions/create',
      titleKey: 'help.guide.competition.create.title',
      steps: [
        const GuideStep(
          titleKey: 'help.guide.competition.create.step1.title',
          descriptionKey: 'help.guide.competition.create.step1.description',
        ),
        const GuideStep(
          titleKey: 'help.guide.competition.create.step2.title',
          descriptionKey: 'help.guide.competition.create.step2.description',
        ),
        const GuideStep(
          titleKey: 'help.guide.competition.create.step3.title',
          descriptionKey: 'help.guide.competition.create.step3.description',
        ),
        const GuideStep(
          titleKey: 'help.guide.competition.create.step4.title',
          descriptionKey: 'help.guide.competition.create.step4.description',
        ),
        const GuideStep(
          titleKey: 'help.guide.competition.create.step5.title',
          descriptionKey: 'help.guide.competition.create.step5.description',
        ),
      ],
      autoShow: true,
    ),

    // Invite Judges Guide (dynamic route pattern: /competitions/*/judges)
    '/competitions/judges': GuideConfig(
      routePath: '/competitions/judges',
      titleKey: 'help.guide.judges.invite.title',
      steps: [
        const GuideStep(
          titleKey: 'help.guide.judges.invite.step1.title',
          descriptionKey: 'help.guide.judges.invite.step1.description',
        ),
        const GuideStep(
          titleKey: 'help.guide.judges.invite.step2.title',
          descriptionKey: 'help.guide.judges.invite.step2.description',
        ),
        const GuideStep(
          titleKey: 'help.guide.judges.invite.step3.title',
          descriptionKey: 'help.guide.judges.invite.step3.description',
        ),
        const GuideStep(
          titleKey: 'help.guide.judges.invite.step4.title',
          descriptionKey: 'help.guide.judges.invite.step4.description',
        ),
        const GuideStep(
          titleKey: 'help.guide.judges.invite.step5.title',
          descriptionKey: 'help.guide.judges.invite.step5.description',
        ),
      ],
      autoShow: true,
    ),

    // Configure Categories Guide (dynamic route pattern: /competitions/*/categories)
    '/competitions/categories': GuideConfig(
      routePath: '/competitions/categories',
      titleKey: 'help.guide.categories.config.title',
      steps: [
        const GuideStep(
          titleKey: 'help.guide.categories.config.step1.title',
          descriptionKey: 'help.guide.categories.config.step1.description',
        ),
        const GuideStep(
          titleKey: 'help.guide.categories.config.step2.title',
          descriptionKey: 'help.guide.categories.config.step2.description',
        ),
        const GuideStep(
          titleKey: 'help.guide.categories.config.step3.title',
          descriptionKey: 'help.guide.categories.config.step3.description',
        ),
        const GuideStep(
          titleKey: 'help.guide.categories.config.step4.title',
          descriptionKey: 'help.guide.categories.config.step4.description',
        ),
        const GuideStep(
          titleKey: 'help.guide.categories.config.step5.title',
          descriptionKey: 'help.guide.categories.config.step5.description',
        ),
      ],
      autoShow: true,
    ),

    // Manage Participants Guide (dynamic route pattern: /competitions/*/participants)
    '/competitions/participants': GuideConfig(
      routePath: '/competitions/participants',
      titleKey: 'help.guide.participants.manage.title',
      steps: [
        const GuideStep(
          titleKey: 'help.guide.participants.manage.step1.title',
          descriptionKey: 'help.guide.participants.manage.step1.description',
        ),
        const GuideStep(
          titleKey: 'help.guide.participants.manage.step2.title',
          descriptionKey: 'help.guide.participants.manage.step2.description',
        ),
        const GuideStep(
          titleKey: 'help.guide.participants.manage.step3.title',
          descriptionKey: 'help.guide.participants.manage.step3.description',
        ),
        const GuideStep(
          titleKey: 'help.guide.participants.manage.step4.title',
          descriptionKey: 'help.guide.participants.manage.step4.description',
        ),
        const GuideStep(
          titleKey: 'help.guide.participants.manage.step5.title',
          descriptionKey: 'help.guide.participants.manage.step5.description',
        ),
      ],
      autoShow: true,
    ),

    // Start Competition Guide (dynamic route pattern: /competitions/*)
    '/competitions/manage': GuideConfig(
      routePath: '/competitions/manage',
      titleKey: 'help.guide.competition.start.title',
      steps: [
        const GuideStep(
          titleKey: 'help.guide.competition.start.step1.title',
          descriptionKey: 'help.guide.competition.start.step1.description',
        ),
        const GuideStep(
          titleKey: 'help.guide.competition.start.step2.title',
          descriptionKey: 'help.guide.competition.start.step2.description',
        ),
        const GuideStep(
          titleKey: 'help.guide.competition.start.step3.title',
          descriptionKey: 'help.guide.competition.start.step3.description',
        ),
        const GuideStep(
          titleKey: 'help.guide.competition.start.step4.title',
          descriptionKey: 'help.guide.competition.start.step4.description',
        ),
        const GuideStep(
          titleKey: 'help.guide.competition.start.step5.title',
          descriptionKey: 'help.guide.competition.start.step5.description',
        ),
      ],
      autoShow: true,
    ),
  };

  /// Get guide configuration for a specific route
  /// Handles dynamic routes by normalizing them
  static GuideConfig? getGuideForRoute(String routePath) {
    // Try exact match first
    if (_guides.containsKey(routePath)) {
      return _guides[routePath];
    }

    // Handle dynamic routes like /competitions/:id/judges
    // Normalize to /competitions/judges
    if (routePath.contains('/competitions/')) {
      if (routePath.endsWith('/judges')) {
        return _guides['/competitions/judges'];
      }
      if (routePath.endsWith('/categories')) {
        return _guides['/competitions/categories'];
      }
      if (routePath.endsWith('/participants')) {
        return _guides['/competitions/participants'];
      }
      // Competition detail/manage page (has ID but no sub-path)
      final segments = routePath.split('/');
      if (segments.length == 3 && segments[1] == 'competitions') {
        return _guides['/competitions/manage'];
      }
    }

    return null;
  }

  /// Check if a guide exists for a route
  static bool hasGuideForRoute(String routePath) {
    return getGuideForRoute(routePath) != null;
  }

  /// Get all available guide routes
  static List<String> getAllGuideRoutes() {
    return _guides.keys.toList();
  }
}
