import '../../profile/repositories/privacy_repository.dart';
import './privacy_settings_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(this._repository) : super(PrivacySettingsInitial());
  final PrivacyRepository _repository;

  Future<void> loadSettings() async {
    emit(PrivacySettingsLoading());
    try {
      // Using the new repository method
      final settings = await _repository.getSettings('current_user');
      emit(PrivacySettingsLoaded(settings));
    } catch (e) {
      emit(PrivacySettingsError(e.toString()));
    }
  }

  Future<void> updateSettings(Map<String, dynamic> data) async {
    try {
      // Optimistic update could be done here if we had the previous state,
      // but for now we'll just show loading or keep previous state?
      // Better: keep showing current UI but maybe with a loading overlay?
      // Usually, for settings, we might want to just update and reload,
      // or assume success.
      // Let's rely on the repository returning the updated object.

      // If we are currently loaded, we can try to stay in loaded state?
      // But standard way is to show some loading feedback.
      // Since this is a toggle, full page loading is annoying.
      // Ideally we would emit a "Updating" state or similar,
      // but let's stick to the defined states.

      // We'll emit loading only if we want to block interaction,
      // but for switches it's better to just wait.
      // However, to keep it simple and consistent:
      final currentState = state;
      if (currentState is PrivacySettingsLoaded) {
        // We could emit a specific "Submitting" state to show a linear progress bar
        // instead of full replacement, but let's keep it simple for now and just call API.
        // If we emit loading, the UI might flicker.
        // Let's just await.
      } else {
        emit(PrivacySettingsLoading());
      }

      final updatedSettings = await _repository.updatePartialSettings(
        'current_user',
        data,
      );
      emit(PrivacySettingsLoaded(updatedSettings));
    } catch (e) {
      emit(PrivacySettingsError(e.toString()));
      // If error, we might want to reload to ensure consistency
      loadSettings();
    }
  }

  Future<void> unblockUser(String userId) async {
    try {
      await _repository.unblockUser(
        blockerId: 'current_user',
        blockedId: userId,
      );
      // Reload settings to get updated blocked list
      // The API doesn't return the new settings on unblock usually, so we fetch again.
      await loadSettings();
    } catch (e) {
      emit(PrivacySettingsError(e.toString()));
    }
  }
}
