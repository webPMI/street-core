import '../../../core/lang/context_tr.dart';
import '../../../core/lang/locale_keys.dart';
import 'comment_model.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

/// Widget mejorado para mostrar un comentario
///
/// Características:
/// - Animaciones suaves en interacciones
/// - Mejor jerarquía visual
/// - Soporte para menciones @usuario
/// - Indicadores visuales de respuestas anidadas
/// - Material Design 3
class CommentCard extends StatefulWidget {
  const CommentCard({
    super.key,
    required this.comment,
    this.onLike,
    this.onReply,
    this.onDelete,
    this.onEdit,
    this.onUserTap,
    this.onViewReplies,
  });

  final CommentModel comment;
  final VoidCallback? onLike;
  final VoidCallback? onReply;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onUserTap;
  final VoidCallback? onViewReplies;

  @override
  State<CommentCard> createState() => _CommentCardState();
}

class _CommentCardState extends State<CommentCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _likeAnimationController;
  late Animation<double> _likeScaleAnimation;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _likeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _likeScaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _likeAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _likeAnimationController.dispose();
    super.dispose();
  }

  void _handleLike() {
    _likeAnimationController.forward().then((_) {
      _likeAnimationController.reverse();
    });
    widget.onLike?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isReply = widget.comment.isReply;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.only(
          left: isReply ? 48 : 0,
          bottom: 8,
        ),
        decoration: BoxDecoration(
          color: _isHovering
              ? theme.colorScheme.surfaceVariant.withOpacity(0.3)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isReply
              ? Border(
                  left: BorderSide(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    width: 2,
                  ),
                )
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar with ripple effect
              _buildAvatar(context),

              const SizedBox(width: 12),

              // Comment content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 6),
                    _buildCommentText(context),
                    const SizedBox(height: 8),
                    _buildActions(context),
                    if (widget.comment.hasReplies)
                      _buildViewRepliesButton(context),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Like button with animation
              _buildLikeButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    return GestureDetector(
      onTap: widget.onUserTap,
      child: Hero(
        tag: 'avatar_${widget.comment.userId}',
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 20,
            backgroundImage: widget.comment.userAvatar != null &&
                    widget.comment.userAvatar!.isNotEmpty
                ? NetworkImage(widget.comment.userAvatar!)
                : null,
            child: widget.comment.userAvatar == null ||
                    widget.comment.userAvatar!.isEmpty
                ? Text(
                    widget.comment.userName.isNotEmpty
                        ? widget.comment.userName[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        // Username
        GestureDetector(
          onTap: widget.onUserTap,
          child: Text(
            widget.comment.userName,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),

        const SizedBox(width: 8),

        // Timestamp
        Text(
          timeago.format(widget.comment.createdAt, locale: 'es'),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),

        // Edited indicator
        if (widget.comment.isEdited) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              context.tr(LocaleKeys.edited),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCommentText(BuildContext context) {
    final theme = Theme.of(context);

    // Parse mentions and create styled text
    final spans = _parseMentions(widget.comment.text, theme);

    return RichText(
      text: TextSpan(
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface,
          height: 1.4,
        ),
        children: spans,
      ),
    );
  }

  List<TextSpan> _parseMentions(String text, ThemeData theme) {
    final List<TextSpan> spans = [];
    final mentionRegex = RegExp(r'@(\w+)');
    int currentIndex = 0;

    for (final match in mentionRegex.allMatches(text)) {
      // Add text before mention
      if (match.start > currentIndex) {
        spans.add(TextSpan(
          text: text.substring(currentIndex, match.start),
        ));
      }

      // Add mention with styling
      spans.add(TextSpan(
        text: match.group(0),
        style: TextStyle(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ));

      currentIndex = match.end;
    }

    // Add remaining text
    if (currentIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(currentIndex),
      ));
    }

    return spans.isEmpty ? [TextSpan(text: text)] : spans;
  }

  Widget _buildActions(BuildContext context) {
    final theme = Theme.of(context);

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [


        // Reply button - solo ícono
        if (widget.onReply != null)
          _IconOnlyButton(
            icon: Icons.reply,
            tooltip: context.tr(LocaleKeys.reply),
            onTap: widget.onReply,
          ),

        // Edit button - solo ícono
        if (widget.onEdit != null)
          _IconOnlyButton(
            icon: Icons.edit_outlined,
            tooltip: context.tr(LocaleKeys.edit),
            onTap: widget.onEdit,
          ),

        // Delete button - solo ícono
        if (widget.onDelete != null)
          _IconOnlyButton(
            icon: Icons.delete_outline,
            tooltip: context.tr(LocaleKeys.delete),
            onTap: widget.onDelete,
            color: theme.colorScheme.error,
          ),
      ],
    );
  }

  Widget _buildViewRepliesButton(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: GestureDetector(
        onTap: widget.onViewReplies,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24,
              height: 1,
              color: theme.colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.comment_outlined,
              size: 14,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 4),
            Text(
              '${context.tr(LocaleKeys.show)} ${widget.comment.repliesCount} ${widget.comment.repliesCount == 1 ? context.tr(LocaleKeys.viewReply) : context.tr(LocaleKeys.viewReplies)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLikeButton(BuildContext context) {
    final theme = Theme.of(context);
    final isLiked = widget.comment.isLikedByCurrentUser;
    final likesCount = widget.comment.likesCount;

    return ScaleTransition(
      scale: _likeScaleAnimation,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _handleLike,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  size: 20,
                  color: isLiked
                      ? theme.colorScheme.error
                      : theme.colorScheme.onSurfaceVariant,
                ),
                if (likesCount > 0) ...[
                  const SizedBox(width: 4),
                  Text(
                    '$likesCount',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isLiked
                          ? theme.colorScheme.error
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Botón de solo ícono (sin texto)
class _IconOnlyButton extends StatelessWidget {
  const _IconOnlyButton({
    required this.icon,
    required this.tooltip,
    this.onTap,
    this.color,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.colorScheme.onSurfaceVariant;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 18, color: effectiveColor),
        ),
      ),
    );
  }
}
