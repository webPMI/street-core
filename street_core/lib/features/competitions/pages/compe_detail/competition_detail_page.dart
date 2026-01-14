import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:street_core/core/helpers/responsive/responsive.dart';
import 'package:street_core/core/widgets/app_logo.dart';
import 'package:street_core/core/widgets/error_card.dart';
import 'package:street_core/features/competitions/pages/compe_register/compe_register_button.dart';

import '../../../../core/helpers/snackbar_helper.dart';
import '../../../../core/lang/context_tr.dart';
import '../../../../core/router/navigation_service.dart';
import '../../../../core/widgets/my_text.dart';
import '../../../auth/bloc/user_cubit.dart';
import '../../bloc/competitions_cubit.dart';
import '../../bloc/competitions_state.dart';
import '../../competition_routes.dart';
import '../../models/competition.dart';
import '../../models/judge_check_in.dart';
import 'competition_info_section.dart';
import '../../widgets/competition_status_badge.dart';
import '../../widgets/judges_list_section.dart';
import '../../widgets/management/management_section.dart';
import 'participants_list_section.dart';
import '../../../../core/lang/locale_keys.dart';

class CompetitionDetailPage extends StatefulWidget {
  final String competitionId;

  const CompetitionDetailPage({super.key, required this.competitionId});

  @override
  State<CompetitionDetailPage> createState() => _CompetitionDetailPageState();
}

