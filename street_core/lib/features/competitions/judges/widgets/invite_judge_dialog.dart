/// Widget de diálogo para invitar jueces
/// Tres modos: por email, buscar usuario, o agregar juez externo
///
/// Siguiendo la arquitectura Monolith-by-Features (ADR-005).

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:street_core/core/lang/locale_keys.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/helpers/snackbar_helper.dart';
import '../../../../core/lang/context_tr.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/widgets/my_text.dart';
import '../../../../data/models/user_model.dart';
import '../../../profile/profile_uris.dart';
import '../../../profile/widgets/user_list_item.dart';
import '../../bloc/competitions_cubit.dart';
import '../../models/competition.dart';
import '../../repositories/judge_invitation_repository.dart';

/// Enum para los modos de invitación
enum InviteMode { email, searchUser, externalJudge }

/// Muestra el diálogo de invitar juez
Future<void> showInviteJudgeDialog(
  BuildContext context,
  Competition competition,
) {
  return showDialog(
    context: context,
    builder: (dialogContext) => InviteJudgeDialog(
      competition: competition,
      onSuccess: () {
        // Refresh competition data
        context.read<CompetitionsCubit>().fetchById(competition.id);
      },
    ),
  );
}

class InviteJudgeDialog extends StatefulWidget {
  const InviteJudgeDialog({
    super.key,
    required this.competition,
    this.onSuccess,
  });

  final Competition competition;
  final VoidCallback? onSuccess;

  @override
  State<InviteJudgeDialog> createState() => _InviteJudgeDialogState();
}

class _InviteJudgeDialogState extends State<InviteJudgeDialog> {
  InviteMode _currentMode = InviteMode.email;
  bool _isLoading = false;

  // Controllers para cada modo
  final _emailController = TextEditingController();
  final _userSearchController = TextEditingController();
  final _externalNameController = TextEditingController();
  final _messageController = TextEditingController();

  // User search state
  List<UserModel> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounceTimer;
  String? _selectedUserId;
  String? _selectedUserName;

