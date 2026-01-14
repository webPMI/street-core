import 'package:equatable/equatable.dart';

import '../../../data/models/privacy_settings_model.dart';

abstract class SettingsState extends Equatable {
  const SettingsState();

  @override
  List<Object?> get props => [];
}

class PrivacySettingsInitial extends SettingsState {}

class PrivacySettingsLoading extends SettingsState {}

class PrivacySettingsLoaded extends SettingsState {
  const PrivacySettingsLoaded(this.settings);
  final PrivacySettings settings;

  @override
  List<Object?> get props => [settings];
}

class PrivacySettingsError extends SettingsState {
  const PrivacySettingsError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
