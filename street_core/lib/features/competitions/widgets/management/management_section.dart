/// Widget de Sección de Gestión para Organizadores
/// Permite aprobar/rechazar participantes y gestionar la competición.
/// Following Monolith-by-Features architecture (ADR-005).

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:street_core/core/lang/locale_keys.dart';

import '../../../../core/helpers/snackbar_helper.dart';
import '../../../../core/lang/context_tr.dart';
import '../../../../core/widgets/help_guide/bloc/guide_cubit.dart';
import '../../../../core/widgets/help_guide/widgets/guide_overlay.dart';
import '../../models/competition.dart';
import '../../models/participant.dart';
import '../../services/participant_service.dart';
import 'all_participants_section.dart';
import 'management_stats_card.dart';
import 'pending_approvals_section.dart';
import 'reject_participant_dialog.dart';

class ManagementSection extends StatefulWidget {
  final String competitionId;
  final Competition competition;

  const ManagementSection({
    super.key,
    required this.competitionId,
    required this.competition,
  });

  @override
  State<ManagementSection> createState() => _ManagementSectionState();
}

class _ManagementSectionState extends State<ManagementSection> {
  final ParticipantService _service = GetIt.I<ParticipantService>();

  List<Participant> _pendingParticipants = [];
  List<Participant> _allParticipants = [];
  ParticipantCounts _counts = const ParticipantCounts();
  bool _isLoading = true;
  String? _error;
  Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _loadData();

    // Load help guide for competition management
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<GuideCubit>().loadGuideForRoute('/competitions/manage');
      }
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _service.fetchPending(widget.competitionId),
        _service.fetchAll(widget.competitionId),
        _service.fetchCounts(widget.competitionId),
      ]);

      if (!mounted) return;

      setState(() {
        _pendingParticipants = (results[0] as List<Map<String, dynamic>>)
            .map((e) => Participant.fromJson(e))
            .toList();
        _allParticipants = (results[1] as List<Map<String, dynamic>>)
            .map((e) => Participant.fromJson(e))
            .toList();
        _counts = results[2] as ParticipantCounts;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _approveParticipant(Participant participant) async {
    try {
      await _service.approve(widget.competitionId, participant.id);
      if (!mounted) return;
      SnackBarHelper.showSuccess(context, LocaleKeys.participantApproved);
      _loadData();
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showError(context, LocaleKeys.errorApprovingParticipant);
    }
  }

  Future<void> _rejectParticipant(Participant participant) async {
    final reason = await showRejectParticipantDialog(context);
    if (reason == null) return;
    if (!mounted) return;

    try {
      await _service.reject(widget.competitionId, participant.id);
      if (!mounted) return;
      SnackBarHelper.showWarning(context, LocaleKeys.participantRejected);
      _loadData();
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showError(context, LocaleKeys.errorRejectingParticipant);
    }
  }

  Future<void> _bulkApprove() async {
    if (_selectedIds.isEmpty) return;

    try {
      await _service.bulkApprove(widget.competitionId, _selectedIds.toList());
      if (!mounted) return;
      SnackBarHelper.showSuccess(context, LocaleKeys.participantsApproved);
      setState(() => _selectedIds.clear());
      _loadData();
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showError(context, LocaleKeys.errorApprovingParticipants);
    }
  }

  Future<void> _bulkReject() async {
    if (_selectedIds.isEmpty) return;

    final reason = await showRejectParticipantDialog(context);
    if (reason == null) return;
    if (!mounted) return;

    try {
      await _service.bulkReject(widget.competitionId, _selectedIds.toList());
      if (!mounted) return;
      SnackBarHelper.showWarning(context, LocaleKeys.participantsRejected);
      setState(() => _selectedIds.clear());
      _loadData();
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showError(context, LocaleKeys.errorRejectingParticipants);
    }
  }

  void _toggleSelection(String participantId) {
    setState(() {
      if (_selectedIds.contains(participantId)) {
        _selectedIds.remove(participantId);
      } else {
        _selectedIds.add(participantId);
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectedIds = _pendingParticipants.map((p) => p.id).toSet();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text('${context.tr(LocaleKeys.error)}: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: Text(context.tr(LocaleKeys.retry)),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _loadData,
          child: CustomScrollView(
            slivers: [
              // Stats header
              SliverToBoxAdapter(
                child: ManagementStatsCard(
                  counts: _counts,
                  requiresApproval: widget.competition.requiresApproval,
                ),
              ),

              // Pending approvals section
              SliverToBoxAdapter(
                child: PendingApprovalsSection(
                  participants: _pendingParticipants,
                  selectedIds: _selectedIds,
                  onToggleSelection: _toggleSelection,
                  onSelectAll: _selectAll,
                  onApprove: _approveParticipant,
                  onReject: _rejectParticipant,
                  onBulkApprove: _bulkApprove,
                  onBulkReject: _bulkReject,
                ),
              ),

              // All participants section
              SliverToBoxAdapter(
                child: AllParticipantsSection(
                  participants: _allParticipants,
                ),
              ),

              // Bottom padding
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        ),

        // Help guide widgets
        const AutoGuide(),
        const GuideOverlay(),
      ],
    );
  }
}
