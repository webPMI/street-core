import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
import '../../../core/lang/context_tr.dart';
import '../../../core/lang/locale_keys.dart';
import '../../../core/router/navigation_service.dart';
import '../../../core/widgets/drawer/my_drawer.dart';
import '../../../core/widgets/my_button.dart';
import '../../../core/widgets/my_text.dart';
import '../../auth/auth.dart';
import '../bloc/user_posts_cubit.dart';
import '../bloc/user_posts_state.dart';
import '../profile_routes.dart';
import '../posts/widgets/post_card.dart';
import '../widgets/profile_action_buttons.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_stats.dart';
import '../widgets/stories_highlights.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late UserPostsCubit _userPostsCubit;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _userPostsCubit = getIt<UserPostsCubit>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userState = context.read<UserCubit>().state;
      if (userState is UserLoaded) {
        final userId = userState.user.id;
        if (userId.isEmpty) {
          return;
        }
        _userPostsCubit.fetchUserPosts(userId);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _userPostsCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userState = context.watch<UserCubit>().state;

    return Scaffold(
      drawer: MyDrawer(),
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.person),
            const SizedBox(width: 8),
            const MyText(LocaleKeys.profile),
          ],
        ),
      ),
      body: BlocProvider.value(
        value: _userPostsCubit,
        child: userState is UserLoading
            ? const Center(child: CircularProgressIndicator())
            : userState is UserError
            ? Center(
                child: MyText(
                  "${context.tr(LocaleKeys.error)}: ${context.tr(userState.message)}",
                ),
              )
            : userState is UserLoaded
            ? _buildProfileContent(context, theme, userState)
            : const Center(child: MyText(LocaleKeys.noUserData)),
      ),
    );
  }

  Widget _buildProfileContent(
    BuildContext context,
    ThemeData theme,
    UserLoaded userState,
  ) {
    final user = userState.user;

    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 16),
                // Profile Header (username, name, badges, bio, member since)
                ProfileHeader(user: user),

                const SizedBox(height: 16),
                // Stats Row (posts, followers, following)
                Divider(),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      //  ProfileImage(onImageSelected: (ImageLoadResult image) {}),
                      const SizedBox(width: 24),
                      Expanded(
                        child: ProfileStatsRow(
                          postsCount: _getPostsCount(),
                          followersCount: user.followersCount.toString(),
                          followingCount: user.followingCount.toString(),
                          onFollowersTap: () =>
                              _navigateToFollowers(context, user),
                          onFollowingTap: () =>
                              _navigateToFollowing(context, user),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Action Buttons (create post, add story, edit profile)
                Divider(),
                const SizedBox(height: 6),
                const ProfileActionButtons(),
                const SizedBox(height: 16),
                // Stories/Highlights Section
                const StoriesHighlights(),
                const SizedBox(height: 8),
                TabBar(
                  controller: _tabController,
                  tabs: [
                    Tab(
                      icon: const Icon(Icons.grid_on),
                      text: context.tr(LocaleKeys.posts),
                    ),
                    Tab(
                      icon: const Icon(Icons.bookmark_border),
                      text: context.tr(LocaleKeys.saved),
                    ),
                    Tab(
                      icon: const Icon(Icons.person_pin_outlined),
                      text: context.tr(LocaleKeys.tagged),
                    ),
                  ],
                  labelColor: theme.colorScheme.primary,
                  unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                  indicatorColor: theme.colorScheme.primary,
                ),
              ],
            ),
          ),
        ];
      },
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPostsGrid(context),
          _buildSavedPostsTab(context),
          _buildPlaceholderTab(
            context,
            LocaleKeys.taggedPostsComingSoon,
            Icons.person_pin,
          ),
        ],
      ),
    );
  }

  String _getPostsCount() {
    // Use actual posts count from user model, not loaded posts count
    final userState = context.read<UserCubit>().state;
    if (userState is UserLoaded) {
      return userState.user.postsCount.toString();
    }
    return '0';
  }

  Widget _buildPostsGrid(BuildContext context) {
    return BlocBuilder<UserPostsCubit, UserPostsState>(
      builder: (context, state) {
        if (state is UserPostsLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is UserPostsError) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 12),
                  MyText(state.message, fontSize: 14),
                  const SizedBox(height: 12),
                  MyButton(
                    text: LocaleKeys.retry,
                    onPressed: () {
                      final userState = context.read<UserCubit>().state;
                      if (userState is UserLoaded) {
                        _userPostsCubit.refresh(userState.user.id);
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        }
        if (state is UserPostsEmpty) {
          return _buildEmptyPostsState(context);
        }
        if (state is UserPostsLoaded) {
          // Responsive width: Center content on desktop/tablet (Instagram-like)
          final screenWidth = MediaQuery.of(context).size.width;
          final maxWidth = screenWidth > 900 ? 600.0 : double.infinity;

          return RefreshIndicator(
            onRefresh: () async {
              final userState = context.read<UserCubit>().state;
              if (userState is UserLoaded) {
                await _userPostsCubit.refresh(userState.user.id);
              }
            },
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 8),
                  itemCount: state.posts.length,
                  itemBuilder: (context, index) {
                    final post = state.posts[index];
                    return PostCard(
                      post: post,
                      onLike: () => _userPostsCubit.toggleLike(post.id),
                      onComment: () => context.push(
                        ProfileRoutes.getPostDetail(post.id),
                      ),
                      onSave: () => _userPostsCubit.toggleSave(post.id),
                      onShare: () => _showShareDialog(context, post.id),
                      onDelete: () => _showDeleteDialog(context, post.id),
                      onPostTap: () => context.push(
                        ProfileRoutes.getPostDetail(post.id),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildEmptyPostsState(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            const MyText(LocaleKeys.noPostsYet, istitle: true, fontSize: 16),
            const SizedBox(height: 8),
            MyText(
              LocaleKeys.shareYourFirstPost,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 14,
            ),
            const SizedBox(height: 16),
            MyButton(
              text: LocaleKeys.createPost,
              onPressed: () =>
                  NavigationService().go(context, ProfileRoutes.postCreate),
              icon: Icons.add_photo_alternate,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedPostsTab(BuildContext context) {
    // Navigate to dedicated saved posts page instead of embedding
    // This provides better UX and performance
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.bookmark,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 12),
              MyText(
                LocaleKeys.viewSavedPosts,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              const SizedBox(height: 6),
              MyText(
                LocaleKeys.tapBelowToViewSaved,
                textAlign: TextAlign.center,
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => context.push(ProfileRoutes.savedPosts),
                icon: const Icon(Icons.bookmark, size: 18),
                label: MyText(LocaleKeys.viewSavedPosts, fontSize: 14),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderTab(
    BuildContext context,
    String messageKey,
    IconData icon,
  ) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            MyText(
              messageKey,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 14,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToFollowers(BuildContext context, User user) {
    context.push(ProfileRoutes.getUserFollowers(user.id));
  }

  void _navigateToFollowing(BuildContext context, User user) {
    context.push(ProfileRoutes.getUserFollowing(user.id));
  }

  void _showDeleteDialog(BuildContext context, String postId) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error),
            const SizedBox(width: 12),
            MyText(LocaleKeys.deletePost, selectable: false),
          ],
        ),
        content: MyText(LocaleKeys.deletePostConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: MyText(LocaleKeys.cancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _userPostsCubit.deletePost(postId);
            },
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
            ),
            child: MyText(LocaleKeys.delete, color: theme.colorScheme.onError),
          ),
        ],
      ),
    );
  }

  void _showShareDialog(BuildContext context, String postId) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.share, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            MyText(LocaleKeys.sharePost, selectable: false),
          ],
        ),
        content: MyText(LocaleKeys.shareFeatureComingSoon),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: MyText(LocaleKeys.ok),
          ),
        ],
      ),
    );
  }
}
