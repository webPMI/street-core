import 'package:flutter/material.dart';

import '../../../../core/lang/locale_keys.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/my_text.dart';
import '../../../auth/bloc/user_cubit.dart';
import '../../../auth/fast_login.dart';
import '../../bloc/competitions_cubit.dart';
import '../../models/competition.dart';
import '../../services/participant_service.dart';
import '../../widgets/external_registration_warning.dart';
import 'compe_register_page.dart';

/// Botón FAB inteligente para registro/desregistro en competiciones
/// Maneja automáticamente:
/// - Estado de registro del usuario
/// - Estado de la competición
/// - Login prompt para usuarios no autenticados
class CompetRegisterButton extends StatefulWidget {
  final Competition competition;

  const CompetRegisterButton({super.key, required this.competition});

  @override
  State<CompetRegisterButton> createState() => _CompetRegisterButtonState();
}

class _CompetRegisterButtonState extends State<CompetRegisterButton> {
  bool _isRegistered = false;
  bool _hasChecked = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = context.read<UserCubit>().currentUser?.id;
    _checkRegistrationStatus();
  }

  @override
  void didUpdateWidget(CompetRegisterButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.competition.id != widget.competition.id) {
      _checkRegistrationStatus();
    }
  }

  Future<void> _checkRegistrationStatus() async {
    if (_currentUserId == null) {
      setState(() => _hasChecked = true);
      return;
    }

    // Primero usar datos del modelo
    final modelRegistered = widget.competition.isRegisteredBy(_currentUserId!);
    setState(() {
      _isRegistered = modelRegistered;
      _hasChecked = true;
    });

    // Luego verificar con API para datos más frescos
    try {
      final participantService = getIt<ParticipantService>();
      final participants = await participantService.fetchAll(
        widget.competition.id,
      );

      final apiRegistered = participants.any(
        (p) =>
            p['athleteId'] == _currentUserId ||
            p['riderId'] == _currentUserId ||
            p['userId'] == _currentUserId,
      );

      if (mounted && apiRegistered != _isRegistered) {
        setState(() => _isRegistered = apiRegistered);
      }
    } catch (_) {
      // Silently fail - usamos datos del modelo
    }
  }

  bool _canRegister() {
    final status = widget.competition.status;
    return (status == 'published' || status == 'upcoming') && !_isRegistered;
  }

  bool _canUnregister() {
    final status = widget.competition.status;
    return _isRegistered && status != 'live' && status != 'completed';
  }

  @override
  Widget build(BuildContext context) {
    // No mostrar nada mientras verificamos
    if (!_hasChecked) return const SizedBox.shrink();

    // Handle external registration - show warning instead of register button
    if (_canRegister() && widget.competition.isExternalRegistration) {
      return ExternalRegistrationWarning(competition: widget.competition);
    }

    // Mostrar botón de registro
    if (_canRegister()) {
      return FloatingActionButton.extended(
        onPressed: () => _handleRegisterTap(context),
        backgroundColor: Colors.green,
        icon: const Icon(Icons.person_add),
        label: MyText(LocaleKeys.register),
      );
    }

    // Mostrar botón de desregistro
    if (_canUnregister()) {
      return FloatingActionButton.extended(
        onPressed: () => _handleUnregisterTap(context),
        backgroundColor: Colors.orange,
        icon: const Icon(Icons.person_remove),
        label: MyText(LocaleKeys.unregisterShort),
      );
    }

    // No mostrar nada (competición live/completed o usuario no puede registrarse)
    return const SizedBox.shrink();
  }

  void _handleRegisterTap(BuildContext context) {
    final user = context.read<UserCubit>().currentUser;

    if (user == null) {
      _showLoginPrompt(context);
    } else {
      _showRegisterSheet(context);
    }
  }

  void _handleUnregisterTap(BuildContext context) {
    final competitionsCubit = context.read<CompetitionsCubit>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: MyText(LocaleKeys.unregister),
        content: MyText(LocaleKeys.confirmUnregister),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: MyText(LocaleKeys.no),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              competitionsCubit.unregister(widget.competition.id);
              setState(() => _isRegistered = false);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: MyText(LocaleKeys.yes),
          ),
        ],
      ),
    );
  }

  void _showLoginPrompt(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => FastLogingAndRegister(
        onLogin: () {
          Navigator.pop(sheetContext);
          context.push(AppRoutes.login);
        },
        onRegister: () {
          Navigator.pop(sheetContext);
          context.push(AppRoutes.register);
        },
      ),
    );
  }

  void _showRegisterSheet(BuildContext context) {
    final competitionsCubit = context.read<CompetitionsCubit>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => CompetitionRegisterSheet(
        competition: widget.competition,
        onConfirm: () {
          Navigator.pop(sheetContext);
          competitionsCubit.register(widget.competition.id);
          setState(() => _isRegistered = true);
        },
      ),
    );
  }
}
