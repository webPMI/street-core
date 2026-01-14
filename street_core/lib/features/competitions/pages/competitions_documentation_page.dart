/// Competitions Documentation Page
///
/// Complete educational documentation for the Competitions module.
/// Covers types, formats, roles, scoring systems, workflow and FAQs.
///
/// Following Monolith-by-Features architecture (ADR-005).

import 'package:flutter/material.dart';
import 'package:street_core/core/lang/context_tr.dart';
import 'package:street_core/core/widgets/my_text.dart';

class CompetitionsDocumentationPage extends StatefulWidget {
  const CompetitionsDocumentationPage({super.key});

  @override
  State<CompetitionsDocumentationPage> createState() =>
      _CompetitionsDocumentationPageState();
}

class _CompetitionsDocumentationPageState
    extends State<CompetitionsDocumentationPage> {
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _sectionKeys = {
    'intro': GlobalKey(),
    'types': GlobalKey(),
    'formats': GlobalKey(),
    'roles': GlobalKey(),
    'scoring': GlobalKey(),
    'workflow': GlobalKey(),
    'faq': GlobalKey(),
    'best': GlobalKey(),
  };

  String _activeSection = 'intro';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateActiveSection);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateActiveSection);
    _scrollController.dispose();
    super.dispose();
  }

  void _updateActiveSection() {
    // Determine which section is currently in view
    final scrollOffset = _scrollController.offset;
    String? newActiveSection;

    for (final entry in _sectionKeys.entries) {
      final key = entry.value;
      final context = key.currentContext;
      if (context != null) {
        final box = context.findRenderObject() as RenderBox?;
        if (box != null) {
          final position = box.localToGlobal(Offset.zero);
          if (position.dy <= 200 && position.dy >= -box.size.height) {
            newActiveSection = entry.key;
          }
        }
      }
    }

    if (newActiveSection != null && newActiveSection != _activeSection) {
      setState(() {
        _activeSection = newActiveSection!;
      });
    }
  }

  void _scrollToSection(String section) {
    final key = _sectionKeys[section];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.1,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWide = MediaQuery.of(context).size.width > 1200;

    return Scaffold(
      appBar: AppBar(
        title: MyText(
          context.tr('docs.title'),
          fontWeight: FontWeight.bold,
        ),
        elevation: 0,
      ),
      body: isWide ? _buildWideLayout(context, theme) : _buildNarrowLayout(context, theme),
    );
  }

  Widget _buildWideLayout(BuildContext context, ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sidebar
        SizedBox(
          width: 280,
          child: _buildSidebar(context, theme),
        ),
        // Divider
        VerticalDivider(
          width: 1,
          thickness: 1,
          color: theme.dividerColor,
        ),
        // Content
        Expanded(
          child: _buildContent(context, theme),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout(BuildContext context, ThemeData theme) {
    return Column(
      children: [
        // Horizontal scrollable navigation
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              bottom: BorderSide(color: theme.dividerColor),
            ),
          ),
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: _buildNavItems(context, theme, horizontal: true),
          ),
        ),
        // Content
        Expanded(
          child: _buildContent(context, theme),
        ),
      ],
    );
  }

  Widget _buildSidebar(BuildContext context, ThemeData theme) {
    return Container(
      color: theme.colorScheme.surface,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: MyText(
            context.tr('docs.subtitle'),
              style: theme.textTheme.bodySmall,
              color: theme.colorScheme.onSurfaceVariant,
              maxLines: 3,
            ),
          ),
          const SizedBox(height: 16),
          ..._buildNavItems(context, theme),
        ],
      ),
    );
  }

  List<Widget> _buildNavItems(BuildContext context, ThemeData theme, {bool horizontal = false}) {
    final items = [
      ('intro', 'docs.nav.introduction', Icons.info_outline),
      ('types', 'docs.nav.types', Icons.category_outlined),
      ('formats', 'docs.nav.formats', Icons.format_list_bulleted),
      ('roles', 'docs.nav.roles', Icons.people_outline),
      ('scoring', 'docs.nav.scoring', Icons.scoreboard_outlined),
      ('workflow', 'docs.nav.workflow', Icons.timeline),
      ('faq', 'docs.nav.faq', Icons.help_outline),
      ('best', 'docs.nav.best.practices', Icons.lightbulb_outline),
    ];

    return items.map((item) {
      final isActive = _activeSection == item.$1;
      return _buildNavItem(
        context,
        theme,
        label: context.tr(item.$2),
        icon: item.$3,
        isActive: isActive,
        onTap: () => _scrollToSection(item.$1),
        horizontal: horizontal,
      );
    }).toList();
  }

  Widget _buildNavItem(
    BuildContext context,
    ThemeData theme, {
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
    bool horizontal = false,
  }) {
    final activeColor = theme.colorScheme.primary;
    final inactiveColor = theme.colorScheme.onSurfaceVariant;

    if (horizontal) {
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ActionChip(
          avatar: Icon(
            icon,
            size: 18,
            color: isActive ? activeColor : inactiveColor,
          ),
          label: MyText(
            label,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            color: isActive ? activeColor : inactiveColor,
          ),
          backgroundColor: isActive
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          onPressed: onTap,
        ),
      );
    }

    return ListTile(
      leading: Icon(
        icon,
        color: isActive ? activeColor : inactiveColor,
        size: 22,
      ),
      title: MyText(
        label,
        fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
        color: isActive ? activeColor : inactiveColor,
      ),
      selected: isActive,
      selectedTileColor: theme.colorScheme.primaryContainer.withOpacity(0.3),
      onTap: onTap,
      dense: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ThemeData theme) {
    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.all(24),
      children: [
        _buildIntroSection(context, theme),
        const SizedBox(height: 48),
        _buildTypesSection(context, theme),
        const SizedBox(height: 48),
        _buildFormatsSection(context, theme),
        const SizedBox(height: 48),
        _buildRolesSection(context, theme),
        const SizedBox(height: 48),
        _buildScoringSection(context, theme),
        const SizedBox(height: 48),
        _buildWorkflowSection(context, theme),
        const SizedBox(height: 48),
        _buildFaqSection(context, theme),
        const SizedBox(height: 48),
        _buildBestPracticesSection(context, theme),
        const SizedBox(height: 48),
        _buildFooter(context, theme),
      ],
    );
  }

  // ============================================================================
  // INTRODUCTION SECTION
  // ============================================================================

  Widget _buildIntroSection(BuildContext context, ThemeData theme) {
    return _buildSection(
      theme,
      key: _sectionKeys['intro']!,
      icon: Icons.info_outline,
      title: context.tr('docs.intro.title'),
      subtitle: context.tr('docs.intro.subtitle'),
      children: [
        _buildSubSection(
          theme,
          title: context.tr('docs.intro.what.title'),
          content: context.tr('docs.intro.what.content'),
        ),
        const SizedBox(height: 24),
        _buildSubSection(
          theme,
          title: context.tr('docs.intro.key.features.title'),
          content: null,
          children: [
            _buildBulletPoint(context, theme, context.tr('docs.intro.key.features.item1')),
            _buildBulletPoint(context, theme, context.tr('docs.intro.key.features.item2')),
            _buildBulletPoint(context, theme, context.tr('docs.intro.key.features.item3')),
            _buildBulletPoint(context, theme, context.tr('docs.intro.key.features.item4')),
            _buildBulletPoint(context, theme, context.tr('docs.intro.key.features.item5')),
            _buildBulletPoint(context, theme, context.tr('docs.intro.key.features.item6')),
          ],
        ),
        const SizedBox(height: 24),
        _buildSubSection(
          theme,
          title: context.tr('docs.intro.why.use.title'),
          content: context.tr('docs.intro.why.use.content'),
        ),
      ],
    );
  }

  // ============================================================================
  // TYPES SECTION
  // ============================================================================

  Widget _buildTypesSection(BuildContext context, ThemeData theme) {
    return _buildSection(
      theme,
      key: _sectionKeys['types']!,
      icon: Icons.category_outlined,
      title: context.tr('docs.types.title'),
      subtitle: context.tr('docs.types.subtitle'),
      children: [
        _buildTypeCard(
          theme,
          icon: Icons.person,
          title: context.tr('docs.types.individual.title'),
          badge: context.tr('docs.types.individual.badge'),
          description: context.tr('docs.types.individual.description'),
          whenTitle: context.tr('docs.types.individual.when.title'),
          whenItems: [
            context.tr('docs.types.individual.when.item1'),
            context.tr('docs.types.individual.when.item2'),
            context.tr('docs.types.individual.when.item3'),
            context.tr('docs.types.individual.when.item4'),
          ],
          exampleTitle: context.tr('docs.types.individual.example.title'),
          exampleContent: context.tr('docs.types.individual.example.content'),
        ),
        const SizedBox(height: 24),
        _buildTypeCard(
          theme,
          icon: Icons.groups,
          title: context.tr('docs.types.team.title'),
          description: context.tr('docs.types.team.description'),
          whenTitle: context.tr('docs.types.team.when.title'),
          whenItems: [
            context.tr('docs.types.team.when.item1'),
            context.tr('docs.types.team.when.item2'),
            context.tr('docs.types.team.when.item3'),
            context.tr('docs.types.team.when.item4'),
          ],
          exampleTitle: context.tr('docs.types.team.example.title'),
          exampleContent: context.tr('docs.types.team.example.content'),
        ),
        const SizedBox(height: 24),
        _buildTypeCard(
          theme,
          icon: Icons.diversity_3,
          title: context.tr('docs.types.both.title'),
          badge: context.tr('docs.types.both.badge'),
          description: context.tr('docs.types.both.description'),
          whenTitle: context.tr('docs.types.both.when.title'),
          whenItems: [
            context.tr('docs.types.both.when.item1'),
            context.tr('docs.types.both.when.item2'),
            context.tr('docs.types.both.when.item3'),
            context.tr('docs.types.both.when.item4'),
          ],
          exampleTitle: context.tr('docs.types.both.example.title'),
          exampleContent: context.tr('docs.types.both.example.content'),
        ),
        const SizedBox(height: 24),
        _buildTipBox(
          theme,
          title: context.tr('docs.types.tip.title'),
          content: context.tr('docs.types.tip.content'),
        ),
      ],
    );
  }

  // ============================================================================
  // FORMATS SECTION
  // ============================================================================

  Widget _buildFormatsSection(BuildContext context, ThemeData theme) {
    return _buildSection(
      theme,
      key: _sectionKeys['formats']!,
      icon: Icons.format_list_bulleted,
      title: context.tr('docs.formats.title'),
      subtitle: context.tr('docs.formats.subtitle'),
      children: [
        _buildFormatCard(
          theme,
          emoji: '🏆',
          title: context.tr('docs.formats.championship.title'),
          definition: context.tr('docs.formats.championship.definition'),
          mechanicsTitle: context.tr('docs.formats.championship.mechanics.title'),
          mechanicsItems: [
            context.tr('docs.formats.championship.mechanics.item1'),
            context.tr('docs.formats.championship.mechanics.item2'),
            context.tr('docs.formats.championship.mechanics.item3'),
            context.tr('docs.formats.championship.mechanics.item4'),
          ],
          whenTitle: context.tr('docs.formats.championship.when.title'),
          whenItems: [
            context.tr('docs.formats.championship.when.item1'),
            context.tr('docs.formats.championship.when.item2'),
            context.tr('docs.formats.championship.when.item3'),
          ],
          exampleTitle: context.tr('docs.formats.championship.example.title'),
          exampleContent: context.tr('docs.formats.championship.example.content'),
          tipsTitle: context.tr('docs.formats.championship.tips.title'),
          tipsItems: [
            context.tr('docs.formats.championship.tips.item1'),
            context.tr('docs.formats.championship.tips.item2'),
            context.tr('docs.formats.championship.tips.item3'),
          ],
        ),
        const SizedBox(height: 24),
        _buildFormatCard(
          theme,
          emoji: '⚔️',
          title: context.tr('docs.formats.tournament.title'),
          definition: context.tr('docs.formats.tournament.definition'),
          mechanicsTitle: context.tr('docs.formats.tournament.mechanics.title'),
          mechanicsItems: [
            context.tr('docs.formats.tournament.mechanics.item1'),
            context.tr('docs.formats.tournament.mechanics.item2'),
            context.tr('docs.formats.tournament.mechanics.item3'),
            context.tr('docs.formats.tournament.mechanics.item4'),
          ],
          whenTitle: context.tr('docs.formats.tournament.when.title'),
          whenItems: [
            context.tr('docs.formats.tournament.when.item1'),
            context.tr('docs.formats.tournament.when.item2'),
            context.tr('docs.formats.tournament.when.item3'),
          ],
          exampleTitle: context.tr('docs.formats.tournament.example.title'),
          exampleContent: context.tr('docs.formats.tournament.example.content'),
          tipsTitle: context.tr('docs.formats.tournament.tips.title'),
          tipsItems: [
            context.tr('docs.formats.tournament.tips.item1'),
            context.tr('docs.formats.tournament.tips.item2'),
            context.tr('docs.formats.tournament.tips.item3'),
          ],
        ),
        const SizedBox(height: 24),
        _buildFormatCard(
          theme,
          emoji: '🏁',
          title: context.tr('docs.formats.single.race.title'),
          definition: context.tr('docs.formats.single.race.definition'),
          mechanicsTitle: context.tr('docs.formats.single.race.mechanics.title'),
          mechanicsItems: [
            context.tr('docs.formats.single.race.mechanics.item1'),
            context.tr('docs.formats.single.race.mechanics.item2'),
            context.tr('docs.formats.single.race.mechanics.item3'),
          ],
          whenTitle: context.tr('docs.formats.single.race.when.title'),
          whenItems: [
            context.tr('docs.formats.single.race.when.item1'),
            context.tr('docs.formats.single.race.when.item2'),
            context.tr('docs.formats.single.race.when.item3'),
          ],
          exampleTitle: context.tr('docs.formats.single.race.example.title'),
          exampleContent: context.tr('docs.formats.single.race.example.content'),
          tipsTitle: context.tr('docs.formats.single.race.tips.title'),
          tipsItems: [
            context.tr('docs.formats.single.race.tips.item1'),
            context.tr('docs.formats.single.race.tips.item2'),
            context.tr('docs.formats.single.race.tips.item3'),
          ],
        ),
        const SizedBox(height: 24),
        _buildFormatCard(
          theme,
          emoji: '⏱️',
          title: context.tr('docs.formats.time.trial.title'),
          definition: context.tr('docs.formats.time.trial.definition'),
          mechanicsTitle: context.tr('docs.formats.time.trial.mechanics.title'),
          mechanicsItems: [
            context.tr('docs.formats.time.trial.mechanics.item1'),
            context.tr('docs.formats.time.trial.mechanics.item2'),
            context.tr('docs.formats.time.trial.mechanics.item3'),
            context.tr('docs.formats.time.trial.mechanics.item4'),
          ],
          whenTitle: context.tr('docs.formats.time.trial.when.title'),
          whenItems: [
            context.tr('docs.formats.time.trial.when.item1'),
            context.tr('docs.formats.time.trial.when.item2'),
            context.tr('docs.formats.time.trial.when.item3'),
          ],
          exampleTitle: context.tr('docs.formats.time.trial.example.title'),
          exampleContent: context.tr('docs.formats.time.trial.example.content'),
          tipsTitle: context.tr('docs.formats.time.trial.tips.title'),
          tipsItems: [
            context.tr('docs.formats.time.trial.tips.item1'),
            context.tr('docs.formats.time.trial.tips.item2'),
            context.tr('docs.formats.time.trial.tips.item3'),
          ],
        ),
        const SizedBox(height: 24),
        _buildFormatCard(
          theme,
          emoji: '💪',
          title: context.tr('docs.formats.endurance.title'),
          definition: context.tr('docs.formats.endurance.definition'),
          mechanicsTitle: context.tr('docs.formats.endurance.mechanics.title'),
          mechanicsItems: [
            context.tr('docs.formats.endurance.mechanics.item1'),
            context.tr('docs.formats.endurance.mechanics.item2'),
            context.tr('docs.formats.endurance.mechanics.item3'),
            context.tr('docs.formats.endurance.mechanics.item4'),
          ],
          whenTitle: context.tr('docs.formats.endurance.when.title'),
          whenItems: [
            context.tr('docs.formats.endurance.when.item1'),
            context.tr('docs.formats.endurance.when.item2'),
            context.tr('docs.formats.endurance.when.item3'),
          ],
          exampleTitle: context.tr('docs.formats.endurance.example.title'),
          exampleContent: context.tr('docs.formats.endurance.example.content'),
          tipsTitle: context.tr('docs.formats.endurance.tips.title'),
          tipsItems: [
            context.tr('docs.formats.endurance.tips.item1'),
            context.tr('docs.formats.endurance.tips.item2'),
            context.tr('docs.formats.endurance.tips.item3'),
          ],
        ),
        const SizedBox(height: 24),
        _buildFormatCard(
          theme,
          emoji: '🥊',
          title: context.tr('docs.formats.knockout.title'),
          definition: context.tr('docs.formats.knockout.definition'),
          mechanicsTitle: context.tr('docs.formats.knockout.mechanics.title'),
          mechanicsItems: [
            context.tr('docs.formats.knockout.mechanics.item1'),
            context.tr('docs.formats.knockout.mechanics.item2'),
            context.tr('docs.formats.knockout.mechanics.item3'),
            context.tr('docs.formats.knockout.mechanics.item4'),
          ],
          whenTitle: context.tr('docs.formats.knockout.when.title'),
          whenItems: [
            context.tr('docs.formats.knockout.when.item1'),
            context.tr('docs.formats.knockout.when.item2'),
            context.tr('docs.formats.knockout.when.item3'),
            context.tr('docs.formats.knockout.when.item4'),
          ],
          exampleTitle: context.tr('docs.formats.knockout.example.title'),
          exampleContent: context.tr('docs.formats.knockout.example.content'),
          tipsTitle: context.tr('docs.formats.knockout.tips.title'),
          tipsItems: [
            context.tr('docs.formats.knockout.tips.item1'),
            context.tr('docs.formats.knockout.tips.item2'),
            context.tr('docs.formats.knockout.tips.item3'),
          ],
        ),
      ],
    );
  }

  // ============================================================================
  // ROLES SECTION
  // ============================================================================

  Widget _buildRolesSection(BuildContext context, ThemeData theme) {
    return _buildSection(
      theme,
      key: _sectionKeys['roles']!,
      icon: Icons.people_outline,
      title: context.tr('docs.roles.title'),
      subtitle: context.tr('docs.roles.subtitle'),
      children: [
        _buildRoleCard(
          theme,
          icon: Icons.person,
          iconColor: theme.colorScheme.primary,
          title: context.tr('docs.roles.organizer.title'),
          description: context.tr('docs.roles.organizer.description'),
          responsibilitiesTitle: context.tr('docs.roles.organizer.responsibilities.title'),
          responsibilitiesItems: [
            context.tr('docs.roles.organizer.responsibilities.item1'),
            context.tr('docs.roles.organizer.responsibilities.item2'),
            context.tr('docs.roles.organizer.responsibilities.item3'),
            context.tr('docs.roles.organizer.responsibilities.item4'),
            context.tr('docs.roles.organizer.responsibilities.item5'),
            context.tr('docs.roles.organizer.responsibilities.item6'),
          ],
          permissionsTitle: context.tr('docs.roles.organizer.permissions.title'),
          permissionsItems: [
            context.tr('docs.roles.organizer.permissions.item1'),
            context.tr('docs.roles.organizer.permissions.item2'),
            context.tr('docs.roles.organizer.permissions.item3'),
            context.tr('docs.roles.organizer.permissions.item4'),
            context.tr('docs.roles.organizer.permissions.item5'),
          ],
          bestPracticesTitle: context.tr('docs.roles.organizer.best.practices.title'),
          bestPracticesItems: [
            context.tr('docs.roles.organizer.best.practices.item1'),
            context.tr('docs.roles.organizer.best.practices.item2'),
            context.tr('docs.roles.organizer.best.practices.item3'),
            context.tr('docs.roles.organizer.best.practices.item4'),
            context.tr('docs.roles.organizer.best.practices.item5'),
          ],
        ),
        const SizedBox(height: 24),
        _buildRoleCard(
          theme,
          icon: Icons.mic,
          iconColor: Colors.orange,
          title: context.tr('docs.roles.speaker.title'),
          description: context.tr('docs.roles.speaker.description'),
          responsibilitiesTitle: context.tr('docs.roles.speaker.responsibilities.title'),
          responsibilitiesItems: [
            context.tr('docs.roles.speaker.responsibilities.item1'),
            context.tr('docs.roles.speaker.responsibilities.item2'),
            context.tr('docs.roles.speaker.responsibilities.item3'),
            context.tr('docs.roles.speaker.responsibilities.item4'),
            context.tr('docs.roles.speaker.responsibilities.item5'),
          ],
          permissionsTitle: context.tr('docs.roles.speaker.permissions.title'),
          permissionsItems: [
            context.tr('docs.roles.speaker.permissions.item1'),
            context.tr('docs.roles.speaker.permissions.item2'),
            context.tr('docs.roles.speaker.permissions.item3'),
            context.tr('docs.roles.speaker.permissions.item4'),
            context.tr('docs.roles.speaker.permissions.item5'),
          ],
          bestPracticesTitle: context.tr('docs.roles.speaker.best.practices.title'),
          bestPracticesItems: [
            context.tr('docs.roles.speaker.best.practices.item1'),
            context.tr('docs.roles.speaker.best.practices.item2'),
            context.tr('docs.roles.speaker.best.practices.item3'),
            context.tr('docs.roles.speaker.best.practices.item4'),
            context.tr('docs.roles.speaker.best.practices.item5'),
          ],
        ),
        const SizedBox(height: 24),
        _buildRoleCard(
          theme,
          icon: Icons.gavel,
          iconColor: Colors.purple,
          title: context.tr('docs.roles.judge.title'),
          description: context.tr('docs.roles.judge.description'),
          responsibilitiesTitle: context.tr('docs.roles.judge.responsibilities.title'),
          responsibilitiesItems: [
            context.tr('docs.roles.judge.responsibilities.item1'),
            context.tr('docs.roles.judge.responsibilities.item2'),
            context.tr('docs.roles.judge.responsibilities.item3'),
            context.tr('docs.roles.judge.responsibilities.item4'),
            context.tr('docs.roles.judge.responsibilities.item5'),
          ],
          permissionsTitle: context.tr('docs.roles.judge.permissions.title'),
          permissionsItems: [
            context.tr('docs.roles.judge.permissions.item1'),
            context.tr('docs.roles.judge.permissions.item2'),
            context.tr('docs.roles.judge.permissions.item3'),
            context.tr('docs.roles.judge.permissions.item4'),
            context.tr('docs.roles.judge.permissions.item5'),
          ],
          bestPracticesTitle: context.tr('docs.roles.judge.best.practices.title'),
          bestPracticesItems: [
            context.tr('docs.roles.judge.best.practices.item1'),
            context.tr('docs.roles.judge.best.practices.item2'),
            context.tr('docs.roles.judge.best.practices.item3'),
            context.tr('docs.roles.judge.best.practices.item4'),
            context.tr('docs.roles.judge.best.practices.item5'),
          ],
          extraTitle: context.tr('docs.roles.judge.requirements.title'),
          extraItems: [
            context.tr('docs.roles.judge.requirements.item1'),
            context.tr('docs.roles.judge.requirements.item2'),
            context.tr('docs.roles.judge.requirements.item3'),
            context.tr('docs.roles.judge.requirements.item4'),
          ],
        ),
        const SizedBox(height: 24),
        _buildRoleCard(
          theme,
          icon: Icons.directions_run,
          iconColor: Colors.green,
          title: context.tr('docs.roles.participant.title'),
          description: context.tr('docs.roles.participant.description'),
          responsibilitiesTitle: context.tr('docs.roles.participant.responsibilities.title'),
          responsibilitiesItems: [
            context.tr('docs.roles.participant.responsibilities.item1'),
            context.tr('docs.roles.participant.responsibilities.item2'),
            context.tr('docs.roles.participant.responsibilities.item3'),
            context.tr('docs.roles.participant.responsibilities.item4'),
            context.tr('docs.roles.participant.responsibilities.item5'),
          ],
          permissionsTitle: context.tr('docs.roles.participant.permissions.title'),
          permissionsItems: [
            context.tr('docs.roles.participant.permissions.item1'),
            context.tr('docs.roles.participant.permissions.item2'),
            context.tr('docs.roles.participant.permissions.item3'),
            context.tr('docs.roles.participant.permissions.item4'),
            context.tr('docs.roles.participant.permissions.item5'),
          ],
          bestPracticesTitle: context.tr('docs.roles.participant.best.practices.title'),
          bestPracticesItems: [
            context.tr('docs.roles.participant.best.practices.item1'),
            context.tr('docs.roles.participant.best.practices.item2'),
            context.tr('docs.roles.participant.best.practices.item3'),
            context.tr('docs.roles.participant.best.practices.item4'),
            context.tr('docs.roles.participant.best.practices.item5'),
          ],
        ),
      ],
    );
  }

  // ============================================================================
  // SCORING SECTION
  // ============================================================================

  Widget _buildScoringSection(BuildContext context, ThemeData theme) {
    return _buildSection(
      theme,
      key: _sectionKeys['scoring']!,
      icon: Icons.scoreboard_outlined,
      title: context.tr('docs.scoring.title'),
      subtitle: context.tr('docs.scoring.subtitle'),
      children: [
        _buildSubSection(
          theme,
          title: context.tr('docs.scoring.overview.title'),
          content: context.tr('docs.scoring.overview.content'),
        ),
        const SizedBox(height: 32),
        _buildScoringTypeCard(
          theme,
          emoji: '💯',
          title: context.tr('docs.scoring.points.title'),
          definition: context.tr('docs.scoring.points.definition'),
          sections: [
            (
              context.tr('docs.scoring.points.how.title'),
              [
                context.tr('docs.scoring.points.how.item1'),
                context.tr('docs.scoring.points.how.item2'),
                context.tr('docs.scoring.points.how.item3'),
                context.tr('docs.scoring.points.how.item4'),
                context.tr('docs.scoring.points.how.item5'),
              ]
            ),
            (
              context.tr('docs.scoring.points.when.title'),
              [
                context.tr('docs.scoring.points.when.item1'),
                context.tr('docs.scoring.points.when.item2'),
                context.tr('docs.scoring.points.when.item3'),
              ]
            ),
            (
              context.tr('docs.scoring.points.criteria.title'),
              [
                context.tr('docs.scoring.points.criteria.item1'),
                context.tr('docs.scoring.points.criteria.item2'),
                context.tr('docs.scoring.points.criteria.item3'),
                context.tr('docs.scoring.points.criteria.item4'),
                context.tr('docs.scoring.points.criteria.item5'),
              ]
            ),
          ],
          example: context.tr('docs.scoring.points.example.content'),
          config: [
            context.tr('docs.scoring.points.config.item1'),
            context.tr('docs.scoring.points.config.item2'),
            context.tr('docs.scoring.points.config.item3'),
            context.tr('docs.scoring.points.config.item4'),
          ],
        ),
        const SizedBox(height: 24),
        _buildScoringTypeCard(
          theme,
          emoji: '⏱️',
          title: context.tr('docs.scoring.time.title'),
          definition: context.tr('docs.scoring.time.definition'),
          sections: [
            (
              context.tr('docs.scoring.time.how.title'),
              [
                context.tr('docs.scoring.time.how.item1'),
                context.tr('docs.scoring.time.how.item2'),
                context.tr('docs.scoring.time.how.item3'),
                context.tr('docs.scoring.time.how.item4'),
              ]
            ),
            (
              context.tr('docs.scoring.time.when.title'),
              [
                context.tr('docs.scoring.time.when.item1'),
                context.tr('docs.scoring.time.when.item2'),
                context.tr('docs.scoring.time.when.item3'),
              ]
            ),
          ],
          example: context.tr('docs.scoring.time.example.content'),
          config: [
            context.tr('docs.scoring.time.config.item1'),
            context.tr('docs.scoring.time.config.item2'),
            context.tr('docs.scoring.time.config.item3'),
            context.tr('docs.scoring.time.config.item4'),
          ],
        ),
        const SizedBox(height: 24),
        _buildScoringTypeCard(
          theme,
          emoji: '📊',
          title: context.tr('docs.scoring.average.title'),
          definition: context.tr('docs.scoring.average.definition'),
          sections: [
            (
              context.tr('docs.scoring.average.how.title'),
              [
                context.tr('docs.scoring.average.how.item1'),
                context.tr('docs.scoring.average.how.item2'),
                context.tr('docs.scoring.average.how.item3'),
                context.tr('docs.scoring.average.how.item4'),
              ]
            ),
            (
              context.tr('docs.scoring.average.when.title'),
              [
                context.tr('docs.scoring.average.when.item1'),
                context.tr('docs.scoring.average.when.item2'),
                context.tr('docs.scoring.average.when.item3'),
              ]
            ),
          ],
          example: context.tr('docs.scoring.average.example.content'),
          config: [
            context.tr('docs.scoring.average.config.item1'),
            context.tr('docs.scoring.average.config.item2'),
            context.tr('docs.scoring.average.config.item3'),
          ],
        ),
        const SizedBox(height: 24),
        _buildScoringTypeCard(
          theme,
          emoji: '➕',
          title: context.tr('docs.scoring.sum.title'),
          definition: context.tr('docs.scoring.sum.definition'),
          sections: [
            (
              context.tr('docs.scoring.sum.how.title'),
              [
                context.tr('docs.scoring.sum.how.item1'),
                context.tr('docs.scoring.sum.how.item2'),
                context.tr('docs.scoring.sum.how.item3'),
                context.tr('docs.scoring.sum.how.item4'),
              ]
            ),
            (
              context.tr('docs.scoring.sum.when.title'),
              [
                context.tr('docs.scoring.sum.when.item1'),
                context.tr('docs.scoring.sum.when.item2'),
                context.tr('docs.scoring.sum.when.item3'),
              ]
            ),
          ],
          example: context.tr('docs.scoring.sum.example.content'),
          config: [
            context.tr('docs.scoring.sum.config.item1'),
            context.tr('docs.scoring.sum.config.item2'),
            context.tr('docs.scoring.sum.config.item3'),
          ],
        ),
        const SizedBox(height: 24),
        _buildScoringTypeCard(
          theme,
          emoji: '⚖️',
          title: context.tr('docs.scoring.weighted.title'),
          definition: context.tr('docs.scoring.weighted.definition'),
          sections: [
            (
              context.tr('docs.scoring.weighted.how.title'),
              [
                context.tr('docs.scoring.weighted.how.item1'),
                context.tr('docs.scoring.weighted.how.item2'),
                context.tr('docs.scoring.weighted.how.item3'),
                context.tr('docs.scoring.weighted.how.item4'),
              ]
            ),
            (
              context.tr('docs.scoring.weighted.when.title'),
              [
                context.tr('docs.scoring.weighted.when.item1'),
                context.tr('docs.scoring.weighted.when.item2'),
                context.tr('docs.scoring.weighted.when.item3'),
              ]
            ),
          ],
          example: context.tr('docs.scoring.weighted.example.content'),
          config: [
            context.tr('docs.scoring.weighted.config.item1'),
            context.tr('docs.scoring.weighted.config.item2'),
            context.tr('docs.scoring.weighted.config.item3'),
          ],
        ),
        const SizedBox(height: 24),
        _buildInfoBox(
          theme,
          icon: Icons.info_outline,
          title: context.tr('docs.scoring.drops.title'),
          content: context.tr('docs.scoring.drops.content'),
          footer: context.tr('docs.scoring.drops.when'),
        ),
        const SizedBox(height: 24),
        _buildSubSection(
          theme,
          title: context.tr('docs.scoring.criteria.title'),
          subtitle: context.tr('docs.scoring.criteria.subtitle'),
          content: context.tr('docs.scoring.criteria.content'),
          children: [
            const SizedBox(height: 12),
            _buildExampleBox(
              theme,
              title: context.tr('docs.scoring.criteria.example.title'),
              items: [
                context.tr('docs.scoring.criteria.example.item1'),
                context.tr('docs.scoring.criteria.example.item2'),
                context.tr('docs.scoring.criteria.example.item3'),
                context.tr('docs.scoring.criteria.example.item4'),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================================
  // WORKFLOW SECTION
  // ============================================================================

  Widget _buildWorkflowSection(BuildContext context, ThemeData theme) {
    return _buildSection(
      theme,
      key: _sectionKeys['workflow']!,
      icon: Icons.timeline,
      title: context.tr('docs.workflow.title'),
      subtitle: context.tr('docs.workflow.subtitle'),
      children: [
        _buildPhaseCard(
          theme,
          phaseNumber: 1,
          phaseColor: Colors.blue,
          title: context.tr('docs.workflow.phase1.title'),
          subtitle: context.tr('docs.workflow.phase1.subtitle'),
          steps: [
            (
              context.tr('docs.workflow.phase1.step1.title'),
              context.tr('docs.workflow.phase1.step1.content')
            ),
            (
              context.tr('docs.workflow.phase1.step2.title'),
              context.tr('docs.workflow.phase1.step2.content')
            ),
            (
              context.tr('docs.workflow.phase1.step3.title'),
              context.tr('docs.workflow.phase1.step3.content')
            ),
            (
              context.tr('docs.workflow.phase1.step4.title'),
              context.tr('docs.workflow.phase1.step4.content')
            ),
            (
              context.tr('docs.workflow.phase1.step5.title'),
              context.tr('docs.workflow.phase1.step5.content')
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildPhaseCard(
          theme,
          phaseNumber: 2,
          phaseColor: Colors.orange,
          title: context.tr('docs.workflow.phase2.title'),
          subtitle: context.tr('docs.workflow.phase2.subtitle'),
          steps: [
            (
              context.tr('docs.workflow.phase2.step1.title'),
              context.tr('docs.workflow.phase2.step1.content')
            ),
            (
              context.tr('docs.workflow.phase2.step2.title'),
              context.tr('docs.workflow.phase2.step2.content')
            ),
            (
              context.tr('docs.workflow.phase2.step3.title'),
              context.tr('docs.workflow.phase2.step3.content')
            ),
            (
              context.tr('docs.workflow.phase2.step4.title'),
              context.tr('docs.workflow.phase2.step4.content')
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildPhaseCard(
          theme,
          phaseNumber: 3,
          phaseColor: Colors.green,
          title: context.tr('docs.workflow.phase3.title'),
          subtitle: context.tr('docs.workflow.phase3.subtitle'),
          steps: [
            (
              context.tr('docs.workflow.phase3.step1.title'),
              context.tr('docs.workflow.phase3.step1.content')
            ),
            (
              context.tr('docs.workflow.phase3.step2.title'),
              context.tr('docs.workflow.phase3.step2.content')
            ),
            (
              context.tr('docs.workflow.phase3.step3.title'),
              context.tr('docs.workflow.phase3.step3.content')
            ),
            (
              context.tr('docs.workflow.phase3.step4.title'),
              context.tr('docs.workflow.phase3.step4.content')
            ),
            (
              context.tr('docs.workflow.phase3.step5.title'),
              context.tr('docs.workflow.phase3.step5.content')
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildPhaseCard(
          theme,
          phaseNumber: 4,
          phaseColor: Colors.purple,
          title: context.tr('docs.workflow.phase4.title'),
          subtitle: context.tr('docs.workflow.phase4.subtitle'),
          steps: [
            (
              context.tr('docs.workflow.phase4.step1.title'),
              context.tr('docs.workflow.phase4.step1.content')
            ),
            (
              context.tr('docs.workflow.phase4.step2.title'),
              context.tr('docs.workflow.phase4.step2.content')
            ),
            (
              context.tr('docs.workflow.phase4.step3.title'),
              context.tr('docs.workflow.phase4.step3.content')
            ),
            (
              context.tr('docs.workflow.phase4.step4.title'),
              context.tr('docs.workflow.phase4.step4.content')
            ),
            (
              context.tr('docs.workflow.phase4.step5.title'),
              context.tr('docs.workflow.phase4.step5.content')
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildTimelineBox(context, theme),
      ],
    );
  }

  // ============================================================================
  // FAQ SECTION
  // ============================================================================

  Widget _buildFaqSection(BuildContext context, ThemeData theme) {
    return _buildSection(
      theme,
      key: _sectionKeys['faq']!,
      icon: Icons.help_outline,
      title: context.tr('docs.faq.title'),
      subtitle: context.tr('docs.faq.subtitle'),
      children: [
        _buildFaqItem(
          theme,
          question: context.tr('docs.faq.q1.question'),
          answer: context.tr('docs.faq.q1.answer'),
        ),
        _buildFaqItem(
          theme,
          question: context.tr('docs.faq.q2.question'),
          answer: context.tr('docs.faq.q2.answer'),
        ),
        _buildFaqItem(
          theme,
          question: context.tr('docs.faq.q3.question'),
          answer: context.tr('docs.faq.q3.answer'),
        ),
        _buildFaqItem(
          theme,
          question: context.tr('docs.faq.q4.question'),
          answer: context.tr('docs.faq.q4.answer'),
        ),
        _buildFaqItem(
          theme,
          question: context.tr('docs.faq.q5.question'),
          answer: context.tr('docs.faq.q5.answer'),
        ),
        _buildFaqItem(
          theme,
          question: context.tr('docs.faq.q6.question'),
          answer: context.tr('docs.faq.q6.answer'),
        ),
        _buildFaqItem(
          theme,
          question: context.tr('docs.faq.q7.question'),
          answer: context.tr('docs.faq.q7.answer'),
        ),
        _buildFaqItem(
          theme,
          question: context.tr('docs.faq.q8.question'),
          answer: context.tr('docs.faq.q8.answer'),
        ),
        _buildFaqItem(
          theme,
          question: context.tr('docs.faq.q9.question'),
          answer: context.tr('docs.faq.q9.answer'),
        ),
        _buildFaqItem(
          theme,
          question: context.tr('docs.faq.q10.question'),
          answer: context.tr('docs.faq.q10.answer'),
        ),
        _buildFaqItem(
          theme,
          question: context.tr('docs.faq.q11.question'),
          answer: context.tr('docs.faq.q11.answer'),
        ),
        _buildFaqItem(
          theme,
          question: context.tr('docs.faq.q12.question'),
          answer: context.tr('docs.faq.q12.answer'),
        ),
      ],
    );
  }

  // ============================================================================
  // BEST PRACTICES SECTION
  // ============================================================================

  Widget _buildBestPracticesSection(BuildContext context, ThemeData theme) {
    return _buildSection(
      theme,
      key: _sectionKeys['best']!,
      icon: Icons.lightbulb_outline,
      title: context.tr('docs.best.title'),
      subtitle: context.tr('docs.best.subtitle'),
      children: [
        _buildBestPracticeCategory(
          theme,
          icon: Icons.calendar_today,
          title: context.tr('docs.best.preparation.title'),
          tips: [
            (
              context.tr('docs.best.preparation.tip1.title'),
              context.tr('docs.best.preparation.tip1.content')
            ),
            (
              context.tr('docs.best.preparation.tip2.title'),
              context.tr('docs.best.preparation.tip2.content')
            ),
            (
              context.tr('docs.best.preparation.tip3.title'),
              context.tr('docs.best.preparation.tip3.content')
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildBestPracticeCategory(
          theme,
          icon: Icons.chat_bubble_outline,
          title: context.tr('docs.best.communication.title'),
          tips: [
            (
              context.tr('docs.best.communication.tip1.title'),
              context.tr('docs.best.communication.tip1.content')
            ),
            (
              context.tr('docs.best.communication.tip2.title'),
              context.tr('docs.best.communication.tip2.content')
            ),
            (
              context.tr('docs.best.communication.tip3.title'),
              context.tr('docs.best.communication.tip3.content')
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildBestPracticeCategory(
          theme,
          icon: Icons.gavel,
          title: context.tr('docs.best.judges.title'),
          tips: [
            (
              context.tr('docs.best.judges.tip1.title'),
              context.tr('docs.best.judges.tip1.content')
            ),
            (
              context.tr('docs.best.judges.tip2.title'),
              context.tr('docs.best.judges.tip2.content')
            ),
            (
              context.tr('docs.best.judges.tip3.title'),
              context.tr('docs.best.judges.tip3.content')
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildBestPracticeCategory(
          theme,
          icon: Icons.people,
          title: context.tr('docs.best.participants.title'),
          tips: [
            (
              context.tr('docs.best.participants.tip1.title'),
              context.tr('docs.best.participants.tip1.content')
            ),
            (
              context.tr('docs.best.participants.tip2.title'),
              context.tr('docs.best.participants.tip2.content')
            ),
            (
              context.tr('docs.best.participants.tip3.title'),
              context.tr('docs.best.participants.tip3.content')
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildBestPracticeCategory(
          theme,
          icon: Icons.play_circle_outline,
          title: context.tr('docs.best.execution.title'),
          tips: [
            (
              context.tr('docs.best.execution.tip1.title'),
              context.tr('docs.best.execution.tip1.content')
            ),
            (
              context.tr('docs.best.execution.tip2.title'),
              context.tr('docs.best.execution.tip2.content')
            ),
            (
              context.tr('docs.best.execution.tip3.title'),
              context.tr('docs.best.execution.tip3.content')
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildBestPracticeCategory(
          theme,
          icon: Icons.flag,
          title: context.tr('docs.best.after.title'),
          tips: [
            (
              context.tr('docs.best.after.tip1.title'),
              context.tr('docs.best.after.tip1.content')
            ),
            (
              context.tr('docs.best.after.tip2.title'),
              context.tr('docs.best.after.tip2.content')
            ),
            (
              context.tr('docs.best.after.tip3.title'),
              context.tr('docs.best.after.tip3.content')
            ),
            (
              context.tr('docs.best.after.tip4.title'),
              context.tr('docs.best.after.tip4.content')
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================================
  // FOOTER
  // ============================================================================

  Widget _buildFooter(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.help_center,
            size: 48,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          MyText(
            context.tr('docs.need.help.title'),
            style: theme.textTheme.titleLarge,
            fontWeight: FontWeight.bold,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          MyText(
            context.tr('docs.need.help.content'),
            style: theme.textTheme.bodyMedium,
            color: theme.colorScheme.onSurfaceVariant,
            textAlign: TextAlign.center,
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  // Navigate to contact support
                },
                icon: const Icon(Icons.contact_support),
                label: MyText(context.tr('docs.contact.support')),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  // Navigate to community
                },
                icon: const Icon(Icons.groups),
                label: MyText(context.tr('docs.join.community')),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  // Navigate to tutorials
                },
                icon: const Icon(Icons.video_library),
                label: MyText(context.tr('docs.watch.tutorials')),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Divider(color: theme.dividerColor),
          const SizedBox(height: 16),
          MyText(
            '${context.tr('docs.updated')}: 2026-01-09',
            style: theme.textTheme.bodySmall,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          MyText(
            '${context.tr('docs.version')}: 1.0',
            style: theme.textTheme.bodySmall,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // REUSABLE WIDGETS
  // ============================================================================

  Widget _buildSection(
    ThemeData theme, {
    required GlobalKey key,
    required IconData icon,
    required String title,
    String? subtitle,
    required List<Widget> children,
  }) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: theme.colorScheme.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MyText(
            title,
                    style: theme.textTheme.headlineMedium,
                    fontWeight: FontWeight.bold,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    MyText(
            subtitle,
                      style: theme.textTheme.bodyLarge,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        ...children,
      ],
    );
  }

  Widget _buildSubSection(
    ThemeData theme, {
    required String title,
    String? subtitle,
    String? content,
    List<Widget>? children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MyText(
          title,
          style: theme.textTheme.titleLarge,
          fontWeight: FontWeight.w600,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          MyText(
            subtitle,
            style: theme.textTheme.bodyMedium,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
        if (content != null) ...[
          const SizedBox(height: 12),
          MyText(
            content,
            style: theme.textTheme.bodyLarge,
            maxLines: 20,
          ),
        ],
        if (children != null) ...children,
      ],
    );
  }

  Widget _buildBulletPoint(BuildContext context, ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: MyText(
            text,
              style: theme.textTheme.bodyMedium,
              maxLines: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeCard(
    ThemeData theme, {
    required IconData icon,
    required String title,
    String? badge,
    required String description,
    required String whenTitle,
    required List<String> whenItems,
    required String exampleTitle,
    required String exampleContent,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 32, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: MyText(
            title,
                  style: theme.textTheme.titleLarge,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: MyText(
            badge,
                    style: theme.textTheme.bodySmall,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onTertiaryContainer,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          MyText(
            description,
            style: theme.textTheme.bodyMedium,
            maxLines: 10,
          ),
          const SizedBox(height: 16),
          MyText(
            whenTitle,
            style: theme.textTheme.titleSmall,
            fontWeight: FontWeight.w600,
          ),
          ...whenItems.map((item) => _buildBulletPoint(context, theme, item)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb_outline,
                        size: 18, color: theme.colorScheme.secondary),
                    const SizedBox(width: 8),
                    MyText(
            exampleTitle,
                      style: theme.textTheme.titleSmall,
                      fontWeight: FontWeight.w600,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                MyText(
            exampleContent,
                  style: theme.textTheme.bodySmall,
                  maxLines: 10,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatCard(
    ThemeData theme, {
    required String emoji,
    required String title,
    required String definition,
    required String mechanicsTitle,
    required List<String> mechanicsItems,
    required String whenTitle,
    required List<String> whenItems,
    required String exampleTitle,
    required String exampleContent,
    required String tipsTitle,
    required List<String> tipsItems,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Expanded(
                child: MyText(
            title,
                  style: theme.textTheme.titleLarge,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          MyText(
            definition,
            style: theme.textTheme.bodyMedium,
            maxLines: 10,
          ),
          const SizedBox(height: 16),
          MyText(
            mechanicsTitle,
            style: theme.textTheme.titleSmall,
            fontWeight: FontWeight.w600,
          ),
          ...mechanicsItems.map((item) => _buildBulletPoint(context, theme, item)),
          const SizedBox(height: 16),
          MyText(
            whenTitle,
            style: theme.textTheme.titleSmall,
            fontWeight: FontWeight.w600,
          ),
          ...whenItems.map((item) => _buildBulletPoint(context, theme, item)),
          const SizedBox(height: 16),
          _buildExampleBox(theme, title: exampleTitle, content: exampleContent),
          const SizedBox(height: 16),
          MyText(
            tipsTitle,
            style: theme.textTheme.titleSmall,
            fontWeight: FontWeight.w600,
          ),
          ...tipsItems.map((item) => _buildBulletPoint(context, theme, item)),
        ],
      ),
    );
  }

  Widget _buildRoleCard(
    ThemeData theme, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required String responsibilitiesTitle,
    required List<String> responsibilitiesItems,
    required String permissionsTitle,
    required List<String> permissionsItems,
    required String bestPracticesTitle,
    required List<String> bestPracticesItems,
    String? extraTitle,
    List<String>? extraItems,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: iconColor.withOpacity(0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 28, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MyText(
            title,
                  style: theme.textTheme.titleLarge,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          MyText(
            description,
            style: theme.textTheme.bodyMedium,
            maxLines: 10,
          ),
          const SizedBox(height: 16),
          MyText(
            responsibilitiesTitle,
            style: theme.textTheme.titleSmall,
            fontWeight: FontWeight.w600,
          ),
          ...responsibilitiesItems.map((item) => _buildBulletPoint(context, theme, item)),
          const SizedBox(height: 16),
          MyText(
            permissionsTitle,
            style: theme.textTheme.titleSmall,
            fontWeight: FontWeight.w600,
          ),
          ...permissionsItems.map((item) => _buildBulletPoint(context, theme, item)),
          const SizedBox(height: 16),
          MyText(
            bestPracticesTitle,
            style: theme.textTheme.titleSmall,
            fontWeight: FontWeight.w600,
          ),
          ...bestPracticesItems.map((item) => _buildBulletPoint(context, theme, item)),
          if (extraTitle != null && extraItems != null) ...[
            const SizedBox(height: 16),
            MyText(
            extraTitle,
              style: theme.textTheme.titleSmall,
              fontWeight: FontWeight.w600,
            ),
            ...extraItems.map((item) => _buildBulletPoint(context, theme, item)),
          ],
        ],
      ),
    );
  }

  Widget _buildScoringTypeCard(
    ThemeData theme, {
    required String emoji,
    required String title,
    required String definition,
    required List<(String, List<String>)> sections,
    required String example,
    required List<String> config,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: MyText(
            title,
                  style: theme.textTheme.titleLarge,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          MyText(
            definition,
            style: theme.textTheme.bodyMedium,
            maxLines: 10,
          ),
          const SizedBox(height: 16),
          ...sections.map((section) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyText(
            section.$1,
                  style: theme.textTheme.titleSmall,
                  fontWeight: FontWeight.w600,
                ),
                ...section.$2.map((item) => _buildBulletPoint(context, theme, item)),
                const SizedBox(height: 12),
              ],
            );
          }),
          _buildExampleBox(theme, title: 'Ejemplo:', content: example),
          const SizedBox(height: 12),
          MyText(
            'Configuración recomendada:',
            style: theme.textTheme.titleSmall,
            fontWeight: FontWeight.w600,
          ),
          ...config.map((item) => _buildBulletPoint(context, theme, item)),
        ],
      ),
    );
  }

  Widget _buildPhaseCard(
    ThemeData theme, {
    required int phaseNumber,
    required Color phaseColor,
    required String title,
    required String subtitle,
    required List<(String, String)> steps,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: phaseColor.withOpacity(0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: phaseColor.withOpacity(0.2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: phaseColor,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: MyText(
            phaseNumber.toString(),
                    style: theme.textTheme.titleLarge,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MyText(
            title,
                        style: theme.textTheme.titleLarge,
                        fontWeight: FontWeight.bold,
                      ),
                      MyText(
            subtitle,
                        style: theme.textTheme.bodySmall,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: steps.asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: phaseColor.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: MyText(
            (entry.key + 1).toString(),
                          style: theme.textTheme.bodySmall,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            MyText(
            entry.value.$1,
                              style: theme.textTheme.titleSmall,
                              fontWeight: FontWeight.w600,
                            ),
                            const SizedBox(height: 4),
                            MyText(
            entry.value.$2,
                              style: theme.textTheme.bodySmall,
                              maxLines: 10,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqItem(ThemeData theme, {required String question, required String answer}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.help_outline,
                  size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: MyText(
            question,
                  style: theme.textTheme.titleSmall,
                  fontWeight: FontWeight.w600,
                  maxLines: 5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: MyText(
            answer,
              style: theme.textTheme.bodyMedium,
              maxLines: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBestPracticeCategory(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required List<(String, String)> tips,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              MyText(
            title,
                style: theme.textTheme.titleLarge,
                fontWeight: FontWeight.w600,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...tips.map((tip) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MyText(
            tip.$1,
                    style: theme.textTheme.titleSmall,
                    fontWeight: FontWeight.w600,
                  ),
                  const SizedBox(height: 4),
                  MyText(
            tip.$2,
                    style: theme.textTheme.bodyMedium,
                    maxLines: 10,
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTipBox(ThemeData theme, {required String title, required String content}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.tertiary.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb, color: theme.colorScheme.tertiary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyText(
            title,
                  style: theme.textTheme.titleSmall,
                  fontWeight: FontWeight.w600,
                ),
                const SizedBox(height: 4),
                MyText(
            content,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 10,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String content,
    String? footer,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: MyText(
            title,
                  style: theme.textTheme.titleSmall,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          MyText(
            content,
            style: theme.textTheme.bodyMedium,
            maxLines: 10,
          ),
          if (footer != null) ...[
            const SizedBox(height: 8),
            MyText(
            footer,
              style: theme.textTheme.bodySmall,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExampleBox(
    ThemeData theme, {
    required String title,
    String? content,
    List<String>? items,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.code, size: 18, color: theme.colorScheme.secondary),
              const SizedBox(width: 8),
              MyText(
            title,
                style: theme.textTheme.titleSmall,
                fontWeight: FontWeight.w600,
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (content != null)
            MyText(
            content,
              style: theme.textTheme.bodySmall,
              maxLines: 10,
            ),
          if (items != null)
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: MyText(
            '• $item',
                    style: theme.textTheme.bodySmall,
                    maxLines: 5,
                  ),
                )),
        ],
      ),
    );
  }

  Widget _buildTimelineBox(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MyText(
            context.tr('docs.workflow.timeline.title'),
            style: theme.textTheme.titleLarge,
            fontWeight: FontWeight.w600,
          ),
          const SizedBox(height: 16),
          _buildTimelineItem(theme, '4W', context.tr('docs.workflow.timeline.week4')),
          _buildTimelineItem(theme, '3W', context.tr('docs.workflow.timeline.week3')),
          _buildTimelineItem(theme, '2W', context.tr('docs.workflow.timeline.week2')),
          _buildTimelineItem(theme, '1W', context.tr('docs.workflow.timeline.week1')),
          _buildTimelineItem(theme, '1D', context.tr('docs.workflow.timeline.day1')),
          _buildTimelineItem(theme, 'HOY', context.tr('docs.workflow.timeline.day0'),
              isLast: false),
          _buildTimelineItem(
              theme, '+1D', context.tr('docs.workflow.timeline.day.after'),
              isLast: true),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(ThemeData theme, String label, String text,
      {bool isLast = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: MyText(
            label,
                  style: theme.textTheme.bodySmall,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 30,
                  color: theme.colorScheme.outlineVariant,
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: MyText(
            text,
                style: theme.textTheme.bodyMedium,
                maxLines: 5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
