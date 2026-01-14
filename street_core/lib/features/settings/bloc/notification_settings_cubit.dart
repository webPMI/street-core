import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Notification Settings Cubit
///
/// ⚠️ TODO: Backend implementation pending
/// Currently stores state locally (in-memory only).
/// Backend endpoints need to be implemented:
/// - GET /api/v2/users/me/notification-settings
/// - PUT /api/v2/users/me/notification-settings
///
/// Backend model exists: models.NotificationSettings
/// but lacks service, handler, and routes.

// STATE
class NotificationSettingsState extends Equatable {

  const NotificationSettingsState({
    this.pushEnabled = true,
    this.emailEnabled = true,
    this.marketingEnabled = false,
  });
  final bool pushEnabled;
  final bool emailEnabled;
  final bool marketingEnabled;

  NotificationSettingsState copyWith({
    bool? pushEnabled,
    bool? emailEnabled,
    bool? marketingEnabled,
  }) {
    return NotificationSettingsState(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      emailEnabled: emailEnabled ?? this.emailEnabled,
      marketingEnabled: marketingEnabled ?? this.marketingEnabled,
    );
  }

  @override
  List<Object> get props => [pushEnabled, emailEnabled, marketingEnabled];
}

// CUBIT
class NotificationSettingsCubit extends Cubit<NotificationSettingsState> {
  NotificationSettingsCubit() : super(const NotificationSettingsState());

  void togglePush(bool value) => emit(state.copyWith(pushEnabled: value));
  void toggleEmail(bool value) => emit(state.copyWith(emailEnabled: value));
  void toggleMarketing(bool value) =>
      emit(state.copyWith(marketingEnabled: value));
}
