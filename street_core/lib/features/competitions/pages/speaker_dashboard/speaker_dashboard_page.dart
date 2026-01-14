/// Speaker Dashboard Page - Real-time competition display for announcers
///
/// Displays live heat information with SSE updates for:
/// - Score resets
/// - Score swaps
/// - Score overrides
/// - Emergency alerts
/// - Athlete removals
/// - Heat order changes

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/helpers/snackbar_helper.dart';

import '../../../../core/lang/locale_keys.dart';
import '../../categories/bloc/competition_category_cubit.dart';
import '../../categories/bloc/competition_category_state.dart';
import '../../infrastructure/bloc/sse_event_cubit.dart';
import '../../infrastructure/services/sse_event_service.dart';
import '../../infrastructure/widgets/sse_event_listener.dart';
import '../../models/competition_category_model.dart';
import '../../models/sse_events.dart';

/// Speaker Dashboard Page
///
/// Provides real-time competition display with SSE integration.
/// Automatically reloads data when emergency events are received.
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
  String? _selectedCategoryId;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // Competition categories cubit
        BlocProvider(
          create: (context) => GetIt.instance<CompetitionCategoryCubit>()
            ..fetchCategories(widget.competitionId),
        ),
        // SSE event cubit
        BlocProvider(
          create: (context) => SSEEventCubit(SSEEventServiceProvider.instance)
            ..connect(widget.competitionId),
        ),
      ],
      child: _SpeakerDashboardContent(
        competitionId: widget.competitionId,
        selectedCategoryId: _selectedCategoryId,
        onCategorySelected: (categoryId) {
          setState(() {
            _selectedCategoryId = categoryId;
          });
        },
      ),
    );
  }
}

/// Speaker Dashboard Content Widget
///
/// Wraps content with SSEEventListener and implements reload logic.
class _SpeakerDashboardContent extends StatelessWidget {
  final String competitionId;
  final String? selectedCategoryId;
  final void Function(String) onCategorySelected;

  const _SpeakerDashboardContent({
    required this.competitionId,
    required this.selectedCategoryId,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(LocaleKeys.speakerDashboardTitle),
        actions: [
          // SSE Connection Status Indicator
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: SSEConnectionIndicator(),
          ),
          // Reload button
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: LocaleKeys.reloadData,
            onPressed: () => _reloadAllData(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SSEEventListener(
        // Handle score reset - reload category data
        onScoreReset: (event) => _handleScoreReset(context, event),

        // Handle score swap - reload category data
        onScoreSwap: (event) => _handleScoreSwap(context, event),

        // Handle score override - reload category data
        onScoreOverride: (event) => _handleScoreOverride(context, event),

        // Handle emergency alerts - show alert, may pause display
        onEmergency: (event) => _handleEmergency(context, event),

        // Handle score under review - mark score as under review
        onScoreUnderReview: (event) => _handleScoreUnderReview(context, event),

        // Handle heat order change - reload category
        onHeatOrderChange: (event) => _handleHeatOrderChange(context, event),

        // Handle athlete removed - reload category
        onAthleteRemoved: (event) => _handleAthleteRemoved(context, event),

        child: _buildDashboardBody(context),
      ),
    );
  }

  /// Build dashboard body with categories and heat display
  Widget _buildDashboardBody(BuildContext context) {
    return BlocBuilder<CompetitionCategoryCubit, CompetitionCategoryState>(
      builder: (context, state) {
        if (state is CategoriesLoading) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(LocaleKeys.loading),
              ],
            ),
          );
        }

