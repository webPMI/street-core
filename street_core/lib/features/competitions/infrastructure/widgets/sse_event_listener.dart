/// SSE Event Listener Widget - Displays real-time event notifications
///
/// Listens to SSE events from the competition SSE stream and provides
/// visual feedback through snackbars and dialogs.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/lang/locale_keys.dart';
import '../../models/sse_events.dart';
import '../bloc/sse_event_cubit.dart';
import '../../../../core/helpers/snackbar_helper.dart';
import '../../../../core/lang/context_tr.dart';

/// SSE Event Listener - Listens to SSE events and shows visual notifications
///
/// Wraps child widgets and provides callbacks for handling different types
/// of SSE events. Automatically shows snackbars for each event type unless
/// [showSnackbar] is set to false.
///
/// Usage:
/// ```dart
/// SSEEventListener(
///   onScoreReset: (event) {
///     // Reload athlete scores
///   },
///   onScoreSwap: (event) {
///     // Reload both athletes
///   },
///   onEmergency: (event) {
///     // Show critical alert
///   },
///   child: YourSpeakerDashboard(),
/// )
/// ```
class SSEEventListener extends StatelessWidget {
  /// The child widget to wrap with SSE event listening
  final Widget child;

  /// Callback for score reset events (athlete re-run authorized)
  final void Function(ScoreResetEvent)? onScoreReset;

  /// Callback for score swap events (scores swapped between athletes)
  final void Function(ScoreSwapEvent)? onScoreSwap;

  /// Callback for score override events (admin manual entry)
  final void Function(ScoreOverrideEvent)? onScoreOverride;

  /// Callback for emergency events (critical alerts)
  final void Function(EmergencyEvent)? onEmergency;

  /// Callback for score under review events (protest filed)
  final void Function(ScoreUnderReviewEvent)? onScoreUnderReview;

  /// Callback for heat order change events
  final void Function(HeatOrderChangeEvent)? onHeatOrderChange;

  /// Callback for athlete removed events
  final void Function(AthleteRemovedEvent)? onAthleteRemoved;

  /// Whether to show snackbar notifications automatically (default: true)
  final bool showSnackbar;

  const SSEEventListener({
    super.key,
    required this.child,
    this.onScoreReset,
    this.onScoreSwap,
    this.onScoreOverride,
    this.onEmergency,
    this.onScoreUnderReview,
    this.onHeatOrderChange,
    this.onAthleteRemoved,
    this.showSnackbar = true,
  });

  @override
  Widget build(BuildContext context) {
    return BlocListener<SSEEventCubit, SSEEventState>(
      listener: (context, state) {
        final event = state.latestEvent;
        if (event == null) return;

        // Handle different event types
        if (event is ScoreResetEvent) {
          _handleScoreReset(context, event);
        } else if (event is ScoreSwapEvent) {
          _handleScoreSwap(context, event);
        } else if (event is ScoreOverrideEvent) {
          _handleScoreOverride(context, event);
        } else if (event is EmergencyEvent) {
          _handleEmergency(context, event);
        } else if (event is ScoreUnderReviewEvent) {
          _handleScoreUnderReview(context, event);
        } else if (event is HeatOrderChangeEvent) {
          _handleHeatOrderChange(context, event);
        } else if (event is AthleteRemovedEvent) {
          _handleAthleteRemoved(context, event);
        }
      },
      child: child,
    );
  }

  /// Handles score reset events
  void _handleScoreReset(BuildContext context, ScoreResetEvent event) {
    if (showSnackbar) {
      _showEventSnackbar(
        context,
        icon: Icons.refresh,
        color: Colors.orange,
        titleKey: LocaleKeys.emergencyScoreReset,
        message: event.message,
      );
    }
    onScoreReset?.call(event);
  }

  /// Handles score swap events
  void _handleScoreSwap(BuildContext context, ScoreSwapEvent event) {
    if (showSnackbar) {
      _showEventSnackbar(
        context,
        icon: Icons.swap_horiz,
        color: Colors.purple,
        titleKey: LocaleKeys.emergencyScoreSwap,
        message: event.message,
      );
    }
    onScoreSwap?.call(event);
  }

  /// Handles score override events
  void _handleScoreOverride(BuildContext context, ScoreOverrideEvent event) {
    if (showSnackbar) {
      _showEventSnackbar(
        context,
        icon: Icons.edit,
        color: Colors.amber,
        titleKey: LocaleKeys.emergencyScoreOverride,
        message: event.message,
      );
    }
    onScoreOverride?.call(event);
  }

