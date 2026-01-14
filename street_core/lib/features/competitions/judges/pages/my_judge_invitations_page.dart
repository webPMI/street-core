import 'package:street_core/core/lang/locale_keys.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/lang/context_tr.dart';
import '../../../../core/widgets/drawer/my_drawer.dart';
import '../../../../core/widgets/my_text.dart';
import '../../models/judge_invitation.dart';
import '../bloc/judge_invitation_cubit.dart';
import '../bloc/judge_invitation_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class MyJudgeInvitationsPage extends StatelessWidget {
  const MyJudgeInvitationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<JudgeInvitationCubit>()..getMyInvitations(),
      child: const _MyJudgeInvitationsView(),
    );
  }
}

class _MyJudgeInvitationsView extends StatefulWidget {
  const _MyJudgeInvitationsView();

  @override
  State<_MyJudgeInvitationsView> createState() =>
      _MyJudgeInvitationsViewState();
}

class _MyJudgeInvitationsViewState extends State<_MyJudgeInvitationsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: const [
            Icon(Icons.gavel),
            SizedBox(width: 8),
            MyText(LocaleKeys.myJudgeInvitations),
          ],
        ),
      ),
      drawer: MyDrawer(),
      body: Column(
      children: [
        Material(
          color: theme.colorScheme.surface,
          elevation: 1,
          child: TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: context.tr(LocaleKeys.pendingInvitations)),
              Tab(text: context.tr(LocaleKeys.accepted)),
              Tab(text: context.tr(LocaleKeys.rejected)),
            ],
          ),
        ),
        Expanded(
          child: BlocBuilder<JudgeInvitationCubit, JudgeInvitationState>(
            builder: (context, state) {
              if (state is JudgeInvitationLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is JudgeInvitationError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      MyText(state.message, noTranslation: true, color: theme.colorScheme.error),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => context
                            .read<JudgeInvitationCubit>()
                            .getMyInvitations(),
                        child: const MyText(LocaleKeys.retry),
                      ),
                    ],
                  ),
                );
              }

              if (state is JudgeInvitationListLoaded) {
                final allInvitations = state.invitations;
                final pendingInvitations = allInvitations
                    .where((inv) => inv.isPending && !inv.isExpired)
                    .toList();
                final acceptedInvitations = allInvitations
                    .where((inv) => inv.isAccepted)
                    .toList();
                final rejectedInvitations = allInvitations
                    .where((inv) => inv.isRejected)
                    .toList();

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildInvitationList(
                      context,
                      pendingInvitations,
                      InvitationStatus.pending,
                      theme,
                    ),
                    _buildInvitationList(
                      context,
                      acceptedInvitations,
                      InvitationStatus.accepted,
                      theme,
                    ),
                    _buildInvitationList(
                      context,
                      rejectedInvitations,
                      InvitationStatus.rejected,
                      theme,
                    ),
                  ],
                );
              }

              return const Center(child: MyText(LocaleKeys.noDataAvailable));
            },
          ),
        ),
      ],
      ),
    );
  }

  Widget _buildInvitationList(
    BuildContext context,
    List<JudgeInvitation> invitations,
    String filterStatus,
    ThemeData theme,
  ) {
    if (invitations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mail_outline,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            MyText(LocaleKeys.noInvitations, color: theme.textTheme.bodySmall?.color),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<JudgeInvitationCubit>().getMyInvitations();
      },
      child: ListView.separated(
        itemCount: invitations.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final invitation = invitations[index];
          return _buildInvitationCard(context, invitation, theme);
        },
      ),
    );
  }

  Widget _buildInvitationCard(
    BuildContext context,
    JudgeInvitation invitation,
    ThemeData theme,
  ) {
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');
    final canRespond = invitation.canRespond;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Competition and Category
            Row(
              children: [
                Icon(
                  Icons.emoji_events,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MyText(
                        invitation.competitionName,
                        noTranslation: true,
                        istitle: true,
                        fontSize: 16,
                      ),
                      MyText(
                        invitation.categoryName,
                        noTranslation: true,
                        fontSize: 14,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(context, invitation, theme),
              ],
            ),
            const SizedBox(height: 12),

            // Organizer info
            Row(
              children: [
                Icon(
                  Icons.person,
                  size: 16,
                  color: theme.textTheme.bodySmall?.color,
                ),
                const SizedBox(width: 6),
                MyText(
                  '${context.tr(LocaleKeys.invitedBy)}: ${invitation.invitedByName}',
                  noTranslation: true,
                  fontSize: 13,
                  color: theme.textTheme.bodySmall?.color,
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Created date
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: theme.textTheme.bodySmall?.color,
                ),
                const SizedBox(width: 6),
                MyText(
                  dateFormat.format(invitation.createdAt),
                  noTranslation: true,
                  fontSize: 13,
                  color: theme.textTheme.bodySmall?.color,
                ),
              ],
            ),

            // Expiration warning
            if (invitation.expiresAt != null && invitation.isPending) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: invitation.isExpired
                        ? theme.colorScheme.error
                        : Colors.orange,
                  ),
                  const SizedBox(width: 6),
                  MyText(
                    '${context.tr(LocaleKeys.invitationExpiresAt)}: ${dateFormat.format(invitation.expiresAt!)}',
                    noTranslation: true,
                    fontSize: 13,
                    color: invitation.isExpired
                        ? theme.colorScheme.error
                        : Colors.orange,
                  ),
                ],
              ),
            ],

            // Message from organizer
            if (invitation.message != null &&
                invitation.message!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(
                    0.3,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MyText(
                      LocaleKeys.message,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                    const SizedBox(height: 4),
                    MyText(invitation.message!, noTranslation: true, fontSize: 13),
                  ],
                ),
              ),
            ],

            // Response actions for pending invitations
            if (canRespond) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _acceptInvitation(context, invitation),
                      icon: const Icon(Icons.check, size: 18),
                      label: const MyText(LocaleKeys.acceptInvitation),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _rejectInvitation(context, invitation),
                      icon: const Icon(Icons.close, size: 18),
                      label: const MyText(LocaleKeys.rejectInvitation),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // Response message
            if (invitation.response != null &&
                invitation.response!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(
                    0.3,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MyText(
                      LocaleKeys.yourResponse,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                    const SizedBox(height: 4),
                    MyText(invitation.response!, noTranslation: true, fontSize: 13),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(
    BuildContext context,
    JudgeInvitation invitation,
    ThemeData theme,
  ) {
    Color backgroundColor;
    Color textColor;
    IconData icon;
    String statusKey;

    if (invitation.isAccepted) {
      backgroundColor = Colors.green.withOpacity(0.2);
      textColor = Colors.green.shade700;
      icon = Icons.check_circle;
      statusKey = LocaleKeys.accepted;
    } else if (invitation.isRejected) {
      backgroundColor = Colors.red.withOpacity(0.2);
      textColor = Colors.red.shade700;
      icon = Icons.cancel;
      statusKey = LocaleKeys.rejected;
    } else if (invitation.isExpired) {
      backgroundColor = Colors.grey.withOpacity(0.2);
      textColor = Colors.grey.shade700;
      icon = Icons.access_time;
      statusKey = LocaleKeys.expired;
    } else {
      backgroundColor = Colors.orange.withOpacity(0.2);
      textColor = Colors.orange.shade700;
      icon = Icons.pending;
      statusKey = LocaleKeys.pending;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          MyText(
            statusKey,
            noTranslation: statusKey == 'Expired',
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ],
      ),
    );
  }

  Future<void> _acceptInvitation(
    BuildContext context,
    JudgeInvitation invitation,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _ResponseDialog(
        title: context.tr(LocaleKeys.acceptInvitation),
        message: context.tr(LocaleKeys.confirmAcceptInvitation),
        confirmText: context.tr(LocaleKeys.accept),
        cancelText: context.tr(LocaleKeys.cancel),
      ),
    );

    if ((result ?? false) && context.mounted) {
      context.read<JudgeInvitationCubit>().respondToInvitation(
        invitation.id,
        InvitationStatus.accepted,
        '', // Optional message
      );
    }
  }

  Future<void> _rejectInvitation(
    BuildContext context,
    JudgeInvitation invitation,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _ResponseDialog(
        title: context.tr(LocaleKeys.rejectInvitation),
        message: context.tr(LocaleKeys.confirmRejectInvitation),
        confirmText: context.tr(LocaleKeys.reject),
        cancelText: context.tr(LocaleKeys.cancel),
      ),
    );

    if ((result ?? false) && context.mounted) {
      context.read<JudgeInvitationCubit>().respondToInvitation(
        invitation.id,
        InvitationStatus.rejected,
        '', // Optional message
      );
    }
  }
}

class _ResponseDialog extends StatelessWidget {
  const _ResponseDialog({
    required this.title,
    required this.message,
    required this.confirmText,
    required this.cancelText,
  });
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: MyText(title, noTranslation: true, istitle: true),
      content: MyText(message, noTranslation: true),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: MyText(cancelText, noTranslation: true),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: MyText(confirmText, noTranslation: true),
        ),
      ],
    );
  }
}
