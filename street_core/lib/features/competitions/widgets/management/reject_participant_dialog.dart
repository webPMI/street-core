/// Diálogo para rechazar participante con motivo opcional
/// Following Monolith-by-Features architecture (ADR-005).

import 'package:flutter/material.dart';
import '../../../../core/lang/context_tr.dart';
import '../../../../core/lang/locale_keys.dart';

/// Muestra el diálogo de rechazo y retorna el motivo (o null si se cancela)
Future<String?> showRejectParticipantDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (context) => const RejectParticipantDialog(),
  );
}

class RejectParticipantDialog extends StatefulWidget {
  const RejectParticipantDialog({super.key});

  @override
  State<RejectParticipantDialog> createState() => _RejectParticipantDialogState();
}

class _RejectParticipantDialogState extends State<RejectParticipantDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.tr(LocaleKeys.rejectParticipantTitle)),
      content: TextField(
        controller: _controller,
        decoration: InputDecoration(
          labelText: context.tr(LocaleKeys.rejectReasonOptional),
          hintText: context.tr(LocaleKeys.rejectReasonHint),
        ),
        maxLines: 3,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.tr(LocaleKeys.cancel)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: Text(context.tr(LocaleKeys.reject)),
        ),
      ],
    );
  }
}
