// lib/features/livestreams/pages/live_streams_list_page.dart

import 'package:flutter/material.dart';
import 'package:street_core/core/services/api_service.dart';
import 'package:street_core/core/theme/app_spacing.dart';
import 'package:street_core/data/models/paginated_result.dart';
import 'package:street_core/features/livestreams/models/models.dart';
import 'package:street_core/features/livestreams/services/livestream_service.dart';
import 'package:street_core/features/livestreams/widgets/widgets.dart';
import 'package:street_core/core/lang/context_tr.dart';
import 'package:street_core/core/lang/locale_keys.dart';
import 'package:street_core/core/widgets/my_text.dart';

/// Page showing list of livestreams
///
/// Tabs:
/// - Live: Currently streaming
/// - Scheduled: Upcoming streams
/// - My Streams: User's own streams
class LiveStreamsListPage extends StatefulWidget {
  const LiveStreamsListPage({super.key});

  @override
  State<LiveStreamsListPage> createState() => _LiveStreamsListPageState();
}

class _LiveStreamsListPageState extends State<LiveStreamsListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late LiveStreamService _service;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // TODO: Get from DI
    _service = LiveStreamService(ApiService());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Livestreams'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: context.tr(LocaleKeys.liveNow), icon: const Icon(Icons.circle, color: Colors.red)),
            Tab(text: context.tr(LocaleKeys.scheduled), icon: const Icon(Icons.schedule)),
            Tab(text: context.tr(LocaleKeys.myStreams), icon: const Icon(Icons.video_library)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearch(context),
            tooltip: context.tr(LocaleKeys.search),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _LiveStreamsTab(service: _service),
          _ScheduledStreamsTab(service: _service),
          _MyStreamsTab(service: _service),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToCreateStream(context),
        icon: const Icon(Icons.videocam),
        label: MyText(LocaleKeys.transmit),
      ),
    );
  }

  void _showSearch(BuildContext context) {
    showSearch(
      context: context,
      delegate: _LiveStreamSearchDelegate(_service),
    );
  }

  void _navigateToCreateStream(BuildContext context) {
    // TODO: Navigate to create stream page
    Navigator.pushNamed(context, '/livestreams/create');
  }
}

/// Tab showing live streams
class _LiveStreamsTab extends StatelessWidget {
  final LiveStreamService service;

  const _LiveStreamsTab({required this.service});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PaginatedResult<LiveStream>>(
      future: service.getLiveStreams(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                SizedBox(height: AppSpacing.md),
                MyText(
                  LocaleKeys.errorLoadingStreams,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: () => (context as Element).markNeedsBuild(),
                  child: MyText(LocaleKeys.retry),
                ),
              ],
            ),
          );
        }

        final streams = snapshot.data?.items ?? [];

        if (streams.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.videocam_off, size: 64, color: Colors.grey[400]),
                SizedBox(height: AppSpacing.md),
                MyText(
                  LocaleKeys.noLiveStreams,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SizedBox(height: AppSpacing.sm),
                MyText(LocaleKeys.beTheFirstToTransmit),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            (context as Element).markNeedsBuild();
          },
          child: GridView.builder(
            padding: EdgeInsets.all(AppSpacing.md),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: streams.length,
            itemBuilder: (context, index) {
              return LiveStreamCard.grid(
                stream: streams[index],
                onTap: () => _navigateToStream(context, streams[index]),
              );
            },
          ),
        );
      },
    );
  }

  void _navigateToStream(BuildContext context, LiveStream stream) {
    Navigator.pushNamed(
      context,
      '/livestreams/view',
      arguments: stream.id,
    );
  }
}

/// Tab showing scheduled streams
class _ScheduledStreamsTab extends StatelessWidget {
  final LiveStreamService service;

  const _ScheduledStreamsTab({required this.service});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PaginatedResult<LiveStream>>(
      future: service.getScheduledStreams(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: MyText(LocaleKeys.errorLoadingStreams));
        }

        final streams = snapshot.data?.items ?? [];

        if (streams.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.schedule, size: 64, color: Colors.grey[400]),
                SizedBox(height: AppSpacing.md),
                MyText(
                  LocaleKeys.noResultsFound,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(AppSpacing.md),
          itemCount: streams.length,
          itemBuilder: (context, index) {
            return LiveStreamCard.list(
              stream: streams[index],
              onTap: () => _navigateToStream(context, streams[index]),
            );
          },
        );
      },
    );
  }

  void _navigateToStream(BuildContext context, LiveStream stream) {
    Navigator.pushNamed(
      context,
      '/livestreams/view',
      arguments: stream.id,
    );
  }
}

/// Tab showing user's streams
class _MyStreamsTab extends StatelessWidget {
  final LiveStreamService service;

  const _MyStreamsTab({required this.service});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PaginatedResult<LiveStream>>(
      future: service.getMyStreams(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: MyText(LocaleKeys.errorLoadingMyStreams));
        }

        final streams = snapshot.data?.items ?? [];

        if (streams.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.video_library, size: 64, color: Colors.grey[400]),
                SizedBox(height: AppSpacing.md),
                MyText(
                  LocaleKeys.noMyStreams,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SizedBox(height: AppSpacing.sm),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/livestreams/create');
                  },
                  icon: const Icon(Icons.add),
                  label: MyText(LocaleKeys.createLivestream),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(AppSpacing.md),
          itemCount: streams.length,
          itemBuilder: (context, index) {
            return LiveStreamCard.list(
              stream: streams[index],
              onTap: () => _navigateToStream(context, streams[index]),
            );
          },
        );
      },
    );
  }

  void _navigateToStream(BuildContext context, LiveStream stream) {
    if (stream.isLive || stream.isScheduled) {
      // Navigate as host
      Navigator.pushNamed(
        context,
        '/livestreams/host',
        arguments: stream.id,
      );
    } else {
      // Navigate as viewer (VOD)
      Navigator.pushNamed(
        context,
        '/livestreams/view',
        arguments: stream.id,
      );
    }
  }
}

/// Search delegate for streams
class _LiveStreamSearchDelegate extends SearchDelegate<LiveStream?> {
  final LiveStreamService service;

  _LiveStreamSearchDelegate(this.service);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.isEmpty) {
      return Center(child: MyText(LocaleKeys.typeToSearch));
    }

    return FutureBuilder<PaginatedResult<LiveStream>>(
      future: service.searchStreams(query: query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final streams = snapshot.data?.items ?? [];

        if (streams.isEmpty) {
          return Center(child: MyText(LocaleKeys.noResultsFound));
        }

        return ListView.builder(
          itemCount: streams.length,
          itemBuilder: (context, index) {
            return LiveStreamCard.list(
              stream: streams[index],
              onTap: () => close(context, streams[index]),
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return buildResults(context);
  }
}
