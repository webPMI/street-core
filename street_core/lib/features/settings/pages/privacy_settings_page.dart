import '../../../core/lang/context_tr.dart';
import '../../../core/lang/locale_keys.dart';
import '../../../core/services/api_service.dart';
import '../../../core/widgets/my_text.dart';
import '../../../core/helpers/snackbar_helper.dart';
import '../../../data/models/privacy_settings_model.dart';
import '../../profile/repositories/privacy_repository.dart';
import '../bloc/privacy_settings_cubit.dart';
import '../bloc/privacy_settings_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PrivacySettingsPage extends StatelessWidget {
  const PrivacySettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          SettingsCubit(PrivacyRepository(context.read<ApiService>()))
            ..loadSettings(),
      child: const _PrivacySettingsView(),
    );
  }
}

class _PrivacySettingsView extends StatelessWidget {
  const _PrivacySettingsView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<SettingsCubit, SettingsState>(
      listener: (context, state) {
        if (state is PrivacySettingsError) {
          SnackBarHelper.showCustom(context, state.message, type: SnackBarType.error);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: MyText(LocaleKeys.privacySettings,),
          centerTitle: true,
        ),
        body: BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, state) {
            if (state is PrivacySettingsLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is PrivacySettingsError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    MyText(state.message),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () =>
                          context.read<SettingsCubit>().loadSettings(),
                      icon: const Icon(Icons.refresh),
                      label: MyText(LocaleKeys.retry),
                    ),
                  ],
                ),
              );
            }

            if (state is PrivacySettingsLoaded) {
              return RefreshIndicator(
                onRefresh: () => context.read<SettingsCubit>().loadSettings(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context, Theme.of(context)),
                      const SizedBox(height: 16),
                      _buildProfileVisibilitySection(
                        context,
                        Theme.of(context),
                        state.settings,
                      ),
                      const SizedBox(height: 16),
                      _buildContactInfoSection(
                        context,
                        Theme.of(context),
                        state.settings,
                      ),
                      const SizedBox(height: 16),
                      _buildActivityPrivacySection(
                        context,
                        Theme.of(context),
                        state.settings,
                      ),
                      const SizedBox(height: 16),
                      _buildInteractionSettingsSection(
                        context,
                        Theme.of(context),
                        state.settings,
                      ),
                      const SizedBox(height: 16),
                      _buildDataPrivacySection(
                        context,
                        Theme.of(context),
                        state.settings,
                      ),
                      const SizedBox(height: 16),
                      _buildBlockedUsersSection(
                        context,
                        Theme.of(context),
                        state.settings,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.lock_outline,
                size: 32,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MyText(LocaleKeys.privacySettings, istitle: true, 
                 ),
                  const SizedBox(height: 4),
                  MyText(
                    LocaleKeys.manageYourPrivacy,
                    color: theme.colorScheme.onSurfaceVariant,
                    selectable: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileVisibilitySection(
    BuildContext context,
    ThemeData theme,
    PrivacySettings settings,
  ) {
    return _buildSection(
      context,
      theme,
      title: LocaleKeys.profileVisibility,
      icon: Icons.visibility,
      color: Colors.blue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MyText(
            LocaleKeys.whoCanSeeYourProfile,
            color: theme.colorScheme.onSurfaceVariant,
            selectable: false,
          ),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: [
              ButtonSegment(
                value: 'public',
                label: MyText(LocaleKeys.public, selectable: false),
                icon: const Icon(Icons.public),
              ),
              ButtonSegment(
                value: 'friends',
                label: MyText(LocaleKeys.friends, selectable: false),
                icon: const Icon(Icons.people),
              ),
              ButtonSegment(
                value: 'private',
                label: MyText(LocaleKeys.private, selectable: false),
                icon: const Icon(Icons.lock),
              ),
            ],
            selected: {settings.profileVisibility},
            onSelectionChanged: (Set<String> newSelection) {
              context.read<SettingsCubit>().updateSettings({
                'profileVisibility': newSelection.first,
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfoSection(
    BuildContext context,
    ThemeData theme,
    PrivacySettings settings,
  ) {
    return _buildSection(
      context,
      theme,
      title: LocaleKeys.contactInformation,
      icon: Icons.contact_phone,
      color: Colors.purple,
      child: Column(
        children: [
          SwitchListTile(
            value: settings.showEmail,
            onChanged: (value) => context.read<SettingsCubit>().updateSettings({
              'showEmail': value,
            }),
            title: MyText(LocaleKeys.showEmail, selectable: false),
            subtitle: MyText(LocaleKeys.showEmailDescription, selectable: false),
            secondary: const Icon(Icons.email_outlined),
          ),
          const Divider(),
          SwitchListTile(
            value: settings.showPhone,
            onChanged: (value) => context.read<SettingsCubit>().updateSettings({
              'showPhone': value,
            }),
            title: MyText(LocaleKeys.showPhone, selectable: false),
            subtitle: MyText(LocaleKeys.showPhoneDescription, selectable: false),
            secondary: const Icon(Icons.phone_outlined),
          ),
          const Divider(),
          SwitchListTile(
            value: settings.showBirthdate,
            onChanged: (value) => context.read<SettingsCubit>().updateSettings({
              'showBirthdate': value,
            }),
            title: MyText(LocaleKeys.showBirthdate, selectable: false),
            subtitle: MyText(LocaleKeys.showBirthdateDescription, selectable: false),
            secondary: const Icon(Icons.cake_outlined),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityPrivacySection(
    BuildContext context,
    ThemeData theme,
    PrivacySettings settings,
  ) {
    return _buildSection(
      context,
      theme,
      title: LocaleKeys.activityPrivacy,
      icon: Icons.access_time,
      color: Colors.orange,
      child: Column(
        children: [
          SwitchListTile(
            value: settings.showOnlineStatus,
            onChanged: (value) => context.read<SettingsCubit>().updateSettings({
              'showOnlineStatus': value,
            }),
            title: MyText(LocaleKeys.showOnlineStatus, selectable: false),
            subtitle: MyText(LocaleKeys.showOnlineStatusDescription, selectable: false),
            secondary: const Icon(Icons.circle, color: Colors.green, size: 16),
          ),
          const Divider(),
          SwitchListTile(
            value: settings.showLastSeen,
            onChanged: (value) => context.read<SettingsCubit>().updateSettings({
              'showLastSeen': value,
            }),
            title: MyText(LocaleKeys.showLastSeen, selectable: false),
            subtitle: MyText(LocaleKeys.showLastSeenDescription, selectable: false),
            secondary: const Icon(Icons.schedule),
          ),
          const Divider(),
          SwitchListTile(
            value: settings.showActivityFeed,
            onChanged: (value) => context.read<SettingsCubit>().updateSettings({
              'showActivityFeed': value,
            }),
            title: MyText(LocaleKeys.showActivityFeed, selectable: false),
            subtitle: MyText(LocaleKeys.showActivityFeedDescription, selectable: false),
            secondary: const Icon(Icons.feed_outlined),
          ),
          const Divider(),
          SwitchListTile(
            value: settings.allowTagging,
            onChanged: (value) => context.read<SettingsCubit>().updateSettings({
              'allowTagging': value,
            }),
            title: MyText(LocaleKeys.allowTagging, selectable: false),
            subtitle: MyText(LocaleKeys.allowTaggingDescription, selectable: false),
            secondary: const Icon(Icons.local_offer_outlined),
          ),
          const Divider(),
          SwitchListTile(
            value: settings.allowMentions,
            onChanged: (value) => context.read<SettingsCubit>().updateSettings({
              'allowMentions': value,
            }),
            title: MyText(LocaleKeys.allowMentions, selectable: false),
            subtitle: MyText(LocaleKeys.allowMentionsDescription, selectable: false),
            secondary: const Icon(Icons.alternate_email),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractionSettingsSection(
    BuildContext context,
    ThemeData theme,
    PrivacySettings settings,
  ) {
    return _buildSection(
      context,
      theme,
      title: LocaleKeys.interactionSettings,
      icon: Icons.people_outline,
      color: Colors.teal,
      child: Column(
        children: [
          _buildDropdownSetting(
            context,
            theme,
            title: LocaleKeys.whoCanMessageYou,
            subtitle: LocaleKeys.whoCanMessageYouDescription,
            icon: Icons.message_outlined,
            value: settings.whoCanMessage,
            items: [LocaleKeys.everyone, LocaleKeys.friends, LocaleKeys.nobody],
            onChanged: (value) => context.read<SettingsCubit>().updateSettings({
              'whoCanMessage': value,
            }),
          ),
          const Divider(),
          _buildDropdownSetting(
            context,
            theme,
            title: LocaleKeys.whoCanComment,
            subtitle: LocaleKeys.whoCanCommentDescription,
            icon: Icons.comment_outlined,
            value: settings.whoCanComment,
            items: [LocaleKeys.everyone, LocaleKeys.friends, LocaleKeys.nobody],
            onChanged: (value) => context.read<SettingsCubit>().updateSettings({
              'whoCanComment': value,
            }),
          ),
          const Divider(),
          _buildDropdownSetting(
            context,
            theme,
            title: LocaleKeys.whoCanFollowYou,
            subtitle: LocaleKeys.whoCanFollowYouDescription,
            icon: Icons.person_add_outlined,
            value: settings.whoCanFollow,
            items: [LocaleKeys.everyone, LocaleKeys.nobody],
            onChanged: (value) => context.read<SettingsCubit>().updateSettings({
              'whoCanFollow': value,
            }),
          ),
          const Divider(),
          SwitchListTile(
            value: settings.requireFollowApproval,
            onChanged: (value) => context.read<SettingsCubit>().updateSettings({
              'requireFollowApproval': value,
            }),
            title: MyText(LocaleKeys.requireFollowApproval, selectable: false),
            subtitle: MyText(LocaleKeys.requireFollowApprovalDescription, selectable: false),
            secondary: const Icon(Icons.check_circle_outline),
          ),
        ],
      ),
    );
  }

  Widget _buildDataPrivacySection(
    BuildContext context,
    ThemeData theme,
    PrivacySettings settings,
  ) {
    return _buildSection(
      context,
      theme,
      title: LocaleKeys.dataPrivacy,
      icon: Icons.shield_outlined,
      color: Colors.red,
      child: Column(
        children: [
          SwitchListTile(
            value: settings.allowDataCollection,
            onChanged: (value) => context.read<SettingsCubit>().updateSettings({
              'allowDataCollection': value,
            }),
            title: MyText(LocaleKeys.allowDataCollection, selectable: false),
            subtitle: MyText(LocaleKeys.allowDataCollectionDescription, selectable: false),
            secondary: const Icon(Icons.analytics_outlined),
          ),
          const Divider(),
          SwitchListTile(
            value: settings.allowPersonalizedAds,
            onChanged: (value) => context.read<SettingsCubit>().updateSettings({
              'allowPersonalizedAds': value,
            }),
            title: MyText(LocaleKeys.allowPersonalizedAds, selectable: false),
            subtitle: MyText(LocaleKeys.allowPersonalizedAdsDescription, selectable: false),
            secondary: const Icon(Icons.ads_click_outlined),
          ),
          const Divider(),
          SwitchListTile(
            value: settings.allowThirdPartySharing,
            onChanged: (value) => context.read<SettingsCubit>().updateSettings({
              'allowThirdPartySharing': value,
            }),
            title: MyText(LocaleKeys.allowThirdPartySharing, selectable: false),
            subtitle: MyText(LocaleKeys.allowThirdPartySharingDescription, selectable: false),
            secondary: const Icon(Icons.share_outlined),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockedUsersSection(
    BuildContext context,
    ThemeData theme,
    PrivacySettings settings,
  ) {
    final blockedCount = settings.blockedUserIds.length;

    return _buildSection(
      context,
      theme,
      title: LocaleKeys.blockedUsers,
      icon: Icons.block,
      color: Colors.grey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MyText(
            LocaleKeys.blockedUsersCount,
            args: {'count': '$blockedCount'},
            color: theme.colorScheme.onSurfaceVariant,
            selectable: false,
          ),
          const SizedBox(height: 12),
          if (blockedCount == 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 48,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(height: 12),
                    MyText(
                      LocaleKeys.noBlockedUsers,
                      color: theme.colorScheme.onSurfaceVariant,
                      selectable: false,
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: blockedCount,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final userId = settings.blockedUserIds[index];
                return ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.person_outline),
                  ),
                   title: MyText(LocaleKeys.user, args: {'index': '${index + 1}'}, selectable: false),
                   subtitle: MyText(userId, noTranslation: true, selectable: false),
                  trailing: IconButton(
                    icon: const Icon(Icons.block_outlined),
                    onPressed: () => _showUnblockDialog(context, userId),
                    tooltip: context.tr(LocaleKeys.unblock),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    ThemeData theme, {
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 12),
                MyText(title, istitle: true,),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }

  Widget _buildDropdownSetting(
    BuildContext context,
    ThemeData theme, {
    required String title,
    required String subtitle,
    required IconData icon,
    required String value,
    required List<String> items,
    required Function(String) onChanged,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: MyText(title, selectable: false),
      subtitle: MyText(subtitle, selectable: false),
      trailing: DropdownButton<String>(
        value: value,
        underline: const SizedBox(),
        items: items.map((item) {
          return DropdownMenuItem(value: item, child: MyText(item));
        }).toList(),
        onChanged: (newValue) {
          if (newValue != null) {
            onChanged(newValue);
          }
        },
      ),
    );
  }

  void _showUnblockDialog(BuildContext context, String userId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: MyText(LocaleKeys.unblockUser),
        content: MyText(LocaleKeys.unblockUserConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: MyText(LocaleKeys.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<SettingsCubit>().unblockUser(userId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: MyText(LocaleKeys.unblock),
          ),
        ],
      ),
    );
  }
}
