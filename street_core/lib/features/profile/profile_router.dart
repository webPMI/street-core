// profile_routes.dart
//
// Centralized profile routes configuration.
// All profile-related routes are defined here and exported to private_routes.

import 'package:flutter/material.dart';

import 'pages/change_password_page.dart';
import 'pages/followers_page.dart';
import 'pages/following_page.dart';
import 'pages/profile_edit_page.dart';
import 'pages/profile_page.dart';
import 'pages/saved_posts_page.dart';
import 'pages/user_profile_page.dart';
import 'posts/pages/create_post_page.dart';
import 'posts/pages/post_detail_page.dart';
import 'posts/pages/posts_feed_page.dart';
import 'package:go_router/go_router.dart';

import 'profile_routes.dart';

/// Private profile routes (authentication required)
///
/// These routes are only accessible to authenticated users.
/// Include: profile view, profile edit, change password, user profile view,
/// followers/following lists, posts feed, create post, post detail.
///
/// NOTE: All routes use RELATIVE paths (no leading /) because they are
/// nested under /dashboard in the route hierarchy.
/// Example: 'profile' → /dashboard/profile
final List<GoRoute> profileRouter = [
  // =========================================================================
  // PROFILE ROUTES - /dashboard/profile/*
  // =========================================================================
  GoRoute(
    path: 'profile', // Relative → /dashboard/profile
    builder: (context, state) => const ProfilePage(),
    routes: [
      // /dashboard/profile/edit
      GoRoute(
        path: 'edit',
        builder: (context, state) => const ProfileEditPage(),
      ),
      // /dashboard/profile/change-password
      GoRoute(
        path: 'change-password',
        builder: (context, state) => const ChangePasswordPage(),
      ),
      // /dashboard/profile/saved
      GoRoute(
        path: 'saved',
        builder: (context, state) => const SavedPostsPage(),
      ),
      // /dashboard/profile/user/:userId
      GoRoute(
        path: 'user/:userId',
        redirect: (context, state) {
          final userId = state.pathParameters['userId'];
          if (userId == null || userId.isEmpty) {
            // Redirect to own profile if userId is missing
            return ProfileRoutes.profile;
          }
          return null; // No redirect, continue to page
        },
        builder: (context, state) {
          final userId = state.pathParameters['userId'] ?? '';
          return UserProfilePage(userId: userId);
        },
        routes: [
          // /dashboard/profile/user/:userId/followers
          GoRoute(
            path: 'followers',
            builder: (context, state) {
              final userId = state.pathParameters['userId'] ?? '';
              return FollowersPage(userId: userId, username: '');
            },
          ),
          // /dashboard/profile/user/:userId/following
          GoRoute(
            path: 'following',
            builder: (context, state) {
              final userId = state.pathParameters['userId'] ?? '';
              return FollowingPage(userId: userId, username: '');
            },
          ),
        ],
      ),
    ],
  ),

  // =========================================================================
  // POSTS ROUTES - /dashboard/posts/*
  // =========================================================================
  GoRoute(
    path: 'posts', // Relative → /dashboard/posts
    builder: (context, state) => const PostsFeedPage(),
    routes: [
      // /dashboard/posts/create (must come before :id)
      GoRoute(
        path: 'create',
        builder: (context, state) => const CreatePostPage(),
      ),
      // /dashboard/posts/:id
      GoRoute(
        path: ':id',
        builder: (context, state) {
          final postId = state.pathParameters['id'];
          if (postId == null || postId.isEmpty) {
            return const Scaffold(body: Center(child: Text('Invalid post ID')));
          }
          return PostDetailPage(postId: postId);
        },
      ),
    ],
  ),
];
