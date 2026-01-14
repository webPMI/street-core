import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:street_core/core/router/navigation_service.dart';
import 'package:street_core/core/widgets/app_logo.dart';
import 'package:street_core/features/auth/auth.dart';
import 'package:street_core/features/competitions/competition_routes.dart';
import 'package:street_core/features/competitions/pages/compe_list/compe_filters.dart';
import '../../../../core/location/widgets/location_filter_components.dart';
import '../../../../core/helpers/snackbar_helper.dart';
import '../../../../core/widgets/error_card.dart';
import '../../../../core/widgets/drawer/my_drawer.dart';
import '../../widgets/competition_card_skeleton.dart';
import '../../../../../core/helpers/responsive/responsive.dart';
import '../../../../../core/lang/context_tr.dart';
import '../../../../../core/location/widgets/location_aware_list.dart';
import '../../../../../core/widgets/my_text.dart';
import '../../bloc/competitions_cubit.dart';
import '../../bloc/competitions_state.dart';
import '../../models/competition.dart';
import '../../widgets/unified_competition_card.dart';
import '../../widgets/competition_seo_wrapper.dart';
import '../../../../core/lang/locale_keys.dart';

class CompetitionsListPage extends StatefulWidget {
  const CompetitionsListPage({super.key});

  @override
  State<CompetitionsListPage> createState() => _CompetitionsListPageState();
}

class _CompetitionsListPageState extends State<CompetitionsListPage> {
  final ScrollController _scrollController = ScrollController();
  bool _isGridView = true;
  bool _showFilters = true;
  Timer? _searchDebounce;

