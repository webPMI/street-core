// lib/presentation/dashboard/posts/pages/post_detail_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:street_core/core/lang/context_tr.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/helpers/logger.dart';
import '../../../../core/helpers/snackbar_helper.dart';
import '../../../../core/lang/locale_keys.dart';
import '../../../../core/widgets/my_text.dart';
import '../../../social/comment/comments_cubit.dart';
import '../../../social/comment/comments_state.dart';
import '../bloc/post_detail_cubit.dart';
import '../bloc/post_detail_state.dart';
import '../../../social/comment/comment_card.dart';
import '../../../social/comment/comment_input_field.dart';
import '../widgets/post_card.dart';

/// Página de detalle de un post con comentarios
class PostDetailPage extends StatelessWidget {
  const PostDetailPage({super.key, required this.postId});
  final String postId;

  @override
  Widget build(BuildContext context) {
    AppLogger.info('[PostDetailPage] Opening post detail: $postId', tag: 'Comments');

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) {
            AppLogger.debug('[PostDetailPage] Creating PostDetailCubit', tag: 'Comments');
            return getIt<PostDetailCubit>()..fetchPost(postId);
          },
        ),
        BlocProvider(
          create: (_) {
            AppLogger.debug('[PostDetailPage] Creating CommentsCubit', tag: 'Comments');
            return getIt<CommentsCubit>()..fetchComments(postId);
          },
        ),
      ],
      child: const _PostDetailView(),
    );
  }
}

class _PostDetailView extends StatelessWidget {
  const _PostDetailView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.article),
            const SizedBox(width: 8),
            const MyText(LocaleKeys.post),
          ],
        ),
        actions: [
          BlocBuilder<PostDetailCubit, PostDetailState>(
            builder: (context, state) {
              if (state is PostDetailLoaded) {
                return PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'delete') {
                      _showDeleteDialog(context, state.post.id);
                    } else if (value == 'share') {
                      // Implementar funcionalidad de compartir
                      //
                      SnackBarHelper.showSuccess(
                        context,
                        LocaleKeys.notFound,
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value:context.tr(LocaleKeys.share) ,
                      child: Row(
                        children: [
                          const Icon(Icons.share),
                          const SizedBox(width: 8),
                          MyText(LocaleKeys.share, selectable: false),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value:context.tr(LocaleKeys.delete) ,
                      child: Row(
                        children: [
                          const Icon(Icons.delete, color: Colors.red),
                          const SizedBox(width: 8),
                          MyText(LocaleKeys.delete, color: Colors.red, selectable: false),
                        ],
                      ),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Post content
          Expanded(
            child: BlocConsumer<PostDetailCubit, PostDetailState>(
              listener: (context, state) {
                if (state is PostDetailActionSuccess) {
                  SnackBarHelper.showSuccess(context, LocaleKeys.postActionSuccess);
                  Navigator.pop(context);
                } else if (state is PostDetailError) {
                  SnackBarHelper.showError(context, LocaleKeys.postError);
                }
              },
              builder: (context, postState) {
                return SingleChildScrollView(
                  child: Column(
                    children: [
                      // Post
                      if (postState is PostDetailLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (postState is PostDetailLoaded)
                        PostCard(
                          post: postState.post,
                          onLike: () =>
                              context.read<PostDetailCubit>().toggleLike(),
                          onDelete: () =>
                              _showDeleteDialog(context, postState.post.id),
                        ),

                      const Divider(height: 1),

                      // Comments section
                      BlocConsumer<CommentsCubit, CommentsState>(
                        listener: (context, commentsState) {
                          AppLogger.debug('[PostDetailPage] Comments state changed: ${commentsState.runtimeType}', tag: 'Comments');

                          if (commentsState is CommentsActionSuccess) {
                            AppLogger.info('[PostDetailPage] Comment action success: ${commentsState.message}', tag: 'Comments');
                            SnackBarHelper.showSuccess(
                              context,
                              LocaleKeys.commentAdded,
                            );
                            // Actualizar contador de comentarios
                            context
                                .read<PostDetailCubit>()
                                .incrementCommentsCount();
                          } else if (commentsState is CommentsError) {
                            AppLogger.error('[PostDetailPage] Comments error: ${commentsState.message}', tag: 'Comments');
                          }
                        },
                        builder: (context, commentsState) {
                          if (commentsState is CommentsLoading) {
                            return const Padding(
                              padding: EdgeInsets.all(32),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          if (commentsState is CommentsLoaded) {
                            if (commentsState.comments.isEmpty) {
                              return Padding(
                                padding: const EdgeInsets.all(32),
                                child: Center(child: MyText(LocaleKeys.noCommentsYet)),
                              );
                            }

                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: commentsState.comments.length,
                              itemBuilder: (context, index) {
                                final comment = commentsState.comments[index];
                                return CommentCard(
                                  comment: comment,
                                  onLike: () => context
                                      .read<CommentsCubit>()
                                      .toggleLike(comment.id),
                                  onDelete: () => _showDeleteCommentDialog(
                                    context,
                                    comment.id,
                                  ),
                                );
                              },
                            );
                          }

                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Comment input
          BlocBuilder<CommentsCubit, CommentsState>(
            builder: (context, state) {
              final isSubmitting =
                  state is CommentsLoaded && state.isSubmitting;

              return CommentInputField(
                isSubmitting: isSubmitting,
                onSubmit: (text) {
                  AppLogger.info('[PostDetailPage] Comment input submitted: "$text"', tag: 'Comments');

                  final postState = context.read<PostDetailCubit>().state;
                  AppLogger.debug('[PostDetailPage] Post state: ${postState.runtimeType}', tag: 'Comments');

                  if (postState is PostDetailLoaded) {
                    AppLogger.debug('[PostDetailPage] Calling addComment on cubit', tag: 'Comments');
                    context.read<CommentsCubit>().addComment(
                      postState.post.id,
                      text,
                    );
                  } else {
                    AppLogger.warning('[PostDetailPage] Cannot add comment - post not loaded', tag: 'Comments');
                  }
                },
              );
            },
          ),
        ],
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
              context.read<PostDetailCubit>().deletePost();
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

  void _showDeleteCommentDialog(BuildContext context, String commentId) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error),
            const SizedBox(width: 12),
            MyText(LocaleKeys.deleteComment, selectable: false),
          ],
        ),
        content: MyText(LocaleKeys.deleteCommentConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: MyText(LocaleKeys.cancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<CommentsCubit>().deleteComment(commentId);
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
}
