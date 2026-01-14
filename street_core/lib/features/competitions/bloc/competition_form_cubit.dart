/// Cubit de Formulario de Competición - Gestión de estado para crear/editar competiciones.
/// Following Monolith-by-Features architecture (ADR-005).

import '../../../core/helpers/logger.dart';
import './competition_form_state.dart';
import '../models/competition.dart';
import '../services/competitions_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Cubit para gestionar el estado del formulario de competición (crear/editar).
class CompetitionFormCubit extends Cubit<CompetitionFormState> {
  CompetitionFormCubit(this._service) : super(const CompetitionFormInitial());

  final CompetitionsService _service;

  // ===========================================================================
  // LOAD COMPETITION (for editing)
  // ===========================================================================

  /// Cargar una competición existente para editar.
  Future<void> loadCompetition(String competitionId) async {
    emit(const CompetitionFormLoading());

    try {
      AppLogger.info('Loading competition for editing: $competitionId');
      final competition = await _service.fetchCompetitionById(competitionId);
      emit(CompetitionFormLoaded(competition));
    } catch (e) {
      AppLogger.error('Error loading competition: $e');
      emit(CompetitionFormError('Error al cargar la competición: $e'));
    }
  }

  // ===========================================================================
  // CREATE COMPETITION
  // ===========================================================================

  /// Crear una nueva competición.
  Future<void> createCompetition(Competition competition) async {
    emit(const CompetitionFormLoading());

    try {
      AppLogger.info('Creating new competition: ${competition.title}');

      // Convert competition to JSON for API
      final data = _prepareCompetitionData(competition);

      final created = await _service.createCompetition(data);

      AppLogger.info('Competition created successfully: ${created.id}');
      emit(
        CompetitionFormSuccess(
          competition: created,
          message: competition.status == 'draft'
              ? 'Borrador guardado exitosamente'
              : 'Competición creada exitosamente',
        ),
      );
    } catch (e) {
      AppLogger.error('Error creating competition: $e');
      emit(CompetitionFormError('Error al crear la competición: $e'));
    }
  }

  // ===========================================================================
  // UPDATE COMPETITION
  // ===========================================================================

  /// Actualizar una competición existente.
  Future<void> updateCompetition(Competition competition) async {
    emit(const CompetitionFormLoading());

    try {
      AppLogger.info('Updating competition: ${competition.id}');

      // Convert competition to JSON for API
      final data = _prepareCompetitionData(competition);

      final updated = await _service.updateCompetition(competition.id, data);

      AppLogger.info('Competition updated successfully: ${updated.id}');
      emit(
        CompetitionFormSuccess(
          competition: updated,
          message: competition.status == 'draft'
              ? 'Borrador actualizado exitosamente'
              : 'Competición actualizada exitosamente',
        ),
      );
    } catch (e) {
      AppLogger.error('Error updating competition: $e');
      emit(CompetitionFormError('Error al actualizar la competición: $e'));
    }
  }

  // ===========================================================================
  // HELPER METHODS
  // ===========================================================================

  /// Preparar datos de competición para envío a API.
  Map<String, dynamic> _prepareCompetitionData(Competition competition) {
    // Use toJson() from the model
    final data = competition.toJson();

    // Remove fields that shouldn't be sent on create/update
    data.remove('id');
    data.remove('eventId');
    data.remove('currentParticipants');
    data.remove('registeredAthleteIds');
    data.remove('waitlistAthleteIds');
    data.remove('createdAt');
    data.remove('updatedAt');

    return data;
  }

  /// Reiniciar formulario al estado inicial.
  void reset() {
    emit(const CompetitionFormInitial());
  }

  /// Establecer error de validación.
  void setValidationError(String message) {
    emit(CompetitionFormValidationError(message));
  }
}
