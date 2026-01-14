// lib/presentation/dashboard/profile/pages/user_profile_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
import '../../../core/helpers/snackbar_helper.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/router/navigation_service.dart';
import '../../../core/widgets/my_button.dart';
import '../../../core/widgets/my_text.dart';
import '../bloc/user_posts_cubit.dart';
import '../bloc/user_posts_state.dart';
import '../bloc/user_profile_cubit.dart';
import '../bloc/user_profile_state.dart';
import '../../../core/lang/locale_keys.dart';
import '../../../core/lang/context_tr.dart';
import '../posts/widgets/post_grid_item.dart';
import '../profile_routes.dart';

/// Public user profile page for viewing other users' profiles
class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key, required this.userId});
  final String userId;

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      // Load more when scrolled 80% down
      context.read<UserPostsCubit>().loadMore(widget.userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              getIt<UserProfileCubit>()..fetchUserProfile(widget.userId),
        ),
        BlocProvider(
          create: (context) =>
              getIt<UserPostsCubit>()..fetchUserPosts(widget.userId),
        ),
      ],
      child: BlocListener<UserProfileCubit, UserProfileState>(
        listener: (context, state) {
          if (state is UserProfileFollowSuccess) {
            SnackBarHelper.showSuccess(
              context,
              state.isFollowing ? LocaleKeys.userFollowed : LocaleKeys.userUnfollowed,
            );
          } else if (state is UserProfileError) {
            SnackBarHelper.showError(context, state.message);
          }
        },
        child: BlocBuilder<UserProfileCubit, UserProfileState>(
          builder: (context, state) {
            final userName = state is UserProfileLoaded
                ? state.user.firstName
                : (state is UserProfileFollowSuccess
                      ? state.user.firstName
                      : '');

            return Scaffold(
              appBar: AppBar(
                title: Row(
                  children: [
                    const Icon(Icons.person),
                    const SizedBox(width: 8),
                    MyText(userName),
                  ],
                ),
              ),
              body: RefreshIndicator(
                onRefresh: () async {
                  await Future.wait([
                    context.read<UserProfileCubit>().fetchUserProfile(
                      widget.userId,
                    ),
                    context.read<UserPostsCubit>().refresh(widget.userId),
                  ]);
                },
                child: CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    // User stats and bio
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          _buildProfileInfo(context),
                          const Divider(height: 1),
                        ],
                      ),
                    ),

                    // Posts grid
                    _buildPostsGrid(context),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Build profile info section
  Widget _buildProfileInfo(BuildContext context) {
    return BlocBuilder<UserProfileCubit, UserProfileState>(
      builder: (context, state) {
        if (state is UserProfileLoading) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          );
        } else if (state is UserProfileLoaded ||
            state is UserProfileFollowSuccess) {
          final user = state is UserProfileLoaded
              ? state.user
              : (state as UserProfileFollowSuccess).user;
          final isFollowing = state is UserProfileLoaded
              ? state.isFollowing
              : (state as UserProfileFollowSuccess).isFollowing;
          final followersCount = state is UserProfileLoaded
              ? state.followersCount
              : (state as UserProfileFollowSuccess).followersCount;
          final followingCount = state is UserProfileLoaded
              ? state.followingCount
              : (state as UserProfileFollowSuccess).followingCount;
          final postsCount = state is UserProfileLoaded
              ? state.postsCount
              : (state as UserProfileFollowSuccess).postsCount;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Avatar and stats row
                Row(
                  children: [
                    // Avatar
                    CircleAvatar(
                      radius: 40,
                      backgroundImage:
                          user.imageUrl != null && user.imageUrl!.isNotEmpty
                          ? NetworkImage(user.imageUrl!)
                          : null,
                      child: user.imageUrl == null || user.imageUrl!.isEmpty
                          ? const Icon(Icons.person, size: 40)
                          : null,
                    ),
                    const SizedBox(width: 24),

                    // Stats
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatColumn(context, postsCount, LocaleKeys.posts),
                          _buildStatColumn(
                            context,
                            followersCount,
                            LocaleKeys.followers,
                          ),
                          _buildStatColumn(
                            context,
                            followingCount,
                            LocaleKeys.following,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Bio
                if (user.bio != null && user.bio!.isNotEmpty)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: MyText(user.bio!, fontSize: 14, maxLines: 5),
                  ),

                const SizedBox(height: 16),

                // Action buttons
                Row(
                  children: [
                    // Follow/Unfollow button
                    Expanded(
                      flex: 2,
                      child: MyButton(
                        text: isFollowing ? LocaleKeys.unfollow : LocaleKeys.follow,
                        onPressed: () {
                          context.read<UserProfileCubit>().toggleFollow(
                            widget.userId,
                          );
                        },
                        backgroundColor: isFollowing
                            ? Colors.grey[300]
                            : Theme.of(context).primaryColor,
                        textColor: isFollowing ? Colors.black : Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Send Message button
                    Expanded(
                      flex: 1,
                      child: Semantics(
                        label: context.tr(LocaleKeys.sendMessage),
                        button: true,
                        child: MyButton(
                          text: LocaleKeys.sendMessage,
                          onPressed: () {
                            context.push(
                              AppRoutes.chat,
                              extra: widget.userId,
                            );
                          },
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.secondaryContainer,
                          textColor: Theme.of(
                            context,
                          ).colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        } else if (state is UserProfileError) {
          return Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  MyText(state.message, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  MyButton(
                    text: LocaleKeys.retry,
                    onPressed: () {
                      context.read<UserProfileCubit>().fetchUserProfile(
                        widget.userId,
                      );
                      context.read<UserPostsCubit>().fetchUserPosts(
                        widget.userId,
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  /// Build stat column (posts/followers/following)
  Widget _buildStatColumn(BuildContext context, int count, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          count.toString(),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        MyText(label, fontSize: 12, selectable: false),
      ],
    );
  }

  /// Build posts grid
  Widget _buildPostsGrid(BuildContext context) {
    return BlocBuilder<UserPostsCubit, UserPostsState>(
      builder: (context, state) {
        if (state is UserPostsLoading) {
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          );
        } else if (state is UserPostsLoaded || state is UserPostsLoadingMore) {
          final posts = state is UserPostsLoaded
              ? state.posts
              : (state as UserPostsLoadingMore).currentPosts;

          if (posts.isEmpty) {
            return const SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.grid_on, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    MyText(LocaleKeys.noPostsYet, fontSize: 16),
                  ],
                ),
              ),
            );
          }

          return SliverPadding(
            padding: const EdgeInsets.all(2),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index < posts.length) {
                    return PostGridItem(
                      post: posts[index],
                      onTap: () {
                        NavigationService().go(
                          context,
                          ProfileRoutes.getPostDetail(posts[index].id),
                        );
                      },
                    );
                  } else if (state is UserPostsLoadingMore) {
                    // Show loading indicator at the end
                    return const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    );
                  }
                  return null;
                },
                childCount:
                    posts.length + (state is UserPostsLoadingMore ? 1 : 0),
              ),
            ),
          );
        } else if (state is UserPostsEmpty) {
          return const SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.grid_on, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  MyText(LocaleKeys.noPostsYet, fontSize: 16),
                ],
              ),
            ),
          );
        } else if (state is UserPostsError) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  MyText(state.message, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  MyButton(
                    text: LocaleKeys.retry,
                    onPressed: () {
                      context.read<UserPostsCubit>().fetchUserPosts(
                        widget.userId,
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        }

        return const SliverFillRemaining(child: SizedBox.shrink());
      },
    );
  }
}
