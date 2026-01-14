# SSE Integration Guide - Speaker Dashboard

**Version**: 1.0
**Date**: 2026-01-06

---

## 📋 Overview

This guide shows how to integrate **Server-Sent Events (SSE)** into the Speaker Dashboard for real-time updates during competitions.

---

## 🏗️ Architecture

```
SSE Backend (Go)
    ↓
eventsource package (Dart)
    ↓
SSEEventService (Connection Management)
    ↓
SSEEventCubit (State Management)
    ↓
SSEEventListener (UI Widget)
    ↓
Speaker Dashboard (Real-time updates)
```

---

## 📦 Files Created

### 1. Event Models
**File**: `lib/features/competitions/models/sse_events.dart`

Contains all SSE event types:
- `SSEEvent` (base class)
- `ConnectedEvent`
- `EmergencyEvent`
- `ScoreResetEvent`
- `ScoreSwapEvent`
- `ScoreOverrideEvent`
- `ScoreUnderReviewEvent`
- `HeatOrderChangeEvent`
- `AthleteRemovedEvent`

### 2. SSE Service
**File**: `lib/features/competitions/infrastructure/services/sse_event_service.dart`

Features:
- ✅ Automatic reconnection with exponential backoff
- ✅ JWT authentication
- ✅ Connection state management
- ✅ Event streaming
- ✅ Proper cleanup

### 3. SSE Cubit
**File**: `lib/features/competitions/infrastructure/bloc/sse_event_cubit.dart`

Manages:
- Connection state
- Event history (last 50 events)
- Event counts by type
- Error handling

### 4. UI Widgets
**File**: `lib/features/competitions/infrastructure/widgets/sse_event_listener.dart`

Provides:
- `SSEEventListener` - Event listener widget with callbacks
- `SSEConnectionIndicator` - Visual connection status

---

## 🚀 Quick Start

### Step 1: Initialize SSE Service (App Startup)

**File**: `lib/main.dart` or `lib/core/di/injection.dart`

```dart
import 'package:street_core/features/competitions/infrastructure/services/sse_event_service.dart';

void main() {
  // Initialize SSE service
  SSEEventServiceProvider.initialize(
    SSEConfig(
      baseUrl: 'http://localhost:3000', // Your backend URL
      reconnectDelay: Duration(seconds: 3),
      maxReconnectAttempts: 5,
    ),
  );

  runApp(MyApp());
}
```

### Step 2: Register SSE Cubit in Dependency Injection

**File**: `lib/features/competitions/di/competitions_injection.dart`

```dart
import 'package:get_it/get_it.dart';
import '../infrastructure/services/sse_event_service.dart';
import '../infrastructure/bloc/sse_event_cubit.dart';

final getIt = GetIt.instance;

void setupCompetitionsInjection() {
  // Register SSE Event Cubit
  getIt.registerFactory<SSEEventCubit>(
    () => SSEEventCubit(SSEEventServiceProvider.instance),
  );
}
```

### Step 3: Provide Cubit in Speaker Dashboard

**File**: `lib/features/competitions/pages/speaker_dashboard_page.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../infrastructure/bloc/sse_event_cubit.dart';
import '../infrastructure/widgets/sse_event_listener.dart';

class SpeakerDashboardPage extends StatefulWidget {
  final String competitionId;

  const SpeakerDashboardPage({
    super.key,
    required this.competitionId,
  });

  @override
  State<SpeakerDashboardPage> createState() => _SpeakerDashboardPageState();
}

class _SpeakerDashboardPageState extends State<SpeakerDashboardPage> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GetIt.instance<SSEEventCubit>()
        ..connect(widget.competitionId), // Connect on init
      child: _SpeakerDashboardContent(),
    );
  }
}

class _SpeakerDashboardContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Speaker Dashboard'),
        actions: [
          // Connection status indicator
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: SSEConnectionIndicator(),
          ),
        ],
      ),
      body: SSEEventListener(
        // Handle score reset
        onScoreReset: (event) {
          print('Score reset for athlete ${event.athleteId}');
          // TODO: Reload athlete scores
          _reloadAthleteScores(context, event.heatId!, event.athleteId);
        },

        // Handle score swap
        onScoreSwap: (event) {
          print('Scores swapped: ${event.athlete1Id} <-> ${event.athlete2Id}');
          // TODO: Reload both athletes
          _reloadAthleteScores(context, event.heatId!, event.athlete1Id);
          _reloadAthleteScores(context, event.heatId!, event.athlete2Id);
        },

        // Handle score override
        onScoreOverride: (event) {
          print('Score override: ${event.scoreId}');
          // TODO: Reload score display
          _reloadScore(context, event.scoreId);
        },

        // Handle emergency alerts
        onEmergency: (event) {
          print('Emergency: ${event.message}');
          // Critical emergencies automatically show dialog
          // You can add custom handling here
        },

        // Handle score under review
        onScoreUnderReview: (event) {
          print('Score under review: ${event.scoreId}');
          // TODO: Show "UNDER REVIEW" badge
          _markScoreUnderReview(context, event.scoreId);
        },

        // Handle heat order change
        onHeatOrderChange: (event) {
          print('Heat order changed: ${event.newOrder}');
          // TODO: Reorder athletes in UI
          _reorderAthletes(context, event.heatId!, event.newOrder);
        },

        // Handle athlete removed
        onAthleteRemoved: (event) {
          print('Athlete removed: ${event.athleteId}');
          // TODO: Remove athlete from heat display
          _removeAthlete(context, event.heatId!, event.athleteId);
        },

        child: _buildDashboardContent(),
      ),
    );
  }

  Widget _buildDashboardContent() {
    // Your Speaker Dashboard UI
    return ListView(
      children: [
        // Heat display
        // Athlete scores
        // Real-time updates will trigger automatically
      ],
    );
  }

  // Helper methods
  void _reloadAthleteScores(BuildContext context, String heatId, String athleteId) {
    // Implement: Fetch fresh scores from API
    // Update UI state
  }

  void _reloadScore(BuildContext context, String scoreId) {
    // Implement: Fetch single score
  }

  void _markScoreUnderReview(BuildContext context, String scoreId) {
    // Implement: Add "UNDER REVIEW" badge to score widget
  }

  void _reorderAthletes(BuildContext context, String heatId, List<String> newOrder) {
    // Implement: Reorder athlete widgets based on newOrder array
  }

  void _removeAthlete(BuildContext context, String heatId, String athleteId) {
    // Implement: Remove athlete from heat display
  }
}
```

