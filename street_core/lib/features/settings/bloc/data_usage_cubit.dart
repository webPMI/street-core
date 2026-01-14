import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Data Usage Settings Cubit
///
/// ⚠️ TODO: Backend implementation pending
/// Currently stores state locally (in-memory only).
/// Backend endpoints need to be implemented:
/// - GET /api/v2/users/me/data-usage-settings
/// - PUT /api/v2/users/me/data-usage-settings
///
/// No backend model exists yet. Needs to be created.

// STATE
enum AutoplayOption { always, wifiOnly, never }

class DataUsageState extends Equatable {

  const DataUsageState({
    this.autoplayVideos = AutoplayOption.wifiOnly,
    this.downloadOverWifiOnly = true,
  });
  final AutoplayOption autoplayVideos;
  final bool downloadOverWifiOnly;

  DataUsageState copyWith({
    AutoplayOption? autoplayVideos,
    bool? downloadOverWifiOnly,
  }) {
    return DataUsageState(
      autoplayVideos: autoplayVideos ?? this.autoplayVideos,
      downloadOverWifiOnly: downloadOverWifiOnly ?? this.downloadOverWifiOnly,
    );
  }

  @override
  List<Object> get props => [autoplayVideos, downloadOverWifiOnly];
}

// CUBIT
class DataUsageCubit extends Cubit<DataUsageState> {
  DataUsageCubit() : super(const DataUsageState());

  void setAutoplay(AutoplayOption option) =>
      emit(state.copyWith(autoplayVideos: option));
  void toggleWifiDownload(bool value) =>
      emit(state.copyWith(downloadOverWifiOnly: value));

  Future<void> clearCache() async {
    // Simulate cache clearing
    await Future<void>.delayed(const Duration(seconds: 1));
  }
}
