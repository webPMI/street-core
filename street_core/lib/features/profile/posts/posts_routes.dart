// lib/features/profile/posts/posts_routes.dart

import 'pages/create_post_page.dart';
import 'pages/post_detail_page.dart';
import 'pages/posts_feed_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Posts routes - Social Media Module
/// All routes are relative (no leading '/')
final List<GoRoute> postsRoutes = [
  // Posts Feed - Main social feed
  GoRoute(path: 'posts', builder: (context, state) => const PostsFeedPage()),

  // Create Post - New post creation
  GoRoute(
    path: 'posts/create',
    builder: (context, state) => const CreatePostPage(),
  ),

  // Post Detail - View single post with comments
  GoRoute(
    path: 'posts/:id',
    builder: (context, state) {
      final postId = state.pathParameters['id'];

      // Validate postId
      if (postId == null || postId.isEmpty) {
        return const Scaffold(body: Center(child: Text('Invalid post ID')));
      }

      return PostDetailPage(postId: postId);
    },
  ),
];
