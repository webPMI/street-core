/// Estado del Formulario de Competición - Estados para el cubit de formulario de competición.
/// Following Monolith-by-Features architecture (ADR-005).

import 'package:equatable/equatable.dart';
import '../models/competition.dart';

/// Estado base para formulario de competición.
abstract class CompetitionFormState extends Equatable {
  const CompetitionFormState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial.
class CompetitionFormInitial extends CompetitionFormState {
  const CompetitionFormInitial();
}

/// Estado de carga.
class CompetitionFormLoading extends CompetitionFormState {
  const CompetitionFormLoading();
}

/// Competición cargada para edición.
class CompetitionFormLoaded extends CompetitionFormState {
  const CompetitionFormLoaded(this.competition);

  final Competition competition;

  @override
  List<Object?> get props => [competition];
}

/// Competición guardada exitosamente (crear o actualizar).
class CompetitionFormSuccess extends CompetitionFormState {
  const CompetitionFormSuccess({
    required this.competition,
    required this.message,
  });

  final Competition competition;
  final String message;

  @override
  List<Object?> get props => [competition, message];
}

/// Error de validación.
class CompetitionFormValidationError extends CompetitionFormState {
  const CompetitionFormValidationError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

/// Estado de error.
class CompetitionFormError extends CompetitionFormState {
  const CompetitionFormError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