  @override
  void initState() {
    super.initState();
    _userSearchController.addListener(_onSearchTextChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _emailController.dispose();
    _userSearchController.dispose();
    _externalNameController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _onSearchTextChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _searchUsers(_userSearchController.text);
    });
  }

  Future<void> _searchUsers(String query) async {
    if (query.length < 2) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final apiService = getIt<ApiService>();
      final response = await apiService.useFetch(
        ProfileUris.searchUsers(query: query, limit: 10),
        method: 'GET',
      );

      if (response.status == 'success' && response.data != null) {
        final List<dynamic> data = response.data['data'] ?? [];
        setState(() {
          _searchResults = data.map((json) => UserModel.fromJson(json)).toList();
          _isSearching = false;
        });
      } else {
        setState(() {
          _isSearching = false;
          _searchResults = [];
        });
      }
    } catch (e) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
    }
  }

  void _selectUser(UserModel user) {
    setState(() {
      _selectedUserId = user.id;
      _selectedUserName = user.nickName ?? user.firstName;
      _userSearchController.text = _selectedUserName!;
      _searchResults = [];
    });
  }

  void _clearSelectedUser() {
    setState(() {
      _selectedUserId = null;
      _selectedUserName = null;
      _searchResults = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context),
              const SizedBox(height: 16),
              _buildModeSelector(context),
              const SizedBox(height: 24),
              Flexible(child: _buildModeContent(context)),
              const SizedBox(height: 24),
              _buildActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withAlpha(30),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.person_add, color: Theme.of(context).primaryColor),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MyText(
                context.tr(LocaleKeys.inviteJudge),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              const SizedBox(height: 4),
              MyText(
                widget.competition.title,
                fontSize: 14,
                color: Colors.grey[600],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildModeSelector(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildModeButton(
            context,
            mode: InviteMode.email,
            icon: Icons.email_outlined,
            label: context.tr(LocaleKeys.byEmail),
          ),
          _buildModeButton(
            context,
            mode: InviteMode.searchUser,
            icon: Icons.search,
            label: context.tr(LocaleKeys.searchUser),
          ),
          _buildModeButton(
            context,
            mode: InviteMode.externalJudge,
            icon: Icons.person_outline,
            label: context.tr(LocaleKeys.externalJudge),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton(
    BuildContext context, {
    required InviteMode mode,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _currentMode == mode;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentMode = mode),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).primaryColor : null,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeContent(BuildContext context) {
    switch (_currentMode) {
      case InviteMode.email:
        return _buildEmailMode(context);
      case InviteMode.searchUser:
        return _buildSearchUserMode(context);
      case InviteMode.externalJudge:
        return _buildExternalJudgeMode(context);
    }
  }

  Widget _buildEmailMode(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MyText(
            context.tr(LocaleKeys.inviteByEmailDescription),
            fontSize: 14,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: context.tr(LocaleKeys.email),
              hintText: 'juez@ejemplo.com',
              prefixIcon: const Icon(Icons.email_outlined),
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
            enabled: !_isLoading,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _messageController,
            decoration: InputDecoration(
              labelText: context.tr(LocaleKeys.messageOptional),
              hintText: context.tr(LocaleKeys.invitationMessageHint),
              prefixIcon: const Icon(Icons.message_outlined),
              border: const OutlineInputBorder(),
            ),
            maxLines: 3,
            enabled: !_isLoading,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchUserMode(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MyText(
            context.tr(LocaleKeys.searchUserDescription),
            fontSize: 14,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _userSearchController,
            decoration: InputDecoration(
              labelText: context.tr(LocaleKeys.usernameOrId),
              hintText: context.tr(LocaleKeys.searchUserHint),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _selectedUserId != null
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _userSearchController.clear();
                        _clearSelectedUser();
                      },
                    )
                  : _isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
              border: const OutlineInputBorder(),
            ),
            enabled: !_isLoading,
          ),
          const SizedBox(height: 16),

          // Search results
          if (_searchResults.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _searchResults.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final user = _searchResults[index];
                  return InkWell(
                    onTap: () => _selectUser(user),
                    child: UserListItem(user: user),
                  );
                },
              ),
            )
          else if (_selectedUserId != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withAlpha(50)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${context.tr(LocaleKeys.selectedUser)}: $_selectedUserName',
                      style: TextStyle(fontSize: 13, color: Colors.green[700]),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withAlpha(50)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      context.tr(LocaleKeys.enterUserIdToInvite),
                      style: TextStyle(fontSize: 13, color: Colors.blue[700]),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          TextField(
            controller: _messageController,
            decoration: InputDecoration(
              labelText: context.tr(LocaleKeys.messageOptional),
              hintText: context.tr(LocaleKeys.invitationMessageHint),
              prefixIcon: const Icon(Icons.message_outlined),
              border: const OutlineInputBorder(),
            ),
            maxLines: 2,
            enabled: !_isLoading,
          ),
        ],
      ),
    );
  }

  Widget _buildExternalJudgeMode(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MyText(
            context.tr(LocaleKeys.externalJudgeDescription),
            fontSize: 14,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _externalNameController,
            decoration: InputDecoration(
              labelText: context.tr(LocaleKeys.fullName),
              hintText: context.tr(LocaleKeys.externalJudgeNameHint),
              prefixIcon: const Icon(Icons.person_outline),
              border: const OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.words,
            enabled: !_isLoading,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withAlpha(50)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    context.tr(LocaleKeys.externalJudgeInfo),
                    style: TextStyle(fontSize: 13, color: Colors.green[700]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: Text(context.tr(LocaleKeys.cancel)),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _handleInvite,
          icon: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send),
          label: Text(_getButtonLabel(context)),
        ),
      ],
    );
  }

  String _getButtonLabel(BuildContext context) {
    switch (_currentMode) {
      case InviteMode.email:
        return context.tr(LocaleKeys.sendInvitation);
      case InviteMode.searchUser:
        return context.tr(LocaleKeys.invite);
      case InviteMode.externalJudge:
        return context.tr(LocaleKeys.addJudge);
    }
  }

  Future<void> _handleInvite() async {
    setState(() => _isLoading = true);

    try {
      switch (_currentMode) {
        case InviteMode.email:
          await _inviteByEmail();
          break;
        case InviteMode.searchUser:
          await _inviteByUserId();
          break;
        case InviteMode.externalJudge:
          await _addExternalJudge();
          break;
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _inviteByEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      throw Exception(context.tr(LocaleKeys.emailRequired));
    }

    // Validate email format
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      throw Exception(context.tr(LocaleKeys.invalidEmail));
    }

    final repository = getIt<JudgeInvitationRepository>();
    await repository.createInvitation(widget.competition.id, {
      'invitedUserEmail': email,
      if (_messageController.text.isNotEmpty)
        'message': _messageController.text,
    });

    if (mounted) {
      SnackBarHelper.showSuccess(context, context.tr(LocaleKeys.invitationSent));
      widget.onSuccess?.call();
      Navigator.pop(context);
    }
  }

  Future<void> _inviteByUserId() async {
    // Use the selected user ID if available, otherwise fallback to text input
    final userId = _selectedUserId ?? _userSearchController.text.trim();
    if (userId.isEmpty) {
      throw Exception(context.tr(LocaleKeys.userIdRequired));
    }

    final repository = getIt<JudgeInvitationRepository>();
    await repository.createInvitation(widget.competition.id, {
      'userId': userId,
      if (_messageController.text.isNotEmpty)
        'message': _messageController.text,
    });

    if (mounted) {
      SnackBarHelper.showSuccess(context, context.tr(LocaleKeys.invitationSent));
      widget.onSuccess?.call();
      Navigator.pop(context);
    }
  }

  Future<void> _addExternalJudge() async {
    final name = _externalNameController.text.trim();
    if (name.isEmpty) {
      throw Exception(context.tr(LocaleKeys.nameRequired));
    }

    final repository = getIt<JudgeInvitationRepository>();
    await repository.createInvitation(widget.competition.id, {
      'externalJudgeName': name,
    });

    if (mounted) {
      SnackBarHelper.showSuccess(context, context.tr(LocaleKeys.externalJudgeAdded));
      widget.onSuccess?.call();
      Navigator.pop(context);
    }
  }
}
