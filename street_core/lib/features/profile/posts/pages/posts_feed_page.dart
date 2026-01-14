// lib/features/profile/posts/pages/posts_feed_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/helpers/responsive/responsive_helper.dart';
import '../../../../core/helpers/snackbar_helper.dart';
import '../../../../core/lang/context_tr.dart';
import '../../../../core/lang/locale_keys.dart';
import '../../../../core/router/navigation_service.dart';
import '../../../../core/widgets/drawer/my_drawer.dart';
import '../../../../core/widgets/my_text.dart';
import '../../profile_routes.dart';
import '../bloc/posts_feed_cubit.dart';
import '../bloc/posts_feed_state.dart';
import '../widgets/post_card.dart';

/// Main posts feed page
class PostsFeedPage extends StatelessWidget {
  const PostsFeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<PostsFeedCubit>()..fetchFeed(),
      child: const _PostsFeedView(),
    );
  }
}

class _PostsFeedView extends StatefulWidget {
  const _PostsFeedView();

  @override
  State<_PostsFeedView> createState() => _PostsFeedViewState();
}

class _PostsFeedViewState extends State<_PostsFeedView> {
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
    if (_isBottom) {
      context.read<PostsFeedCubit>().loadMorePosts();
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final responsive = ResponsiveHelper(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.dynamic_feed),
            const SizedBox(width: 8),
            const MyText(LocaleKeys.feed),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined),
            onPressed: () {
              context.push(ProfileRoutes.postCreate);
            },
            tooltip: context.tr(LocaleKeys.createPost),
          ),
        ],
      ),
      drawer: MyDrawer(),
      body: BlocConsumer<PostsFeedCubit, PostsFeedState>(
        listener: (context, state) {
          if (state is PostsFeedActionSuccess) {
            SnackBarHelper.showSuccess(context, state.message);
          } else if (state is PostsFeedError) {
            SnackBarHelper.showError(context, state.message);
          }
        },
        builder: (context, state) {
          if (state is PostsFeedLoading) {
            return _postLoading(theme);
          }

          if (state is PostsFeedError) {
            return _postError(responsive, theme, state, context);
          }

          if (state is PostsFeedLoaded) {
            if (state.posts.isEmpty) {
              return _postEmpty(responsive, theme, context);
            }

            // Responsive layout: Center content on desktop/tablet
            final maxWidth = responsive.isDesktop ? 800.0 : double.infinity;

            return _postBody(context, maxWidth, responsive, state);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  RefreshIndicator _postBody(
    BuildContext context,
    double maxWidth,
    ResponsiveHelper responsive,
    PostsFeedLoaded state,
  ) {
    return RefreshIndicator(
      onRefresh: () => context.read<PostsFeedCubit>().refreshFeed(),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: ListView.builder(
            controller: _scrollController,
            padding: responsive.pagePadding,
            itemCount: state.posts.length + (state.isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= state.posts.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final post = state.posts[index];
              return PostCard(
                post: post,
                onLike: () =>
                    context.read<PostsFeedCubit>().toggleLike(post.id),
                onComment: () {
                  context.push(ProfileRoutes.getPostDetail(post.id));
                },
                onSave: () =>
                    context.read<PostsFeedCubit>().toggleSave(post.id),
                onShare: () => _showShareDialog(context, post.id),
                onDelete: () => _showDeleteDialog(context, post.id),
                onPostTap: () {
                  context.push(ProfileRoutes.getPostDetail(post.id));
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Center _postLoading(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          MyText(LocaleKeys.loading, color: theme.colorScheme.onSurfaceVariant),
        ],
      ),
    );
  }

  Center _postError(
    ResponsiveHelper responsive,
    ThemeData theme,
    PostsFeedError state,
    BuildContext context,
  ) {
    return Center(
      child: Padding(
        padding: responsive.pagePadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 64,
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 24),
            MyText(
              LocaleKeys.errorLoadingPosts,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            MyText(
              state.message,
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.read<PostsFeedCubit>().fetchFeed(),
              icon: const Icon(Icons.refresh),
              label: MyText(LocaleKeys.retry),
            ),
          ],
        ),
      ),
    );
  }

  Center _postEmpty(
    ResponsiveHelper responsive,
    ThemeData theme,
    BuildContext context,
  ) {
    return Center(
      child: Padding(
        padding: responsive.pagePadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.3,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.post_add,
                size: 64,
                color: theme.colorScheme.primary.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 24),
            MyText(
              LocaleKeys.noPostsYet,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            MyText(
              LocaleKeys.noPostsAvailable,
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                NavigationService().go(context, ProfileRoutes.postCreate);
              },
              icon: const Icon(Icons.add),
              label: MyText(LocaleKeys.createFirstPost),
            ),
          ],
        ),
      ),
    );
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
            MyText(LocaleKeys.deletePost),
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
              context.read<PostsFeedCubit>().deletePost(postId);
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
            MyText(LocaleKeys.sharePost),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.link),
              title: MyText(LocaleKeys.copyLink),
              onTap: () {
                Navigator.pop(dialogContext);
                SnackBarHelper.showInfo(context, LocaleKeys.linkCopied);
              },
            ),
            ListTile(
              leading: const Icon(Icons.message),
              title: MyText(LocaleKeys.shareViaMessage),
              onTap: () {
                Navigator.pop(dialogContext);
                SnackBarHelper.showInfo(context, LocaleKeys.featureComingSoon);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: MyText(LocaleKeys.cancel),
          ),
        ],
      ),
    );
  }
}