  String _selectedFilter = 'all';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchWithFilters();
    _scrollController.addListener(_onScroll);
  }

  Map<String, dynamic> _buildFilters() {
    final filters = <String, dynamic>{};
    if (_selectedFilter != 'all') {
      filters['status'] = _selectedFilter;
    }
    if (_searchQuery.isNotEmpty) {
      filters['search'] = _searchQuery;
    }
    return filters;
  }

  void _fetchWithFilters() {
    context.read<CompetitionsCubit>().fetchCompetitions(
      filters: _buildFilters(),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (!mounted) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      final state = context.read<CompetitionsCubit>().state;
      if (state is CompetitionsLoaded && state.hasMore) {
        context.read<CompetitionsCubit>().loadMore(filters: _buildFilters());
      }
    }
  }

  int _getGridColumns(double width) {
    if (width < ResponsiveBreakpoints.mobile) return 1;
    if (width < ResponsiveBreakpoints.tablet) return 2;
    if (width < ResponsiveBreakpoints.desktop) return 3;
    return 4;
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final bool isAuthenticated = authState is AuthAuthenticated;

    return Scaffold(
      floatingActionButton: isAuthenticated
          ? FloatingActionButton(
              tooltip: context.tr(LocaleKeys.myCompetitions),
              child: Icon(Icons.emoji_events_outlined),
              onPressed: () {
                NavigationService().go(
                  context,
                  CompetitionRoutes.myCompetitions,
                );
              },
            )
          : null,
      appBar: AppBar(
        title: Row(
          children: [
            AppLogo(
              icon: Icons.emoji_events,
              margin: context.isMobile ? 5 : null,
              padding: context.isMobile ? 5 : null,
              animate: true,
              variant: LogoVariant.full,
            ),
            const SizedBox(width: 8),
            if (!context.isMobile)
              const MyText(LocaleKeys.competitions),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            tooltip: _isGridView
                ? context.tr(LocaleKeys.viewList)
                : context.tr(LocaleKeys.viewGrid),
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
          IconButton(
            tooltip: _showFilters
                ? context.tr(LocaleKeys.hideFilters)
                : context.tr(LocaleKeys.showFilters),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
            icon: Icon(
              _showFilters ? Icons.arrow_upward : Icons.arrow_downward,
            ),
          ),
          LocationFilterButton(onLocationChanged: () {}),
          if (isAuthenticated)
            IconButton(
              onPressed: () {
                NavigationService().go(
                  context,
                  CompetitionRoutes.competitionCreateNav,
                );
              },
              icon: const Icon(Icons.add),
              tooltip: context.tr(LocaleKeys.createCompetition),
            ),
        ],
      ),
      drawer: MyDrawer(),
      body: CompetitionsListSEOWrapper(
        filter: _selectedFilter,
        child: Column(
          children: [
            if (_showFilters)
              CompeFilters(
                selectedFilter: _selectedFilter,
                onFilterChanged: (value) {
                  setState(() {
                    _selectedFilter = value;
                  });
                  _fetchWithFilters();
                },
                onSearchChanged: (value) {
                  _searchQuery = value;
                  _searchDebounce?.cancel();
                  _searchDebounce = Timer(
                    const Duration(milliseconds: 400),
                    _fetchWithFilters,
                  );
                },
              ),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  BlocConsumer<CompetitionsCubit, CompetitionsState> _buildContent() {
    return BlocConsumer<CompetitionsCubit, CompetitionsState>(
      listener: (context, state) {
        if (state is CompetitionCreated) {
          SnackBarHelper.showSuccess(context, LocaleKeys.competitionCreated);
        } else if (state is CompetitionUpdated) {
          SnackBarHelper.showSuccess(context, LocaleKeys.competitionUpdated);
        } else if (state is CompetitionsError) {
          SnackBarHelper.showError(context, state.message);
        }
      },
      builder: (context, state) {
        //CARGAR CUERPO

        if (state is CompetitionsLoaded) {
          return LocationAwareList<Competition>(
            showLocationBar: _showFilters,
            items: state.competitions,
            isLoading: state is CompetitionsLoadingMore,
            getLatitude: (competition) => competition.latitude,
            getLongitude: (competition) => competition.longitude,
            onRefresh: _fetchWithFilters,
            emptyWidget: _buildEmptyState(context),
            builder: (context, filteredCompetitions) {
              return RefreshIndicator(
                onRefresh: () async => _fetchWithFilters(),
                child: _isGridView
                    ? _buildGridView(filteredCompetitions, state)
                    : _buildListView(filteredCompetitions, state),
              );
            },
          );
        }
        // LOADING
        if (state is CompetitionsLoading || state is CompetitionsInitial) {
          return CompetitionCardSkeleton();
        }
        if (state is CompetitionsError) {
          return ErrorCard(message: state.message, onRetry: _fetchWithFilters);
        }

        return Center(child: MyText(LocaleKeys.unknownState));
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.emoji_events,
            size: 100,
            color: theme.colorScheme.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 20),
          MyText(LocaleKeys.noResultsFound, istitle: true),
        ],
      ),
    );
  }

  Widget _buildListView(
    List<Competition> competitions,
    CompetitionsLoaded state,
  ) {
    final isMobile = ResponsiveBreakpoints.isMobile(getWidth(context));
    final horizontalPadding = ResponsiveBreakpoints.getHorizontalPadding(
      getWidth(context),
    );
    final verticalPadding = ResponsiveBreakpoints.getVerticalPadding(
      getWidth(context),
    );

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      itemCount: competitions.length + (state.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == competitions.length) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final competition = competitions[index];
        return UnifiedCompetitionCard(
          competition: competition,
          layout: CompetitionCardLayout.list,
          isCompact: isMobile,
        ).withDistanceBadge(
          latitude: competition.latitude,
          longitude: competition.longitude,
        );
      },
    );
  }

  Widget _buildGridView(
    List<Competition> competitions,
    CompetitionsLoaded state,
  ) {
    final crossAxisCount = _getGridColumns(getWidth(context));
    final horizontalPadding = ResponsiveBreakpoints.getHorizontalPadding(
      getWidth(context),
    );
    final verticalPadding = ResponsiveBreakpoints.getVerticalPadding(
      getWidth(context),
    );
    final spacing = ResponsiveBreakpoints.getSpacing(getWidth(context));

    final childAspectRatio = getWidth(context) < ResponsiveBreakpoints.mobile
        ? 0.85
        : getWidth(context) < ResponsiveBreakpoints.tablet
        ? 0.9
        : 0.95;

    return GridView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: competitions.length + (state.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == competitions.length) {
          return const Center(child: CircularProgressIndicator());
        }
        final competition = competitions[index];
        return UnifiedCompetitionCard(
          competition: competition,
          layout: CompetitionCardLayout.grid,
        ).withDistanceBadge(
          latitude: competition.latitude,
          longitude: competition.longitude,
        );
      },
    );
  }
}