  /// Handles emergency events
  void _handleEmergency(BuildContext context, EmergencyEvent event) {
    // Emergency events get a dialog instead of snackbar
    if (event.priority == 'CRITICAL') {
      _showEmergencyDialog(context, event);
    } else if (showSnackbar) {
      _showEventSnackbar(
        context,
        icon: Icons.warning,
        color: Colors.red,
        titleKey: LocaleKeys.emergencyAlert,
        message: event.message,
      );
    }
    onEmergency?.call(event);
  }

  /// Handles score under review events
  void _handleScoreUnderReview(
      BuildContext context, ScoreUnderReviewEvent event) {
    if (showSnackbar) {
      _showEventSnackbar(
        context,
        icon: Icons.flag,
        color: Colors.yellow.shade700,
        titleKey: LocaleKeys.emergencyScoreUnderReview,
        message: event.message,
      );
    }
    onScoreUnderReview?.call(event);
  }

  /// Handles heat order change events
  void _handleHeatOrderChange(
      BuildContext context, HeatOrderChangeEvent event) {
    if (showSnackbar) {
      _showEventSnackbar(
        context,
        icon: Icons.reorder,
        color: Colors.blue,
        titleKey: LocaleKeys.emergencyHeatOrderChange,
        message: event.message,
      );
    }
    onHeatOrderChange?.call(event);
  }

  /// Handles athlete removed events
  void _handleAthleteRemoved(BuildContext context, AthleteRemovedEvent event) {
    if (showSnackbar) {
      _showEventSnackbar(
        context,
        icon: Icons.person_remove,
        color: Colors.red,
        titleKey: LocaleKeys.emergencyAthleteRemoved,
        message: event.message,
      );
    }
    onAthleteRemoved?.call(event);
  }

  void _showEventSnackbar(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String titleKey,
    required String message,
  }) {
    SnackBarType type = SnackBarType.info;
    if (color == Colors.red) {
      type = SnackBarType.error;
    } else if (color == Colors.orange || color == Colors.amber || color == Colors.yellow.shade700) {
      type = SnackBarType.warning;
    } else if (color == Colors.green) {
      type = SnackBarType.success;
    }

    SnackBarHelper.showCustom(
      context,
      message,
      title: context.tr(titleKey),
      type: type,
      duration: const Duration(seconds: 5),
    );
  }

  /// Shows a critical emergency dialog
  void _showEmergencyDialog(BuildContext context, EmergencyEvent event) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.error_outline,
          color: Colors.red,
          size: 48,
        ),
        title: Text(LocaleKeys.emergencyAlertTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              event.message,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Text(
              '${LocaleKeys.emergencySubject}: ${event.subject}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (event.actionNeeded) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.priority_high, color: Colors.red),
                    const SizedBox(width: 8),
                    Text(
                      LocaleKeys.emergencyActionRequired,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(LocaleKeys.emergencyAcknowledge.toUpperCase()),
          ),
        ],
      ),
    );
  }
}

/// SSE Connection Status Indicator
///
/// Displays a visual indicator of the current SSE connection state.
/// Shows different colors and text based on connection status:
/// - Green: Connected (Live)
/// - Orange: Connecting/Reconnecting
/// - Red: Connection Error
/// - Grey: Disconnected
class SSEConnectionIndicator extends StatelessWidget {
  const SSEConnectionIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SSEEventCubit, SSEEventState>(
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getStatusColor(state.connectionState).withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _getStatusColor(state.connectionState),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _getStatusColor(state.connectionState),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _getStatusText(state.connectionState),
                style: TextStyle(
                  color: _getStatusColor(state.connectionState),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Returns the appropriate color for each connection state
  Color _getStatusColor(SSEConnectionState state) {
    switch (state) {
      case SSEConnectionState.connected:
        return Colors.green;
      case SSEConnectionState.connecting:
      case SSEConnectionState.reconnecting:
        return Colors.orange;
      case SSEConnectionState.error:
        return Colors.red;
      case SSEConnectionState.disconnected:
        return Colors.grey;
    }
  }

  /// Returns the appropriate text for each connection state
  String _getStatusText(SSEConnectionState state) {
    switch (state) {
      case SSEConnectionState.connected:
        return LocaleKeys.sseLive;
      case SSEConnectionState.connecting:
        return LocaleKeys.sseConnecting;
      case SSEConnectionState.reconnecting:
        return LocaleKeys.sseReconnecting;
      case SSEConnectionState.error:
        return LocaleKeys.sseConnectionError;
      case SSEConnectionState.disconnected:
        return LocaleKeys.sseDisconnected;
    }
  }
}
