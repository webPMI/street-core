// lib/presentation/dashboard/posts/widgets/comment_input_field.dart

import '../../../core/helpers/logger.dart';
import 'package:flutter/material.dart';

/// Widget para el campo de entrada de comentarios
class CommentInputField extends StatefulWidget {

  const CommentInputField({
    super.key,
    this.userAvatar,
    this.hintText = 'Escribe un comentario...',
    this.isSubmitting = false,
    required this.onSubmit,
    this.onCancel,
  });
  final String? userAvatar;
  final String hintText;
  final bool isSubmitting;
  final Function(String) onSubmit;
  final VoidCallback? onCancel;

  @override
  State<CommentInputField> createState() => _CommentInputFieldState();
}

class _CommentInputFieldState extends State<CommentInputField> {
  final TextEditingController _controller = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    AppLogger.debug('[CommentInputField] Widget initialized', tag: 'Comments');
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    AppLogger.debug('[CommentInputField] Widget disposed', tag: 'Comments');
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _hasText = _controller.text.trim().isNotEmpty;
    });
  }

  void _handleSubmit() {
    final text = _controller.text.trim();

    AppLogger.debug('[CommentInputField] Submit attempted', tag: 'Comments');
    AppLogger.debug('[CommentInputField] Text length: ${text.length}', tag: 'Comments');
    AppLogger.debug('[CommentInputField] Is submitting: ${widget.isSubmitting}', tag: 'Comments');

    if (text.isEmpty) {
      AppLogger.warning('[CommentInputField] Submit blocked - text is empty', tag: 'Comments');
      return;
    }

    if (widget.isSubmitting) {
      AppLogger.warning('[CommentInputField] Submit blocked - already submitting', tag: 'Comments');
      return;
    }

    AppLogger.info('[CommentInputField] Submitting comment: "$text"', tag: 'Comments');
    widget.onSubmit(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // User avatar
            CircleAvatar(
              radius: 18,
              backgroundImage: widget.userAvatar != null &&
                      widget.userAvatar!.isNotEmpty
                  ? NetworkImage(widget.userAvatar!)
                  : null,
              child: widget.userAvatar == null || widget.userAvatar!.isEmpty
                  ? const Icon(Icons.person, size: 20)
                  : null,
            ),

            const SizedBox(width: 12),

            // Input field
            Expanded(
              child: TextField(
                controller: _controller,
                enabled: !widget.isSubmitting,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  isDense: true,
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _handleSubmit(),
              ),
            ),

            const SizedBox(width: 8),

            // Send button
            if (widget.isSubmitting)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              IconButton(
                icon: Icon(
                  Icons.send,
                  color: _hasText
                      ? Theme.of(context).primaryColor
                      : Colors.grey[400],
                ),
                onPressed: _hasText ? _handleSubmit : null,
                iconSize: 24,
              ),
          ],
        ),
      ),
    );
  }
}
