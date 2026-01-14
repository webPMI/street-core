// lib/features/social/like/like_model.dart

import '../../../core/services/api_address.dart';

/// Like Model - Represents a like on a post
class LikeModel {
  LikeModel({
    required this.id,
    required this.userId,
    required this.postId,
    required this.userName,
    this.userAvatar,
    required this.createdAt,
  });

  /// Create Like from JSON response
  factory LikeModel.fromJson(Map<String, dynamic> json) {
    // Helper for parsing dates
    DateTime parseDate(dynamic value, DateTime defaultValue) {
      if (value == null) return defaultValue;
      if (value is DateTime) return value;
      if (value is String) {
        return DateTime.tryParse(value) ?? defaultValue;
      }
      return defaultValue;
    }

    final now = DateTime.now();

    return LikeModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      postId: json['postId'] as String? ?? '',
      userName: json['userName'] as String? ?? 'Unknown User',
      userAvatar: mediaUrlOrNull(json['userAvatar']),
      createdAt: parseDate(json['createdAt'], now),
    );
  }

  // Identificación
  final String id;
  final String userId; // Usuario que dio like
  final String postId; // Post al que se le dio like
  final String userName; // Nombre del usuario
  final String? userAvatar; // Avatar del usuario

  // Metadata
  final DateTime createdAt;

  /// Convert to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'postId': postId,
      'userName': userName,
      'userAvatar': userAvatar,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// CopyWith method for state management
  LikeModel copyWith({
    String? id,
    String? userId,
    String? postId,
    String? userName,
    String? userAvatar,
    DateTime? createdAt,
  }) {
    return LikeModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      postId: postId ?? this.postId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// Typedef for convenience
typedef Like = LikeModel;
