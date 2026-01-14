import 'package:street_core/core/lang/locale_keys.dart';
import '../../../../core/widgets/my_text.dart';
import '../bloc/competition_category_cubit.dart';
import '../../models/competition_category_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Widget for displaying and managing judges section
class CategoryJudgesSection extends StatelessWidget {
  const CategoryJudgesSection({
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
            _buildJudgesList(context, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Row(
      children: [
        Icon(Icons.gavel, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: MyText(LocaleKeys.judges, istitle: true, fontSize: 20),
        ),
        if (!category.isFull)
          ElevatedButton.icon(
            onPressed: () => _showInviteJudgeDialog(context),
            icon: const Icon(Icons.person_add, size: 18),
            label: MyText(LocaleKeys.inviteJudge),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
      ],
    );
  }

  Widget _buildJudgesList(BuildContext context, ThemeData theme) {
    if (category.judges.isEmpty) {
      return _buildEmptyState(context, theme);
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: category.judges.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final judgeId = category.judges[index];
        return _JudgeListTile(
          judgeId: judgeId,
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
            Icon(Icons.gavel, size: 48, color: theme.colorScheme.outline),
            const SizedBox(height: 12),
            MyText(LocaleKeys.noJudgesAssigned,
              color: theme.textTheme.bodySmall?.color,
            ),
          ],
        ),
      ),
    );
  }

  void _showInviteJudgeDialog(BuildContext context) {
    final judgeIdController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: MyText(LocaleKeys.inviteJudge),
        content: TextField(
          controller: judgeIdController,
          decoration: InputDecoration(
            labelText: LocaleKeys.judgeId,
            hintText: LocaleKeys.enterJudgeId,
            prefixIcon: const Icon(Icons.person),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: MyText(LocaleKeys.cancel),
          ),
          FilledButton(
            onPressed: () {
              if (judgeIdController.text.isNotEmpty) {
                context.read<CompetitionCategoryCubit>().addJudge(
                  competitionId,
                  categoryId,
                  judgeIdController.text,
                );
                Navigator.pop(dialogContext);
              }
            },
            child: MyText(LocaleKeys.invite),
          ),
        ],
      ),
    );
  }
}

/// Internal widget for judge list tile
class _JudgeListTile extends StatelessWidget {
  const _JudgeListTile({
    required this.judgeId,
    required this.index,
    required this.competitionId,
    required this.categoryId,
  });
  final String judgeId;
  final int index;
  final String competitionId;
  final String categoryId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primaryContainer,
        child: Icon(Icons.person, color: theme.colorScheme.primary),
      ),
      title: MyText('${LocaleKeys.judge} #${index + 1}'),
      subtitle: MyText('${LocaleKeys.id}: $judgeId'),
      trailing: IconButton(
        icon: const Icon(Icons.cancel),
        onPressed: () => _showRemoveConfirmation(context),
      ),
    );
  }

  void _showRemoveConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: MyText(LocaleKeys.removeJudge),
        content: MyText(LocaleKeys.removeJudgeConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: MyText(LocaleKeys.cancel),
          ),
          FilledButton(
            onPressed: () {
              context.read<CompetitionCategoryCubit>().removeJudge(
                competitionId,
                categoryId,
                judgeId,
              );
              Navigator.pop(dialogContext);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: MyText( LocaleKeys.remove, ),
          ),
        ],
      ),
    );
  }
}
