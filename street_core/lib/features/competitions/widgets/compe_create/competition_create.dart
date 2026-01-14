import 'package:street_core/core/widgets/app_logo.dart';

import '../../../../core/helpers/responsive/responsive_builder.dart';
import '../../../../core/helpers/snackbar_helper.dart';
import '../../../../core/lang/context_tr.dart';
import '../../../../core/widgets/form/animated_form_container.dart';
import '../../../../core/widgets/my_form.dart';
import '../../../../core/widgets/my_text.dart';
import '../../../../develop/dev_form_filler.dart';
import '../../bloc/competitions_cubit.dart';
import '../../bloc/competitions_state.dart';
import 'competition_form_items.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/lang/locale_keys.dart';

class CompetitionCreate extends StatefulWidget {
  // If provided, it's editing

  const CompetitionCreate({super.key, this.competitionId});
  final String? competitionId;

  @override
  State<CompetitionCreate> createState() => _CompetitionCreateState();
}

class _CompetitionCreateState extends State<CompetitionCreate> {
  Map<String, dynamic>? _devInitialData;

  @override
  void initState() {
    super.initState();
    if (widget.competitionId != null) {
      // Load competition data for editing
      context.read<CompetitionsCubit>().fetchById(widget.competitionId!);
    }
  }

  Future<void> _handleSubmit(Map<String, dynamic> data) async {
    try {
      if (widget.competitionId == null) {
        // Create new competition
        await context.read<CompetitionsCubit>().create(data);
      } else {
        // Update existing competition
        await context.read<CompetitionsCubit>().update(
          widget.competitionId!,
          data,
        );
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            AppLogo(
              icon: widget.competitionId == null
                  ? Icons.add_circle
                  : Icons.edit_attributes,
              margin: context.isMobile ? 4 : null,
              padding: context.isMobile ? 4 : null,
              animate: true,
              variant: LogoVariant.full,
            ),
            const SizedBox(width: 8),
            MyText(
              widget.competitionId == null
                  ? LocaleKeys.createCompetition
                  : LocaleKeys.editCompetition,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book_outlined),
            tooltip: context.tr('docs.title'),
            onPressed: () => context.go('/competitions/docs'),
          ),
        ],
      ),
      floatingActionButton: DevFillButton(
        onFill: () => setState(() => _devInitialData = competitionMockData),
      ),
      body: BlocListener<CompetitionsCubit, CompetitionsState>(
        listener: (context, state) {
          if (state is CompetitionCreated) {
            SnackBarHelper.showSuccess(
              context,
              LocaleKeys.competitionCreated,
            );
            Navigator.of(context).pop();
          } else if (state is CompetitionCreatedWithWarning) {
            SnackBarHelper.showWarning(
              context,
              '${context.tr(LocaleKeys.competitionCreated)} - ${context.tr(state.warning)}',
            );
            Navigator.of(context).pop();
          } else if (state is CompetitionUpdated) {
            SnackBarHelper.showSuccess(
              context,
              LocaleKeys.competitionUpdated,
            );
            Navigator.of(context).pop();
          } else if (state is CompetitionUpdatedWithWarning) {
            SnackBarHelper.showWarning(
              context,
              '${context.tr(LocaleKeys.competitionUpdated)} - ${context.tr(state.warning)}',
            );
            Navigator.of(context).pop();
          } else if (state is CompetitionsError) {
            SnackBarHelper.showError(context, context.tr(state.message));
          }
        },
        child: AnimatedFormContainer(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: BlocBuilder<CompetitionsCubit, CompetitionsState>(
              builder: (context, state) {
                Map<String, dynamic>? initialData = _devInitialData;
                bool isLoading = state is CompetitionsLoading;

                // Extract competition data for editing
                if (state is CompetitionDetailLoaded) {
                  final competition = state.competition;
                  initialData = {
                    'title': competition.title,
                    'description': competition.description,
                    'format': competition.format,
                    'competitionType': competition.competitionType,
                    'discipline': competition.discipline,
                    'startDate': competition.startDate.toIso8601String(),
                    'endDate': competition.endDate.toIso8601String(),
                    'venue': competition.venue,
                    'city': competition.city,
                    'country': competition.country,
                    'maxParticipants': competition.maxParticipants,
                    'minParticipants': competition.minParticipants,
                    'requiresApproval': competition.requiresApproval,
                    'entryFee': competition.entryFee,
                    'currency': competition.currency ?? 'EUR',
                    'registrationDeadline': competition.registrationDeadline
                        ?.toIso8601String(),
                    'scoringType': competition.scoringType,
                    'maxScore': competition.maxScore,
                    'totalRounds': competition.totalRounds,
                    'bannerUrl': competition.bannerUrl,
                    'rules': competition.rules,
                  };
                }

                return MyForm(
                  key: ValueKey(initialData?.hashCode),
                  title: widget.competitionId == null
                      ? LocaleKeys.createCompetition
                      : LocaleKeys.editCompetition,
                  formItems: competitionFormItems,
                  initialData: initialData,
                  onSubmit: _handleSubmit,
                  isLoading: isLoading,
                  isScrollable: false,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
