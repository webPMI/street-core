import 'package:flutter/material.dart';
import '../services/cache_service.dart';

/// Cache Statistics Widget
///
/// Displays real-time cache performance metrics in a card layout.
/// Useful for debugging, monitoring, and admin panels.
///
/// Features:
/// - Real-time statistics update
/// - Visual progress indicators
/// - Color-coded performance metrics
/// - Expandable details section
///
/// Usage:
/// ```dart
/// CacheStatsWidget(
///   cacheService: CacheService.instance,
///   autoRefresh: true,
///   refreshInterval: Duration(seconds: 5),
/// )
/// ```
class CacheStatsWidget extends StatefulWidget {
  const CacheStatsWidget({
    super.key,
    required this.cacheService,
    this.autoRefresh = false,
    this.refreshInterval = const Duration(seconds: 5),
    this.compact = false,
  });

  /// Cache service instance to monitor
  final CacheService cacheService;

  /// Auto-refresh statistics
  final bool autoRefresh;

  /// Refresh interval when auto-refresh is enabled
  final Duration refreshInterval;

  /// Compact mode (smaller card, fewer details)
  final bool compact;

  @override
  State<CacheStatsWidget> createState() => _CacheStatsWidgetState();
}

class _CacheStatsWidgetState extends State<CacheStatsWidget> {
  late CacheStats _stats;
  bool _showDetails = false;

  @override
  void initState() {
    super.initState();
    _stats = widget.cacheService.getStats();

    if (widget.autoRefresh) {
      Future.delayed(widget.refreshInterval, _autoRefresh);
    }
  }

  void _autoRefresh() {
    if (!mounted) return;

    setState(() {
      _stats = widget.cacheService.getStats();
    });

    if (widget.autoRefresh) {
      Future.delayed(widget.refreshInterval, _autoRefresh);
    }
  }

  void _refresh() {
    setState(() {
      _stats = widget.cacheService.getStats();
    });
  }

  Color _getHitRateColor(double hitRate, ThemeData theme) {
    if (hitRate >= 0.8) return Colors.green; // Excellent
    if (hitRate >= 0.6) return Colors.orange; // Good
    return theme.colorScheme.error; // Poor
  }

  Color _getUtilizationColor(double utilization, ThemeData theme) {
    if (utilization >= 90) return theme.colorScheme.error; // Critical
    if (utilization >= 70) return Colors.orange; // Warning
    return Colors.green; // Healthy
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.compact) {
      return _buildCompactCard(theme);
    }

    return _buildFullCard(theme);
  }

  Widget _buildCompactCard(ThemeData theme) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.storage,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Cache Stats',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh, size: 20),
                  tooltip: 'Refresh stats',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildCompactStat(
                  label: 'Hit Rate',
                  value: '${(_stats.hitRate * 100).toStringAsFixed(1)}%',
                  color: _getHitRateColor(_stats.hitRate, theme),
                  theme: theme,
                ),
                _buildCompactStat(
                  label: 'Entries',
                  value: '${_stats.validEntries}/${_stats.maxEntries}',
                  color: theme.colorScheme.primary,
                  theme: theme,
                ),
                _buildCompactStat(
                  label: 'Usage',
                  value: '${_stats.utilizationPercent.round()}%',
                  color: _getUtilizationColor(_stats.utilizationPercent, theme),
                  theme: theme,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactStat({
    required String label,
    required String value,
    required Color color,
    required ThemeData theme,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildFullCard(ThemeData theme) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.storage,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Cache Performance',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (!widget.autoRefresh)
                      IconButton(
                        onPressed: _refresh,
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Refresh stats',
                      ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _showDetails = !_showDetails;
                        });
                      },
                      icon: Icon(
                        _showDetails ? Icons.expand_less : Icons.expand_more,
                      ),
                      tooltip: _showDetails ? 'Hide details' : 'Show details',
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Main metrics
            _buildMetricRow(
              label: 'Hit Rate',
              value: '${(_stats.hitRate * 100).toStringAsFixed(1)}%',
              subtitle: '${_stats.hits} hits / ${_stats.misses} misses',
              color: _getHitRateColor(_stats.hitRate, theme),
              progress: _stats.hitRate,
              theme: theme,
            ),

            const SizedBox(height: 16),

            _buildMetricRow(
              label: 'Cache Utilization',
              value: '${_stats.utilizationPercent.round()}%',
              subtitle: '${_stats.validEntries} valid / ${_stats.maxEntries} max entries',
              color: _getUtilizationColor(_stats.utilizationPercent, theme),
              progress: _stats.utilizationPercent / 100,
              theme: theme,
            ),

            // Details section
            if (_showDetails) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              _buildDetailsSection(theme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow({
    required String label,
    required String value,
    required String subtitle,
    required Color color,
    required double progress,
    required ThemeData theme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0),
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detailed Statistics',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        _buildDetailRow('Total Entries', '${_stats.totalEntries}', theme),
        _buildDetailRow('Valid Entries', '${_stats.validEntries}', theme),
        _buildDetailRow('Expired Entries', '${_stats.expiredEntries}', theme),
        _buildDetailRow('Pending Requests', '${_stats.pendingRequests}', theme),
        _buildDetailRow('Cache Hits', '${_stats.hits}', theme),
        _buildDetailRow('Cache Misses', '${_stats.misses}', theme),
        _buildDetailRow(
          'Hit Rate',
          '${(_stats.hitRate * 100).toStringAsFixed(2)}%',
          theme,
        ),
        _buildDetailRow(
          'Miss Rate',
          '${(_stats.missRate * 100).toStringAsFixed(2)}%',
          theme,
        ),
        _buildDetailRow(
          'Utilization',
          '${_stats.utilizationPercent.toStringAsFixed(1)}%',
          theme,
        ),
        _buildDetailRow('Max Entries', '${_stats.maxEntries}', theme),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
