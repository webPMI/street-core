// lib/features/social/comment/widgets/comments_list_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../comment_card.dart';
import '../comment_model.dart';
import '../comments_cubit.dart';
import '../comments_state.dart';
import '../../../../core/theme/app_spacing.dart';

/// Widget de lista de comentarios con scroll infinito
///
/// Características:
/// - Scroll infinito automático
/// - Indicador de "cargando más"
/// - Pull to refresh
/// - Estado vacío
/// - Manejo de errores
class CommentsListWidget extends StatefulWidget {
  const CommentsListWidget({
    super.key,
    required this.postId,
    this.onReply,
    this.onUserTap,
    this.onViewReplies,
  });

  final String postId;
  final Function(CommentModel)? onReply;
  final Function(String userId)? onUserTap;
  final Function(CommentModel)? onViewReplies;

  @override
  State<CommentsListWidget> createState() => _CommentsListWidgetState();
}

class _CommentsListWidgetState extends State<CommentsListWidget> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<CommentsCubit>().loadMoreComments(widget.postId);
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9); // Load when 90% scrolled
  }

  Future<void> _onRefresh() async {
    await context.read<CommentsCubit>().refreshComments(widget.postId);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CommentsCubit, CommentsState>(
      builder: (context, state) {
        if (state is CommentsLoading) {
          return _buildLoadingState();
        }

        if (state is CommentsError) {
          return _buildErrorState(context, state.message);
        }

        if (state is CommentsLoaded) {
          return _buildLoadedState(context, state);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              'Error al cargar comentarios',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.md),
            ElevatedButton.icon(
              onPressed: () => _onRefresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadedState(BuildContext context, CommentsLoaded state) {
    if (state.comments.isEmpty) {
      return _buildEmptyState(context);
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Header con contador de comentarios
          SliverToBoxAdapter(
            child: _buildHeader(context, state),
          ),

          // Lista de comentarios
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final comment = state.comments[index];
                return CommentCard(
                  comment: comment,
                  onLike: () => context
                      .read<CommentsCubit>()
                      .toggleLike(comment.id),
                  onReply: widget.onReply != null
                      ? () => widget.onReply!(comment)
                      : null,
                  onUserTap: widget.onUserTap != null
                      ? () => widget.onUserTap!(comment.userId)
                      : null,
                  onViewReplies: widget.onViewReplies != null &&
                          comment.hasReplies
                      ? () => widget.onViewReplies!(comment)
                      : null,
                );
              },
              childCount: state.comments.length,
            ),
          ),

          // Loading indicator o "No hay más comentarios"
          SliverToBoxAdapter(
            child: _buildBottomIndicator(context, state),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                  ),
                  SizedBox(height: AppSpacing.md),
                  Text(
                    'No hay comentarios aún',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    'Sé el primero en comentar',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, CommentsLoaded state) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.comment,
            size: 20,
            color: theme.colorScheme.primary,
          ),
          SizedBox(width: AppSpacing.sm),
          Text(
            '${state.totalComments} ${state.totalComments == 1 ? 'comentario' : 'comentarios'}',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (state.comments.length < state.totalComments) ...[
            SizedBox(width: AppSpacing.sm),
            Text(
              '(${state.comments.length} cargados)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomIndicator(BuildContext context, CommentsLoaded state) {
    final theme = Theme.of(context);

    // Mostrar indicador de carga si está cargando más
    if (state.isLoadingMore) {
      return Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary,
                ),
              ),
            ),
            SizedBox(width: AppSpacing.md),
            Text(
              'Cargando más comentarios...',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    // Mostrar "No hay más comentarios" si no hay más
    if (!state.hasMoreComments && state.comments.isNotEmpty) {
      return Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 1,
              color: theme.colorScheme.outlineVariant,
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Icon(
                Icons.check_circle_outline,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              'No hay más comentarios',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Icon(
                Icons.check_circle_outline,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Container(
              width: 40,
              height: 1,
              color: theme.colorScheme.outlineVariant,
            ),
          ],
        ),
      );
    }

    // Espacio adicional al final
    return SizedBox(height: AppSpacing.lg);
  }
}
