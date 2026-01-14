import 'package:street_core/core/lang/locale_keys.dart';

import '../../../../core/router/navigation_service.dart';
import '../../../../core/widgets/my_text.dart';
import '../../competition_routes.dart';
import '../bloc/competition_category_cubit.dart';
import '../../models/competition_category_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Widget for displaying and managing participants section
class CategoryParticipantsSection extends StatelessWidget {
  const CategoryParticipantsSection({
    super.key,
    required this.category,
    required this.competitionId,
    required this.categoryId,
  });
  final CompetitionCategory category;
  final String competitionId;
  final String categoryId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, theme),
            const SizedBox(height: 16),
            _buildParticipantsList(context, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Row(
      children: [
        Icon(Icons.people, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        const Expanded(
          child: MyText(LocaleKeys.participants, istitle: true, fontSize: 20),
        ),
        ElevatedButton.icon(
          onPressed: () => _showAddParticipantDialog(context),
          icon: const Icon(Icons.person_add, size: 18),
          label: const MyText(LocaleKeys.addParticipant),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ),
      ],
    );
  }

  Widget _buildParticipantsList(BuildContext context, ThemeData theme) {
    if (category.participants.isEmpty) {
      return _buildEmptyState(context, theme);
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: category.participants.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final participantId = category.participants[index];
        return _ParticipantListTile(
          participantId: participantId,
          index: index,
          competitionId: competitionId,
          categoryId: categoryId,
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Icon(Icons.people, size: 48, color: theme.colorScheme.outline),
            const SizedBox(height: 12),
            MyText(LocaleKeys.noParticipants,
                color: theme.textTheme.bodySmall?.color),
          ],
        ),
      ),
    );
  }

  void _showAddParticipantDialog(BuildContext context) {
    final participantIdController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const MyText(LocaleKeys.addParticipant),
        content: TextField(
          controller: participantIdController,
          decoration: const InputDecoration(
            labelText: LocaleKeys.participantId,
            hintText: LocaleKeys.enterParticipantId,
            prefixIcon: Icon(Icons.person),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const MyText(LocaleKeys.cancel),
          ),
          FilledButton(
            onPressed: () {
              if (participantIdController.text.isNotEmpty) {
                context.read<CompetitionCategoryCubit>().addParticipant(
                      competitionId,
                      categoryId,
                      participantIdController.text,
                    );
                Navigator.pop(dialogContext);
              }
            },
            child: const MyText(LocaleKeys.add),
          ),
        ],
      ),
    );
  }
}

/// Internal widget for participant list tile
class _ParticipantListTile extends StatelessWidget {
  const _ParticipantListTile({
    required this.participantId,
    required this.index,
    required this.competitionId,
    required this.categoryId,
  });
  final String participantId;
  final int index;
  final String competitionId;
  final String categoryId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.secondaryContainer,
        child: MyText('${index + 1}'),
      ),
      title: MyText(LocaleKeys.participantNumber,
          args: {'number': (index + 1).toString()}),
      subtitle: MyText(LocaleKeys.participantId, args: {'id': participantId}),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.score),
            onPressed: () {
              NavigationService().go(
                context,
                CompetitionRoutes.getJudgeScoring(competitionId, categoryId),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _showRemoveConfirmation(context),
          ),
        ],
      ),
    );
  }

  void _showRemoveConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title:  MyText(LocaleKeys.removeParticipant),
        content: const MyText(LocaleKeys.removeParticipantConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const MyText(LocaleKeys.cancel),
          ),
          FilledButton(
            onPressed: () {
              context.read<CompetitionCategoryCubit>().removeParticipant(
                    competitionId,
                    categoryId,
                    participantId,
                  );
              Navigator.pop(dialogContext);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const MyText(LocaleKeys.remove),
          ),
        ],
      ),
    );
  }
}
