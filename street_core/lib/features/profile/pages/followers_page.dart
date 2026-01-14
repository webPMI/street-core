import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../../core/lang/context_tr.dart';
import '../../../core/lang/locale_keys.dart';
import '../../../core/widgets/my_text.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/user_repository.dart';
import '../widgets/user_list_item.dart';

/// Followers Page
/// Displays list of users who follow a specific user
class FollowersPage extends StatefulWidget {
  const FollowersPage({
    super.key,
    required this.userId,
    this.username = '',
  });
  final String userId;
  final String username;

  @override
  State<FollowersPage> createState() => _FollowersPageState();
}

class _FollowersPageState extends State<FollowersPage> {
  final _userRepository = getIt<UserRepository>();
  final _searchController = TextEditingController();

  bool _isLoading = true;
  List<UserModel> _followers = [];
  List<UserModel> _filteredFollowers = [];
  String? _errorMessage;
  String _username = '';

  @override
  void initState() {
    super.initState();
    _username = widget.username;
    _loadUserIfNeeded();
    _loadFollowers();
    _searchController.addListener(_filterFollowers);
  }

  Future<void> _loadUserIfNeeded() async {
    // If username is not provided, load it from API
    if (_username.isEmpty && widget.userId.isNotEmpty) {
      try {
        final user = await _userRepository.getUserById(widget.userId);
        setState(() {
          _username = user.nickName ?? user.firstName;
        });
      } catch (e) {
        setState(() {
          _username = 'User';
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFollowers() async {
    // Validate userId
    if (widget.userId.isEmpty) {
      setState(() {
        _errorMessage = LocaleKeys.invalidUserId;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final followers = await _userRepository.getFollowers(widget.userId);
      setState(() {
        _followers = followers;
        _filteredFollowers = followers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterFollowers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredFollowers = _followers;
      } else {
        _filteredFollowers = _followers.where((user) {
          final name = user.firstName.toLowerCase();
          final nickName = user.nickName?.toLowerCase() ?? '';
          return name.contains(query) || nickName.contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const MyText(LocaleKeys.followers,),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: context.tr(LocaleKeys.searchFollowers),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _searchController.clear,
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),

          // Followers List
          Expanded(child: _buildContent(theme)),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            MyText(_errorMessage!, fontSize: 14),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadFollowers, child: MyText(LocaleKeys.retry, selectable: false)),
          ],
        ),
      );
    }

    if (_filteredFollowers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            MyText(
              _searchController.text.isEmpty
                  ? context.tr(LocaleKeys.noFollowersYet)
                  : context.tr(LocaleKeys.noResultsFound),
              fontSize: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFollowers,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _filteredFollowers.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final user = _filteredFollowers[index];
          return UserListItem(user: user);
        },
      ),
    );
  }
}