        if (state is CategoryError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  state.message,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _reloadAllData(context),
                  icon: const Icon(Icons.refresh),
                  label: Text(LocaleKeys.retry),
                ),
              ],
            ),
          );
        }

        if (state is CategoriesLoaded) {
          if (state.categories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inbox_outlined, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    LocaleKeys.noCategories,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Category selection
              _buildCategorySelector(context, state.categories),
              const Divider(height: 1),
              // Heat display
              Expanded(
                child: selectedCategoryId == null
                    ? _buildNoCategorySelected()
                    : _buildCategoryDetail(),
              ),
            ],
          );
        }

        if (state is CategoryDetailLoaded) {
          return _buildCategoryDetailView(context, state.category);
        }

        return Center(child: Text(LocaleKeys.noDataAvailable));
      },
    );
  }

  /// Build category selector dropdown
  Widget _buildCategorySelector(
    BuildContext context,
    List<CompetitionCategory> categories,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          Text(
            LocaleKeys.selectCategory,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButton<String>(
              value: selectedCategoryId,
              hint: Text(LocaleKeys.selectCategory),
              isExpanded: true,
              items: categories.map((category) {
                return DropdownMenuItem<String>(
                  value: category.id,
                  child: Text(category.name),
                );
              }).toList(),
              onChanged: (categoryId) {
                if (categoryId != null) {
                  onCategorySelected(categoryId);
                  // Load category details
                  context
                      .read<CompetitionCategoryCubit>()
                      .fetchCategoryById(competitionId, categoryId);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Build placeholder when no category is selected
  Widget _buildNoCategorySelected() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.category_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            LocaleKeys.selectCategory,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  /// Build category detail view (loading state)
  Widget _buildCategoryDetail() {
    return BlocBuilder<CompetitionCategoryCubit, CompetitionCategoryState>(
      builder: (context, state) {
        if (state is CategoriesLoading) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(LocaleKeys.loadingHeat),
              ],
            ),
          );
        }

        if (state is CategoryDetailLoaded) {
          return _buildCategoryDetailView(context, state.category);
        }

        return Center(child: Text(LocaleKeys.noDataAvailable));
      },
    );
  }

  /// Build category detail view with heats and athletes
  Widget _buildCategoryDetailView(
    BuildContext context,
    CompetitionCategory category,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category info card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (category.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      category.description,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _buildCategoryStats(category),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Heats section
          _buildHeatsSection(category),

          // Athletes section
          const SizedBox(height: 16),
          _buildAthletesSection(category),
        ],
      ),
    );
  }

  /// Build category statistics
  Widget _buildCategoryStats(CompetitionCategory category) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _buildStatChip(
          Icons.people_outline,
          LocaleKeys.participants,
          category.participantCount.toString(),
        ),
        _buildStatChip(
          Icons.gavel,
          LocaleKeys.judges,
          category.judgeCount.toString(),
        ),
      ],
    );
  }

  /// Build stat chip
  Widget _buildStatChip(IconData icon, String label, String value) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text('$label: $value'),
    );
  }

  /// Build heats section
  Widget _buildHeatsSection(CompetitionCategory category) {
    // Note: This is a placeholder. In a real implementation,
    // you would fetch heats from the backend and display them here.
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              LocaleKeys.currentHeat,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              LocaleKeys.noHeatsAvailable,
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  /// Build athletes section
  Widget _buildAthletesSection(CompetitionCategory category) {
    final participants = category.participants;

    if (participants.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              LocaleKeys.noParticipants,
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              LocaleKeys.athletesList,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: participants.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final participantId = participants[index];
                return ListTile(
                  leading: CircleAvatar(
                    child: Text('${index + 1}'),
                  ),
                  title: Text('${LocaleKeys.athlete} #$participantId'),
                  subtitle: Text(LocaleKeys.totalScore),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // SSE EVENT HANDLERS
  // ==========================================================================

  /// Handle score reset event
  void _handleScoreReset(BuildContext context, ScoreResetEvent event) {
    _reloadCategoryData(context);
    _showUpdateSnackbar(context, LocaleKeys.dataUpdated);
  }

  /// Handle score swap event
  void _handleScoreSwap(BuildContext context, ScoreSwapEvent event) {
    _reloadCategoryData(context);
    _showUpdateSnackbar(context, LocaleKeys.dataUpdated);
  }

  /// Handle score override event
  void _handleScoreOverride(BuildContext context, ScoreOverrideEvent event) {
    _reloadCategoryData(context);
    _showUpdateSnackbar(context, LocaleKeys.dataUpdated);
  }

  /// Handle emergency event
  void _handleEmergency(BuildContext context, EmergencyEvent event) {
    // Emergency events already show dialog via SSEEventListener
    // Additional handling can be added here (e.g., pause display)
  }

  /// Handle score under review event
  void _handleScoreUnderReview(
    BuildContext context,
    ScoreUnderReviewEvent event,
  ) {
    _reloadCategoryData(context);
  }

  /// Handle heat order change event
  void _handleHeatOrderChange(
    BuildContext context,
    HeatOrderChangeEvent event,
  ) {
    _reloadCategoryData(context);
    _showUpdateSnackbar(context, LocaleKeys.dataUpdated);
  }

  /// Handle athlete removed event
  void _handleAthleteRemoved(
    BuildContext context,
    AthleteRemovedEvent event,
  ) {
    _reloadCategoryData(context);
    _showUpdateSnackbar(context, LocaleKeys.dataUpdated);
  }

  // ==========================================================================
  // RELOAD HELPERS
  // ==========================================================================

  /// Reload category data
  void _reloadCategoryData(BuildContext context) {
    if (selectedCategoryId != null) {
      context
          .read<CompetitionCategoryCubit>()
          .fetchCategoryById(competitionId, selectedCategoryId!);
    }
  }

  /// Reload all data (categories + selected category)
  void _reloadAllData(BuildContext context) {
    context.read<CompetitionCategoryCubit>().fetchCategories(competitionId);
    if (selectedCategoryId != null) {
      context
          .read<CompetitionCategoryCubit>()
          .fetchCategoryById(competitionId, selectedCategoryId!);
    }
  }

  void _showUpdateSnackbar(BuildContext context, String messageKey) {
    SnackBarHelper.showSuccess(context, messageKey);
  }
}