class _CompetitionDetailPageState extends State<CompetitionDetailPage>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  String? _currentUserId;
  bool _canManageCompetition = false;

  @override
  void initState() {
    super.initState();
    _currentUserId = context.read<UserCubit>().currentUser?.id;
    context.read<CompetitionsCubit>().fetchById(widget.competitionId);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  void _initTabController(Competition competition) {
    final canManage =
        _currentUserId != null && competition.canBeManagedBy(_currentUserId!);

    if (_canManageCompetition != canManage || _tabController == null) {
      _tabController?.dispose();
      final tabCount = canManage ? 4 : 3;
      _tabController = TabController(length: tabCount, vsync: this);
      _canManageCompetition = canManage;
    }
  }

  List<Widget> _buildAppBarActions(Competition competition) {
    return [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: CompetitionStatusBadge(
          status: competition.status,
          compact: true,
        ),
      ),
      if (_canEdit(competition))
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () => context.push(competition.id),
        ),
      PopupMenuButton<String>(
        onSelected: (value) => _handleMenuAction(value, competition),
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'share',
            child: Row(
              children: [
                const Icon(Icons.share),
                const SizedBox(width: 8),
                MyText(context.tr(LocaleKeys.share), selectable: false),
              ],
            ),
          ),
          if (_canEdit(competition) && competition.status == 'draft')
            PopupMenuItem(
              value: 'publish',
              child: Row(
                children: [
                  const Icon(Icons.publish),
                  const SizedBox(width: 8),
                  MyText(context.tr(LocaleKeys.publish), selectable: false),
                ],
              ),
            ),
          if (_canEdit(competition) && competition.status != 'live')
            PopupMenuItem(
              value: 'start',
              child: Row(
                children: [
                   const Icon(Icons.play_arrow, color: Colors.green),
                   const SizedBox(width: 8),
                   MyText(context.tr(LocaleKeys.start), selectable: false),
                 ],
               ),
             ),
          if (_canEdit(competition) && competition.status == 'live')
            PopupMenuItem(
              value: 'end',
              child: Row(
                children: [
                   const Icon(Icons.stop, color: Colors.orange),
                   const SizedBox(width: 8),
                   MyText(context.tr(LocaleKeys.end), selectable: false),
                 ],
               ),
             ),
          if (_canEdit(competition) &&
              (competition.status == 'upcoming' ||
                  competition.status == 'live'))
            PopupMenuItem(
              value: 'postpone',
              child: Row(
                children: [
                   const Icon(Icons.pause_circle, color: Colors.amber),
                   const SizedBox(width: 8),
                   MyText(context.tr(LocaleKeys.postpone), selectable: false),
                 ],
               ),
             ),
          if (_canEdit(competition))
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                   const Icon(Icons.delete, color: Colors.red),
                   const SizedBox(width: 8),
                   MyText(
                     context.tr(LocaleKeys.delete),
                     selectable: false,
                     style: const TextStyle(color: Colors.red),
                   ),
                 ],
               ),
             ),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CompetitionsCubit, CompetitionsState>(
      listener: (context, state) {
        // Handle state changes that need user feedback
        if (state is CompetitionDeleted) {
          SnackBarHelper.showSuccess(
            context,
            LocaleKeys.competitionDeleted,
          );
          NavigationService().go(context, CompetitionRoutes.competitionsList);
        }
        if (state is CompetitionStatusChanged) {
          String message;
          switch (state.newStatus) {
            case 'live':
              message = LocaleKeys.competitionStarted;
              break;
            case 'completed':
              message = LocaleKeys.competitionEnded;
              break;
            case 'postponed':
              message = LocaleKeys.competitionPostponed;
              break;
            default:
              message = LocaleKeys.competitionStatusChanged;
          }
          SnackBarHelper.showSuccess(context, message);
        }
        if (state is CompetitionResultsPublished) {
          SnackBarHelper.showSuccess(context, LocaleKeys.resultsPublished);
        }
        if (state is CompetitionRegistrationSuccess) {
          SnackBarHelper.showSuccess(context, LocaleKeys.registeredSuccessfully);
        }
        if (state is CompetitionUnregistrationSuccess) {
          SnackBarHelper.showSuccess(context, LocaleKeys.unregisteredSuccessfully);
        }
      },
      builder: (context, state) {
        // Loading state
        if (state is CompetitionsLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // Error state
        if (state is CompetitionsError) {
          return ErrorCard(
            message: state.message,
            onRetry: () {
              context.read<CompetitionsCubit>().fetchById(widget.competitionId);
            },
          );
        }

        // Success state with competition data
        if (state is! CompetitionDetailLoaded) {
          return Center(child: MyText(LocaleKeys.noData));
        }

        final competition = state.competition;
        _initTabController(competition);

        // Build tabs based on user permissions
        final tabs = <Tab>[
          Tab(text: context.tr(LocaleKeys.info), icon: const Icon(Icons.info)),
          Tab(text: context.tr(LocaleKeys.participants), icon: const Icon(Icons.people)),
          Tab(text: context.tr(LocaleKeys.judges), icon: const Icon(Icons.gavel)),
          if (_canManageCompetition)
            Tab(
              text: context.tr(LocaleKeys.managementPanel),
              icon: const Icon(Icons.settings),
            ),
        ];

        final tabViews = <Widget>[
          CompetitionInfoSection(competition: competition),
          ParticipantsListSection(competitionId: competition.id),
          JudgesListSection(
            competitionId: competition.id,
            canManage: _canManageCompetition,
          ),
          if (_canManageCompetition)
            ManagementSection(
              competitionId: competition.id,
              competition: competition,
            ),
        ];

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                AppLogo(
                  icon: Icons.emoji_events,
                  size: context.isMobile ? 10 : 18,
                ),
                Expanded(
                  child: MyText(
                    competition.title,
                   
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            actions: _buildAppBarActions(competition),
          ),
          body: Column(
            children: [
              TabBar(
                controller: _tabController,
                isScrollable: _canManageCompetition,
                tabs: tabs,
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: tabViews,
                ),
              ),
            ],
          ),
          floatingActionButton: CompetRegisterButton(competition: competition),
        );
      },
    );
  }

  bool _canEdit(Competition competition) {
    if (_currentUserId == null) return false;
    return competition.canBeManagedBy(_currentUserId!);
  }

  void _handleMenuAction(String action, Competition competition) {
    switch (action) {
      case 'share':
        _shareCompetition(competition);
        break;
      case 'publish':
        _publishCompetition(competition);
        break;
      case 'start':
        _startCompetition(competition);
        break;
      case 'end':
        _endCompetition(competition);
        break;
      case 'postpone':
        _postponeCompetition(competition);
        break;
      case 'delete':
        _showDeleteConfirmation(competition);
        break;
    }
  }

  void _shareCompetition(Competition competition) {
    // Use share_plus package to share competition details
    final place = competition.venue ?? competition.city ?? context.tr(LocaleKeys.toBeDefined);
    final date = '${competition.startDate.day}/${competition.startDate.month}/${competition.startDate.year}';
    
    final text = context.tr(LocaleKeys.shareCompetitionDescription, args: {
      'title': competition.title,
      'description': competition.description,
      'date': date,
      'place': place,
      'link': '[Link aquí]', // Replace with actual deep link when available
    });

    SharePlus.instance.share(
      ShareParams(text: text, subject: competition.title),
    );
  }

  void _publishCompetition(Competition competition) {
    final cubit = context.read<CompetitionsCubit>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr(LocaleKeys.publishResultsTitle)),
        content: Text(context.tr(LocaleKeys.publishResultsMessage)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.tr(LocaleKeys.cancel)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              cubit.publishResults(competition.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: Text(context.tr(LocaleKeys.publish)),
          ),
        ],
      ),
    );
  }

  Future<void> _startCompetition(Competition competition) async {
    final cubit = context.read<CompetitionsCubit>();

    // Validate requirements first
    final validationResult = await cubit.validateStartRequirements(competition.id);

    if (!mounted) return;

    // Show validation dialog with checklist
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr(LocaleKeys.startCompetitionTitle)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Text(
                context.tr(LocaleKeys.startCompetitionMessage),
              ),
              const SizedBox(height: 16),
              MyText(
                LocaleKeys.validationChecklist,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildValidationChecklist(validationResult),
              if (validationResult.warnings.isNotEmpty) ...[
                const SizedBox(height: 16),
                MyText(
                  LocaleKeys.warnings,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                ),
                const SizedBox(height: 8),
                ...validationResult.warnings.map((warning) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.warning, size: 16, color: Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(child: Text(context.tr(warning))),
                        ],
                      ),
                    )),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.tr(LocaleKeys.cancel)),
          ),
          ElevatedButton(
            onPressed: validationResult.canStart
                ? () {
                    Navigator.pop(dialogContext);
                    cubit.startCompetition(competition.id);
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: validationResult.canStart ? Colors.green : Colors.grey,
            ),
            child: Text(context.tr(LocaleKeys.start)),
          ),
        ],
      ),
    );
  }

  Widget _buildValidationChecklist(StartValidationResult validation) {
    return Column(
      children: [
        _buildCheckItem(
          validation.status == 'upcoming',
          context.tr(LocaleKeys.statusCheck),
          errorMessage: validation.errors.contains('error_competition_not_upcoming')
              ? context.tr(LocaleKeys.errorCompetitionNotUpcoming)
              : null,
        ),
        _buildCheckItem(
          validation.currentParticipants >= validation.minParticipants,
          context.tr(LocaleKeys.participantsCheck),
          errorMessage: validation.errors.contains('error_insufficient_participants')
              ? context.tr(LocaleKeys.errorInsufficientParticipants)
              : null,
        ),
        _buildCheckItem(
          validation.hasCategories,
          context.tr(LocaleKeys.categoriesCheck),
          errorMessage: validation.errors.contains('error_no_categories_configured')
              ? context.tr(LocaleKeys.errorNoCategoriesConfigured)
              : null,
        ),
        _buildCheckItem(
          validation.categoriesWithCriteria > 0,
          context.tr(LocaleKeys.criteriaCheck),
          errorMessage: validation.errors.contains('error_no_criteria_configured')
              ? context.tr(LocaleKeys.errorNoCriteriaConfigured)
              : null,
        ),
      ],
    );
  }

  Widget _buildCheckItem(
    bool isValid,
    String text, {
    String? errorMessage,
    bool isWarning = false,
  }) {
    final icon = isValid
        ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
        : isWarning
            ? const Icon(Icons.warning, color: Colors.orange, size: 20)
            : const Icon(Icons.cancel, color: Colors.red, size: 20);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              icon,
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    color: isValid ? Colors.green : (isWarning ? Colors.orange : Colors.red),
                    fontWeight: isValid ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (!isValid && errorMessage != null) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 28),
              child: Text(
                errorMessage,
                style: const TextStyle(fontSize: 12, color: Colors.red),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _endCompetition(Competition competition) {
    final cubit = context.read<CompetitionsCubit>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr(LocaleKeys.endCompetitionTitle)),
        content: Text(context.tr(LocaleKeys.endCompetitionMessage)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.tr(LocaleKeys.cancel)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              cubit.endCompetition(competition.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: Text(context.tr(LocaleKeys.end)),
          ),
        ],
      ),
    );
  }

  void _postponeCompetition(Competition competition) {
    final cubit = context.read<CompetitionsCubit>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr(LocaleKeys.postponeCompetitionTitle)),
        content: Text(context.tr(LocaleKeys.postponeCompetitionMessage)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.tr(LocaleKeys.cancel)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              cubit.postponeCompetition(competition.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            child: Text(context.tr(LocaleKeys.postpone)),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Competition competition) {
    final cubit = context.read<CompetitionsCubit>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.warning_amber_rounded,
          color: Colors.red,
          size: 48,
        ),
        title: Text(
          context.tr(LocaleKeys.deleteCompetitionTitle),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.tr(LocaleKeys.deleteCompetitionMessage),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.tr(LocaleKeys.deleteActionIrreversible),
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.tr(LocaleKeys.cancel)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(dialogContext);
              cubit.delete(competition.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.delete_forever),
            label: Text(context.tr(LocaleKeys.delete)),
          ),
        ],
      ),
    );
  }
}
