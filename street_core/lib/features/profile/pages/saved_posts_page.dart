// lib/features/profile/pages/saved_posts_page.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
import '../../../core/helpers/snackbar_helper.dart';
// ignore: unused_import
import '../../../core/lang/context_tr.dart';
import '../../../core/lang/locale_keys.dart';
import '../../../core/services/api_service.dart';
import '../../../core/widgets/my_text.dart';
import '../models/post_model.dart';
import '../profile_routes.dart';
import '../repositories/post_repository.dart';
import '../widgets/loading_skeleton.dart';

/// Page displaying user's saved posts
/// Shows posts saved by the current user in a grid layout
class SavedPostsPage extends StatefulWidget {
  const SavedPostsPage({super.key});

  @override
  State<SavedPostsPage> createState() => _SavedPostsPageState();
}

class _SavedPostsPageState extends State<SavedPostsPage> {
  late final PostRepository _postsRepository = PostRepository(
    getIt<ApiService>(),
  );
  List<PostModel> _savedPosts = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSavedPosts();
  }

  Future<void> _loadSavedPosts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _postsRepository.getSavedPosts();

      if (!mounted) return;

      if (response.status == 'success') {
        setState(() {
          _savedPosts = response.data ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _unsavePost(String postId) async {
    try {
      await _postsRepository.unsavePost(postId);
      if (!mounted) return;
      setState(() {
        _savedPosts.removeWhere((post) => post.id == postId);
      });

      SnackBarHelper.showInfo(context, LocaleKeys.postUnsaved);
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showError(context, LocaleKeys.errorRemovingPost);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.bookmark),
            const SizedBox(width: 8),
            const MyText(LocaleKeys.savedPosts),
          ],
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: PostGridSkeletonLoader());
    }

    if (_errorMessage != null) {
      
               //TODO ErroCard deberiamos usar
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            MyText(_errorMessage!),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadSavedPosts, child: MyText(LocaleKeys.retry)),
          ],
        ),
      );
    }

    if (_savedPosts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bookmark_border, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            MyText(
              LocaleKeys.noSavedPosts,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            MyText(
              LocaleKeys.postsSavedAppearHere,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSavedPosts,
      child: GridView.builder(
        padding: const EdgeInsets.all(2),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemCount: _savedPosts.length,
        itemBuilder: (context, index) {
          final post = _savedPosts[index];
          return _buildPostGridItem(post);
        },
      ),
    );
  }

  Widget _buildPostGridItem(PostModel post) {
    return GestureDetector(
      onTap: () {
        // Navigate to post detail
        context.push(ProfileRoutes.getPostDetail(post.id));
      },
      onLongPress: () {
        _showPostOptions(post);
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Post image
          if (post.mediaUrls.isNotEmpty)
            Image.network(
              post.mediaUrls.first,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.image, size: 40),
                );
              },
            )
          else
            Container(
              color: Colors.grey.shade200,
              padding: const EdgeInsets.all(8),
              child: Text(
                post.caption, // Caption is user content, not translatable
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            ),

          // Overlay for carousel indicator
          if (post.mediaUrls.length > 1)
            Positioned(
              top: 8,
              right: 8,
              child: Icon(
                Icons.layers,
                color: Colors.white,
                size: 20,
                shadows: [
                  Shadow(color: Colors.black.withAlpha(128), blurRadius: 4),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showPostOptions(PostModel post) {
    showModalBottomSheet(
      context: context,
      builder: (modalContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.bookmark_remove, color: Colors.red),
              title: MyText(
                LocaleKeys.removeFromSaved,
                style: const TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(modalContext);
                _unsavePost(post.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: MyText(LocaleKeys.share),
              onTap: () {
                Navigator.pop(modalContext);
                // Implement share functionality
              },
            ),
          ],
        ),
      ),
    );
  }
}
