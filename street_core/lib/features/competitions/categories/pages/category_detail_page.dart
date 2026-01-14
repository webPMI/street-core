import '../../../../core/di/injection.dart';
import '../../../../core/helpers/snackbar_helper.dart';
import '../../../../core/router/navigation_service.dart';
import '../../../../core/widgets/my_text.dart';
import '../../competition_routes.dart';
import '../bloc/competition_category_cubit.dart';
import '../bloc/competition_category_state.dart';
import '../widgets/category_form_dialog.dart';
import '../widgets/category_info_card.dart';
import '../widgets/category_judges_section.dart';
import '../widgets/category_participants_section.dart';
import '../../models/competition_category_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Category Detail Page
///
/// Displays detailed information about a competition category including:
/// - Category information (name, description, skill level, etc.)
/// - Judges management (assign/remove judges)
/// - Participants management (add/remove participants)
/// - Actions (view ranking, edit category)
class CategoryDetailPage extends StatelessWidget {
  const CategoryDetailPage({
    super.key,
    required this.competitionId,
    required this.categoryId,
  });
  final String competitionId;
  final String categoryId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<CompetitionCategoryCubit>()
        ..fetchCategoryById(competitionId, categoryId),
      child: _CategoryDetailView(
        competitionId: competitionId,
        categoryId: categoryId,
      ),
    );
  }
}

class _CategoryDetailView extends StatelessWidget {
  const _CategoryDetailView({
    required this.competitionId,
    required this.categoryId,
  });
  final String competitionId;
  final String categoryId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: _buildAppBar(context),
      body: BlocConsumer<CompetitionCategoryCubit, CompetitionCategoryState>(
        listener: _handleStateChanges,
        builder: (context, state) => _buildBody(context, state, theme),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Row(
        children: [
          const Icon(Icons.category),
          const SizedBox(width: 8),
          const MyText('category_detail', istitle: true),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () => _showEditCategoryDialog(context),
        ),
      ],
    );
  }

  void _handleStateChanges(
    BuildContext context,
    CompetitionCategoryState state,
  ) {
    if (state is CategoryActionSuccess || state is ParticipantActionSuccess) {
      final message = state is CategoryActionSuccess
          ? state.message
          : (state as ParticipantActionSuccess).message;

      SnackBarHelper.showSuccess(context, message);

      // Reload category after action
      context
          .read<CompetitionCategoryCubit>()
          .fetchCategoryById(competitionId, categoryId);
    }
  }

  Widget _buildBody(
    BuildContext context,
    CompetitionCategoryState state,
    ThemeData theme,
  ) {
    if (state is CompetitionCategoryLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is CompetitionCategoryError) {
      return _buildErrorState(context, state.message, theme);
    }

    if (state is CompetitionCategoryLoaded && state.category != null) {
      return _buildContent(context, state.category!, theme);
    }

    return const Center(child: MyText('no_data_available'));
  }

  Widget _buildErrorState(
    BuildContext context,
    String message,
    ThemeData theme,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          MyText(message, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context
                .read<CompetitionCategoryCubit>()
                .fetchCategoryById(competitionId, categoryId),
            child: MyText('retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    CompetitionCategory category,
    ThemeData theme,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Info Card
          CategoryInfoCard(category: category),
          const SizedBox(height: 24),

          // Judges Section
          CategoryJudgesSection(
            category: category,
            competitionId: competitionId,
            categoryId: categoryId,
          ),
          const SizedBox(height: 24),

          // Participants Section
          CategoryParticipantsSection(
            category: category,
            competitionId: competitionId,
            categoryId: categoryId,
          ),
          const SizedBox(height: 24),

          // Action Buttons
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                NavigationService().go(
                  context,
                  CompetitionRoutes.getCategoryRanking(
                    competitionId,
                    categoryId,
                  ),
                );
              },
              icon: const Icon(Icons.leaderboard),
              label: const MyText('view_ranking'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditCategoryDialog(BuildContext context) {
    final cubit = context.read<CompetitionCategoryCubit>();
    final state = cubit.state;

    if (state is CompetitionCategoryLoaded && state.category != null) {
      // Get competitionId from category
      final competitionId = state.category!.competitionId;

      showDialog(
        context: context,
        builder: (dialogContext) => BlocProvider.value(
          value: cubit,
          child: CategoryFormDialog(
            category: state.category,
            competitionId: competitionId,
          ),
        ),
      );
    }
  }
}
