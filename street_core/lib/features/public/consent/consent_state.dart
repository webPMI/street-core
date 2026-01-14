import 'package:equatable/equatable.dart';

import '../../../data/models/site_config/site_config_models.dart';

enum ConsentStatus {
  unknown, // Not yet decided (show banner)
  accepted, // User accepted all or custom
  rejected, // User rejected (or configured minimum)
}

class ConsentState extends Equatable {
  const ConsentState({
    this.status = ConsentStatus.unknown,
    this.isLoading = true,
    this.cookiesAccepted =
        true, // Necessary cookies always true ideally, or defaults
    this.analyticsAccepted = false,
    this.locationAccepted = false,
    this.marketingAccepted = false,
    this.config,
  });
  final ConsentStatus status;
  final bool isLoading;

  // Granular settings (temporary state before saving)
  final bool cookiesAccepted;
  final bool analyticsAccepted;
  final bool locationAccepted;
  final bool marketingAccepted;

  // Configuration texts from backend
  final ConsentConfig? config;

  bool get isUnknown => status == ConsentStatus.unknown;
  bool get isAccepted => status == ConsentStatus.accepted;

  @override
  List<Object?> get props => [
    status,
    isLoading,
    cookiesAccepted,
    analyticsAccepted,
    locationAccepted,
    marketingAccepted,
    config,
  ];

  ConsentState copyWith({
    ConsentStatus? status,
    bool? isLoading,
    bool? cookiesAccepted,
    bool? analyticsAccepted,
    bool? locationAccepted,
    bool? marketingAccepted,
    ConsentConfig? config,
  }) {
    return ConsentState(
      status: status ?? this.status,
      isLoading: isLoading ?? this.isLoading,
      cookiesAccepted: cookiesAccepted ?? this.cookiesAccepted,
      analyticsAccepted: analyticsAccepted ?? this.analyticsAccepted,
      locationAccepted: locationAccepted ?? this.locationAccepted,
      marketingAccepted: marketingAccepted ?? this.marketingAccepted,
      config: config ?? this.config,
    );
  }
}
