/// Widget de Sección de Lista de Participantes
/// Muestra la lista de participantes registrados en una competición.
/// Siguiendo la arquitectura Monolith-by-Features (ADR-005).

import 'package:flutter/material.dart';
import 'package:street_core/core/lang/context_tr.dart';
import '../../../../core/lang/locale_keys.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/widgets/my_text.dart';
import '../../models/participant.dart';
import '../../services/participant_service.dart';

class ParticipantsListSection extends StatefulWidget {
  final String competitionId;

  const ParticipantsListSection({super.key, required this.competitionId});

  @override
  State<ParticipantsListSection> createState() =>
      _ParticipantsListSectionState();
}

class _ParticipantsListSectionState extends State<ParticipantsListSection> {
  late final ParticipantService _participantService;
  List<Participant> _participants = [];
  ParticipantCounts _counts = const ParticipantCounts();
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _participantService = getIt<ParticipantService>();
    _loadParticipants();
  }

  Future<void> _loadParticipants() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Fetch participants (required)
      final participantsData =
          await _participantService.fetchAll(widget.competitionId);

      // Try to fetch counts (optional - might not exist on backend)
      ParticipantCounts counts = const ParticipantCounts();
      try {
        counts = await _participantService.fetchCounts(widget.competitionId);
      } catch (_) {
        // If counts endpoint doesn't exist, calculate from participants
        final approved = participantsData
            .where((p) => p['status'] == 'approved' || p['status'] == 'registered')
            .length;
        final pending =
            participantsData.where((p) => p['status'] == 'pending').length;
        final checkedIn =
            participantsData.where((p) => p['status'] == 'checked_in').length;
        counts = ParticipantCounts(
          approved: approved,
          pending: pending,
          checkedIn: checkedIn,
          total: participantsData.length,
        );
      }

      setState(() {
        _participants =
            participantsData.map((json) => Participant.fromJson(json)).toList();
        _counts = counts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildErrorState(context);
    }

    if (_participants.isEmpty) {
      return _buildEmptyState(context);
    }

    return _buildContent(context);
  }

  Widget _buildContent(BuildContext context) {
    // Separar por estado
    final approved = _participants.where((p) => p.isApproved).toList();
    final pending = _participants.where((p) => p.isPending).toList();
    final checkedIn = _participants.where((p) => p.isCheckedIn).toList();

    return RefreshIndicator(
      onRefresh: _loadParticipants,
      child: CustomScrollView(
        slivers: [
          // Header con estadísticas
          SliverToBoxAdapter(
            child: _buildHeader(context),
          ),

          // Checked In
          if (checkedIn.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _buildSectionTitle(
                context,
                LocaleKeys.checkedInCount,
                checkedIn.length,
                Colors.blue,
                Icons.check_circle,
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildParticipantCard(
                  context,
                  checkedIn[index],
                  index + 1,
                ),
                childCount: checkedIn.length,
              ),
            ),
          ],

          // Aprobados
          if (approved.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _buildSectionTitle(
                context,
                LocaleKeys.approvedCount,
                approved.length,
                Colors.green,
                Icons.verified,
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildParticipantCard(
                  context,
                  approved[index],
                  index + 1,
                ),
                childCount: approved.length,
              ),
            ),
          ],

          // Pendientes
          if (pending.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _buildSectionTitle(
                context,
                LocaleKeys.pendingCount,
                pending.length,
                Colors.orange,
                Icons.hourglass_empty,
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildParticipantCard(
                  context,
                  pending[index],
                  index + 1,
                ),
                childCount: pending.length,
              ),
            ),
          ],

          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final total = _counts.total;
    final active = _counts.active;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                MyText(
                  LocaleKeys.participants,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                MyText(
                  LocaleKeys.activeOutOfTotal,
                  args: {'active': '$active', 'total': '$total'},
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatChip(
                  context,
                  LocaleKeys.approved,
                  _counts.approved,
                  Colors.green,
                ),
                _buildStatChip(
                  context,
                  LocaleKeys.pending,
                  _counts.pending,
                  Colors.orange,
                ),
                _buildStatChip(
                  context,
                  LocaleKeys.registered,
                  _counts.checkedIn,
                  Colors.blue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(
    BuildContext context,
    String labelKey,
    int count,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: color.withAlpha(30),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        const SizedBox(height: 4),
        MyText(
          labelKey,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(
    BuildContext context,
    String titleKey,
    int count,
    Color color,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          MyText(
            '$titleKey ($count)',
            noTranslation: true, // Key is already translated, just adding count
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            MyText(
              LocaleKeys.noParticipants,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
            const SizedBox(height: 8),
            MyText(
              LocaleKeys.noParticipantsInCompetition,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadParticipants,
              icon: const Icon(Icons.refresh),
              label: const MyText(LocaleKeys.refresh),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
            const SizedBox(height: 16),
            MyText(
              LocaleKeys.error,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
            const SizedBox(height: 8),
            MyText(
              _error ?? context.tr(LocaleKeys.errorUnknown),
              noTranslation: _error != null,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadParticipants,
              icon: const Icon(Icons.refresh),
              label: const MyText(LocaleKeys.retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantCard(
    BuildContext context,
    Participant participant,
    int number,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(participant.status),
          child: participant.athleteName.isNotEmpty
              ? Text(
                  participant.athleteName[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : MyText(
                  LocaleKeys.participantNumber,
                  args: {'number': '$number'},
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
        ),
        title: MyText(
          participant.athleteName.isNotEmpty
              ? participant.athleteName
              : context.tr(LocaleKeys.participantNumber, args: {'number': '$number'}),
          noTranslation: participant.athleteName.isNotEmpty,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (participant.athleteEmail != null)
              Text(
                participant.athleteEmail!,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            if (participant.categoryName != null)
              Row(
                children: [
                  Icon(Icons.category, size: 12, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    participant.categoryName!,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            if (participant.registeredAt != null)
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 12, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(participant.registeredAt!),
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
          ],
        ),
        trailing: _buildStatusChip(participant.status),
        isThreeLine: true,
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'registered':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'checked_in':
        return Colors.blue;
      case 'rejected':
        return Colors.red;
      case 'withdrawn':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String labelKey;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'approved':
      case 'registered':
        color = Colors.green;
        labelKey = LocaleKeys.approved;
        icon = Icons.check_circle;
        break;
      case 'pending':
        color = Colors.orange;
        labelKey = LocaleKeys.pending;
        icon = Icons.schedule;
        break;
      case 'checked_in':
        color = Colors.blue;
        labelKey = LocaleKeys.checkedInCount; // Assuming this key exists
        icon = Icons.how_to_reg;
        break;
      case 'rejected':
        color = Colors.red;
        labelKey = LocaleKeys.rejected;
        icon = Icons.cancel;
        break;
      case 'withdrawn':
        color = Colors.grey;
        labelKey = 'withdrawn'; // Needs a key
        icon = Icons.exit_to_app;
        break;
      default:
        color = Colors.grey;
        labelKey = status;
        icon = Icons.help_outline;
    }

    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: MyText(labelKey,
          noTranslation: labelKey == status || labelKey == 'withdrawn',
          style: TextStyle(fontSize: 11, color: color)),
      backgroundColor: color.withAlpha(30),
      side: BorderSide.none,
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
