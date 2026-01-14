// lib/features/livestreams/pages/livestream_viewer_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:street_core/core/services/api_service.dart';
import 'package:street_core/core/theme/app_spacing.dart';
import 'package:street_core/core/helpers/snackbar_helper.dart';
import 'package:street_core/features/livestreams/bloc/livestream_chat_cubit.dart';
import 'package:street_core/features/livestreams/bloc/livestream_cubit.dart';
import 'package:street_core/features/livestreams/bloc/livestream_reactions_cubit.dart';
import 'package:street_core/features/livestreams/bloc/livestream_state.dart';
import 'package:street_core/features/livestreams/services/livestream_service.dart';
import 'package:street_core/features/livestreams/services/livestream_socket_service.dart';
import 'package:street_core/features/livestreams/widgets/widgets.dart';

/// Page for viewing a livestream as a viewer
class LiveStreamViewerPage extends StatelessWidget {
  final String streamId;

  const LiveStreamViewerPage({
    super.key,
    required this.streamId,
  });

  @override
  Widget build(BuildContext context) {
    // TODO: Get from DI
    final apiService = ApiService();
    final streamService = LiveStreamService(apiService);
    final socketService = LiveStreamSocketService(apiService);

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => LiveStreamCubit(
            service: streamService,
            socketService: socketService,
          )..joinStream(streamId),
        ),
        BlocProvider(
          create: (context) => LiveStreamChatCubit(
            service: streamService,
            socketService: socketService,
            streamId: streamId,
          )..initialize(),
        ),
        BlocProvider(
          create: (context) => LiveStreamReactionsCubit(
            service: streamService,
            socketService: socketService,
            streamId: streamId,
            screenWidth: MediaQuery.of(context).size.width,
            screenHeight: MediaQuery.of(context).size.height,
          ),
        ),
      ],
      child: const _LiveStreamViewerContent(),
    );
  }
}

class _LiveStreamViewerContent extends StatefulWidget {
  const _LiveStreamViewerContent();

  @override
  State<_LiveStreamViewerContent> createState() =>
      _LiveStreamViewerContentState();
}

class _LiveStreamViewerContentState extends State<_LiveStreamViewerContent> {
  bool _showChat = true;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Leave stream when navigating back
        await context.read<LiveStreamCubit>().leaveStream();
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: BlocConsumer<LiveStreamCubit, LiveStreamState>(
          listener: (context, state) {
            if (state is LiveStreamError) {
              SnackBarHelper.showCustom(context, state.message, type: SnackBarType.error);
              Navigator.pop(context);
            } else if (state is LiveStreamEnded) {
              _showStreamEndedDialog(context, state);
            }
          },
          builder: (context, state) {
            if (state is LiveStreamLoading) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }

            if (state is! LiveStreamLoaded) {
              return const Center(
                child: Text(
                  'Cargando...',
                  style: TextStyle(color: Colors.white),
                ),
              );
            }

            return Stack(
              children: [
                // Video player placeholder
                // TODO: Replace with Agora video player
                _buildVideoPlaceholder(state),

                // Floating reactions overlay
                BlocBuilder<LiveStreamReactionsCubit,
                    LiveStreamReactionsState>(
                  builder: (context, reactionsState) {
                    return FloatingReactionsOverlay(
                      reactions: reactionsState.reactions,
                    );
                  },
                ),

                // Top overlay (stats, live badge, close button)
                _buildTopOverlay(context, state),

                // Chat overlay (bottom half)
                if (_showChat) _buildChatOverlay(context),

                // Reaction buttons (right side)
                Positioned(
                  right: AppSpacing.md,
                  bottom: 120,
                  child: StreamReactionBar(
                    direction: Axis.vertical,
                    isCompact: true,
                    onReaction: (type) {
                      context
                          .read<LiveStreamReactionsCubit>()
                          .sendReaction(type);
                    },
                  ),
                ),

                // Toggle chat button
                Positioned(
                  left: AppSpacing.md,
                  bottom: 100,
                  child: FloatingActionButton.small(
                    onPressed: () => setState(() => _showChat = !_showChat),
                    backgroundColor: Colors.black.withValues(alpha: 0.7),
                    child: Icon(
                      _showChat ? Icons.chat : Icons.chat_bubble_outline,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildVideoPlaceholder(LiveStreamLoaded state) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.videocam,
              size: 64,
              color: Colors.white54,
            ),
            SizedBox(height: AppSpacing.md),
            const Text(
              'Video Player Placeholder',
              style: TextStyle(color: Colors.white54),
            ),
            const Text(
              'Agora RTC integration goes here',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopOverlay(BuildContext context, LiveStreamLoaded state) {
    return SafeArea(
      child: Container(
        padding: EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.7),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Live badge
            const LiveBadge(),

            SizedBox(width: AppSpacing.sm),

            // Stats
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    state.stream.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.visibility,
                          color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${state.viewerCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.access_time,
                          color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        _formatDuration(state.duration),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Close button
            IconButton(
              onPressed: () async {
                await context.read<LiveStreamCubit>().leaveStream();
                Navigator.pop(context);
              },
              icon: const Icon(Icons.close, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatOverlay(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      height: MediaQuery.of(context).size.height * 0.45,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withValues(alpha: 0.9),
              Colors.transparent,
            ],
          ),
        ),
        child: Column(
          children: [
            // Chat messages
            Expanded(
              child: BlocBuilder<LiveStreamChatCubit, LiveStreamChatState>(
                builder: (context, state) {
                  if (state is LiveStreamChatLoading) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  }

                  if (state is! LiveStreamChatLoaded) {
                    return const SizedBox.shrink();
                  }

                  return ListView.builder(
                    padding: EdgeInsets.all(AppSpacing.sm),
                    itemCount: state.messages.length,
                    itemBuilder: (context, index) {
                      return StreamChatBubble.compact(
                        message: state.messages[index],
                      );
                    },
                  );
                },
              ),
            ),

            // Chat input
            StreamChatInput(
              onSend: (message) {
                context.read<LiveStreamChatCubit>().sendMessage(message);
              },
              backgroundColor: Colors.black.withValues(alpha: 0.8),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  void _showStreamEndedDialog(BuildContext context, LiveStreamEnded state) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Stream Finalizado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('El stream "${state.stream.title}" ha finalizado.'),
            if (state.stats != null) ...[
              SizedBox(height: AppSpacing.md),
              StreamStatsWidget.fromStats(
                stats: state.stats!,
                direction: Axis.vertical,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close viewer page
            },
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