---

## 🎨 UI Components

### Connection Status Indicator

```dart
// In AppBar
AppBar(
  actions: [
    SSEConnectionIndicator(),
  ],
)
```

**Visual States**:
- 🟢 **Green** - Connected (Live)
- 🟠 **Orange** - Connecting/Reconnecting
- 🔴 **Red** - Connection Error
- ⚫ **Grey** - Disconnected

### Event Snackbars

Events automatically show snackbars with appropriate colors:
- 🟠 **Score Reset** - Orange
- 🟣 **Score Swap** - Purple
- 🟡 **Score Override** - Amber
- 🔴 **Emergency** - Red (Dialog for CRITICAL)
- 🟡 **Score Under Review** - Yellow
- 🔵 **Heat Order Change** - Blue
- 🔴 **Athlete Removed** - Red

### Emergency Dialog (CRITICAL Priority)

For `EmergencyEvent` with `priority: CRITICAL`, a modal dialog is shown:

```
┌─────────────────────────────────┐
│         🚨 EMERGENCY ALERT       │
├─────────────────────────────────┤
│                                 │
│ Judge tablet malfunction -      │
│ Heat paused                     │
│                                 │
│ Subject: JUDGE_TABLET_FAILURE   │
│                                 │
│  ⚠️  ACTION REQUIRED            │
│                                 │
│         [ACKNOWLEDGE]           │
└─────────────────────────────────┘
```

---

## 📊 Event Statistics

Access event statistics via `SSEEventCubit`:

```dart
BlocBuilder<SSEEventCubit, SSEEventState>(
  builder: (context, state) {
    return Column(
      children: [
        Text('Total Events: ${state.totalEventsReceived}'),
        Text('Score Resets: ${state.eventCounts['score_reset'] ?? 0}'),
        Text('Score Swaps: ${state.eventCounts['score_swap'] ?? 0}'),

        // Recent events
        ListView.builder(
          shrinkWrap: true,
          itemCount: state.recentEvents.length,
          itemBuilder: (context, index) {
            final event = state.recentEvents[index];
            return ListTile(
              title: Text(event.type),
              subtitle: Text(event.message),
              trailing: Text(_formatTimestamp(event.timestamp)),
            );
          },
        ),
      ],
    );
  },
)
```

---

## 🔄 Manual Reconnection

If user experiences connection issues:

```dart
ElevatedButton(
  onPressed: () {
    context.read<SSEEventCubit>().reconnect();
  },
  child: Text('Reconnect'),
)
```

---

## 🧪 Testing

### 1. Run Backend

```bash
cd backend
go run main.go
```

### 2. Connect from Flutter

```bash
cd street_core
flutter pub get
flutter run
```

### 3. Trigger Events via Backend

Use Postman or curl to trigger emergency actions:

```bash
POST http://localhost:3000/api/v1/competitions/<comp_id>/heats/<heat_id>/emergency/reset-athlete
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "athleteId": "673d1f2e8b5c4a1d2e3f4a5d",
  "reason": "Equipment failure during run"
}
```

### 4. Verify Event Received in Flutter

Check Flutter console logs:
```
📡 Connecting to SSE: http://localhost:3000/api/v1/competitions/.../events
✅ SSE Connected to competition 673d1f2e8b5c4a1d2e3f4a5b
📢 SSE Event: score_reset - Score reset for athlete - Re-run authorized
```

---

