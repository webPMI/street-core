// lib/presentation/dashboard/posts/widgets/post_caption.dart

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../../core/widgets/my_text.dart';

/// Widget para mostrar el caption con hashtags y menciones clickeables
class PostCaption extends StatefulWidget {
  const PostCaption({
    super.key,
    required this.userName,
    required this.caption,
    this.tags = const [],
    this.mentions = const [],
    this.maxLines = 3,
    this.onHashtagTap,
    this.onMentionTap,
    this.onUserNameTap,
  });
  final String userName;
  final String caption;
  final List<String> tags;
  final List<String> mentions;
  final int maxLines;
  final void Function(String hashtag)? onHashtagTap;
  final void Function(String username)? onMentionTap;
  final VoidCallback? onUserNameTap;

  @override
  State<PostCaption> createState() => _PostCaptionState();
}

class _PostCaptionState extends State<PostCaption> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            maxLines: _isExpanded ? null : widget.maxLines,
            overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
            text: TextSpan(
              style: DefaultTextStyle.of(context).style,
              children: [
                // Username en bold
                TextSpan(
                  text: '${widget.userName} ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  recognizer: widget.onUserNameTap != null
                      ? (TapGestureRecognizer()..onTap = widget.onUserNameTap)
                      : null,
                ),

                // Caption con hashtags y menciones
                ..._buildCaptionSpans(),
              ],
            ),
          ),

          // Botón "ver más" / "ver menos"
          if (widget.caption.length > 100)
            GestureDetector(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: MyText(
                  _isExpanded ? 'ver menos' : 'ver más',
                  selectable: false,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<TextSpan> _buildCaptionSpans() {
    final List<TextSpan> spans = [];
    final words = widget.caption.split(' ');

    for (int i = 0; i < words.length; i++) {
      final word = words[i];

      if (word.startsWith('#')) {
        // Hashtag
        spans.add(
          TextSpan(
            text: '$word ',
            style: const TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.w500,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                final hashtag = word.substring(1); // Remove #
                widget.onHashtagTap?.call(hashtag);
              },
          ),
        );
      } else if (word.startsWith('@')) {
        // Mención
        spans.add(
          TextSpan(
            text: '$word ',
            style: const TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.w500,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                final username = word.substring(1); // Remove @
                widget.onMentionTap?.call(username);
              },
          ),
        );
      } else {
        // Texto normal
        spans.add(TextSpan(text: '$word '));
      }
    }

    return spans;
  }
}
