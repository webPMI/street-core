// lib/features/livestreams/widgets/stream_chat_input.dart

import 'package:flutter/material.dart';
import 'package:street_core/core/theme/app_spacing.dart';

/// Reusable chat input widget
///
/// Usage:
/// ```dart
/// StreamChatInput(
///   onSend: (message) => sendMessage(message),
///   hintText: 'Escribe un mensaje...',
/// )
/// ```
class StreamChatInput extends StatefulWidget {
  final Function(String message) onSend;
  final String hintText;
  final int maxLength;
  final bool enabled;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final Widget? leading;
  final Widget? trailing;
  final Color? backgroundColor;
  final bool showSendButton;

  const StreamChatInput({
    super.key,
    required this.onSend,
    this.hintText = 'Escribe un mensaje...',
    this.maxLength = 500,
    this.enabled = true,
    this.controller,
    this.focusNode,
    this.leading,
    this.trailing,
    this.backgroundColor,
    this.showSendButton = true,
  });

  @override
  State<StreamChatInput> createState() => _StreamChatInputState();
}

class _StreamChatInputState extends State<StreamChatInput> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();

    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  void _handleSend() {
    final message = _controller.text.trim();
    if (message.isEmpty) return;

    widget.onSend(message);
    _controller.clear();
    setState(() => _hasText = false);
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.backgroundColor ??
        Theme.of(context).colorScheme.surface.withValues(alpha: 0.95);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Leading widget (e.g., emoji picker button)
            if (widget.leading != null) ...[
              widget.leading!,
              SizedBox(width: AppSpacing.xs),
            ],

            // Text input
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                enabled: widget.enabled,
                maxLength: widget.maxLength,
                maxLines: null,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  counterText: '', // Hide character counter
                ),
                onSubmitted: widget.enabled ? (_) => _handleSend() : null,
              ),
            ),

            SizedBox(width: AppSpacing.xs),

            // Trailing widget (custom actions)
            if (widget.trailing != null) ...[
              widget.trailing!,
              SizedBox(width: AppSpacing.xs),
            ],

            // Send button
            if (widget.showSendButton)
              IconButton(
                onPressed: widget.enabled && _hasText ? _handleSend : null,
                icon: Icon(
                  Icons.send_rounded,
                  color: _hasText && widget.enabled
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).disabledColor,
                ),
                tooltip: 'Enviar',
              ),
          ],
        ),
      ),
    );
  }
}

/// Compact chat input (no border, minimal styling)
///
/// Usage:
/// ```dart
/// CompactChatInput(
///   onSend: (message) => sendMessage(message),
/// )
/// ```
class CompactChatInput extends StatefulWidget {
  final Function(String message) onSend;
  final String hintText;
  final bool enabled;

  const CompactChatInput({
    super.key,
    required this.onSend,
    this.hintText = 'Comentar...',
    this.enabled = true,
  });

  @override
  State<CompactChatInput> createState() => _CompactChatInputState();
}

class _CompactChatInputState extends State<CompactChatInput> {
  final _controller = TextEditingController();

  void _handleSend() {
    final message = _controller.text.trim();
    if (message.isEmpty) return;

    widget.onSend(message);
    _controller.clear();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            enabled: widget.enabled,
            maxLines: 1,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: widget.hintText,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
            ),
            onSubmitted: widget.enabled ? (_) => _handleSend() : null,
          ),
        ),
        IconButton(
          onPressed: widget.enabled ? _handleSend : null,
          icon: Icon(
            Icons.send,
            size: 20,
            color: widget.enabled
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).disabledColor,
          ),
        ),
      ],
    );
  }
}