## 🐛 Debugging

### Enable Debug Logs

The SSE service prints detailed logs:

```
📡 Connecting to SSE: <url>
✅ SSE Connected to competition <id>
📢 SSE Event: <type> - <message>
🔄 Reconnecting in 3s (attempt 1)
❌ SSE Connection error: <error>
🔌 Disconnecting SSE...
🗑️ Disposing SSEEventService...
```

### Common Issues

**1. "No authentication token found"**
- Ensure user is logged in
- Check `FlutterSecureStorage` has `access_token`

**2. "Connection refused"**
- Verify backend is running on correct port
- Check `baseUrl` in `SSEConfig`

**3. "Max reconnection attempts reached"**
- Backend may be down
- Check network connectivity
- Increase `maxReconnectAttempts` in config

**4. Events not showing in UI**
- Verify `BlocProvider` is wrapping the widget
- Check `SSEEventListener` callbacks are implemented
- Look for parse errors in console

---

## 🎯 Real-World Usage Example

```dart
class SpeakerHeatView extends StatelessWidget {
  final String heatId;

  @override
  Widget build(BuildContext context) {
    return SSEEventListener(
      // Score reset: Reload athlete
      onScoreReset: (event) async {
        if (event.heatId == heatId) {
          await context.read<HeatCubit>().reloadAthlete(event.athleteId);
        }
      },

      // Score swap: Reload both athletes
      onScoreSwap: (event) async {
        if (event.heatId == heatId) {
          await Future.wait([
            context.read<HeatCubit>().reloadAthlete(event.athlete1Id),
            context.read<HeatCubit>().reloadAthlete(event.athlete2Id),
          ]);
        }
      },

      // Emergency: Pause heat display
      onEmergency: (event) {
        if (event.priority == 'CRITICAL') {
          context.read<HeatCubit>().pauseHeat();
        }
      },

      child: BlocBuilder<HeatCubit, HeatState>(
        builder: (context, state) {
          return ListView.builder(
            itemCount: state.athletes.length,
            itemBuilder: (context, index) {
              final athlete = state.athletes[index];
              return AthleteScoreCard(athlete: athlete);
            },
          );
        },
      ),
    );
  }
}
```

---

## 📱 Cleanup on Dispose

**IMPORTANT**: Always disconnect when leaving Speaker Dashboard:

```dart
@override
void dispose() {
  context.read<SSEEventCubit>().disconnect();
  super.dispose();
}
```

Or use `BlocProvider` auto-dispose:

```dart
BlocProvider(
  create: (context) => SSEEventCubit(...)..connect(competitionId),
  // Automatically calls close() on cubit when widget is disposed
  child: SpeakerDashboard(),
)
```

---

## 🚀 Production Considerations

### 1. Backend URL Configuration

Use environment variables for different environments:

```dart
// lib/core/config/env_config.dart
class EnvConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );
}

// Initialize SSE
SSEEventServiceProvider.initialize(
  SSEConfig(baseUrl: EnvConfig.apiBaseUrl),
);
```

### 2. Error Handling

Listen to error stream for user-friendly messages:

```dart
BlocListener<SSEEventCubit, SSEEventState>(
  listenWhen: (previous, current) =>
    previous.lastError != current.lastError,
  listener: (context, state) {
    if (state.lastError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connection issue: ${state.lastError!.message}'),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () => context.read<SSEEventCubit>().reconnect(),
          ),
        ),
      );
    }
  },
  child: ...,
)
```

### 3. Network Status Integration

Combine with `connectivity_plus` for network-aware reconnection:

```dart
StreamSubscription<ConnectivityResult>? _connectivitySubscription;

@override
void initState() {
  super.initState();

  _connectivitySubscription = Connectivity()
    .onConnectivityChanged
    .listen((result) {
      if (result != ConnectivityResult.none) {
        // Network restored, reconnect SSE
        context.read<SSEEventCubit>().reconnect();
      }
    });
}
```

---

## ✅ Integration Checklist

- [ ] Add `eventsource: ^0.7.1` to `pubspec.yaml`
- [ ] Run `flutter pub get`
- [ ] Initialize `SSEEventServiceProvider` in `main.dart`
- [ ] Register `SSEEventCubit` in dependency injection
- [ ] Wrap Speaker Dashboard with `BlocProvider<SSEEventCubit>`
- [ ] Connect to SSE on page init: `cubit.connect(competitionId)`
- [ ] Add `SSEConnectionIndicator` to AppBar
- [ ] Wrap content with `SSEEventListener`
- [ ] Implement event callbacks (onScoreReset, onScoreSwap, etc.)
- [ ] Test with backend emergency actions
- [ ] Verify events trigger UI updates
- [ ] Test reconnection on network loss
- [ ] Add cleanup on dispose

---

**Ready for Production**: ✅

All SSE infrastructure is production-ready with robust error handling, automatic reconnection, and comprehensive event mapping.

Next: Implement the actual Speaker Dashboard UI components that respond to these events!
