// lib/features/social/comment/comment_model.dart

import 'package:equatable/equatable.dart';
import '../../../core/services/api_address.dart';

/// Entity type constants for commentable entities
class EntityType {
  static const String post = 'post';
  static const String competition = 'competition';
  static const String event = 'event';
  static const String club = 'club';
  static const String product = 'product';
}

class CommentModel extends Equatable {

  const CommentModel({
    required this.id,
    this.entityId,
    this.entityType,
    this.postId, // DEPRECATED: kept for backward compatibility
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.text,
    this.parentCommentId,
    this.repliesCount = 0,
    this.likesCount = 0,
    this.isLikedByCurrentUser = false,
    this.isEdited = false,
    required this.createdAt,
    required this.updatedAt,
  });

  // 1. Deserialización: Crear modelo desde JSON
  factory CommentModel.fromJson(Map<String, dynamic> json) {
    // Helper para convertir cadena vacía a null
    String? stringOrNull(dynamic value) {
      if (value == null) return null;
      final str = value.toString().trim();
      return str.isEmpty ? null : str;
    }

    // Manejo de fechas
    DateTime parseDate(dynamic value, DateTime defaultValue) {
      if (value == null) return defaultValue;
      if (value is DateTime) return value;
      if (value is String) {
        return DateTime.tryParse(value) ?? defaultValue;
      }
      return defaultValue;
    }

    final now = DateTime.now();

    return CommentModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      entityId: stringOrNull(json['entityId']),
      entityType: stringOrNull(json['entityType']),
      postId: stringOrNull(json['postId']), // Legacy support
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String? ?? 'Unknown User',
      userAvatar: mediaUrlOrNull(json['userAvatar']),
      text: json['text'] as String? ?? json['content'] as String? ?? '',
      parentCommentId: stringOrNull(json['parentCommentId']),
      repliesCount: json['repliesCount'] as int? ?? 0,
      likesCount: json['likesCount'] as int? ?? 0,
      isLikedByCurrentUser: json['isLikedByCurrentUser'] as bool? ?? false,
      isEdited: json['isEdited'] as bool? ?? false,
      createdAt: parseDate(json['createdAt'], now),
      updatedAt: parseDate(json['updatedAt'], now),
    );
  }

  // Identificación básica
  final String id;

  // Generic entity reference (NEW - supports any commentable entity)
  final String? entityId;
  final String? entityType; // 'post', 'competition', 'event', etc.

  // Legacy post reference (DEPRECATED - kept for backward compatibility)
  final String? postId;

  final String userId; // ID del usuario que comentó
  final String userName; // Nombre del usuario
  final String? userAvatar; // Avatar del usuario

  // Contenido
  final String text; // Texto del comentario

  // Anidación (para respuestas a comentarios)
  final String? parentCommentId; // null si es comentario principal
  final int repliesCount; // Cantidad de respuestas

  // Estadísticas
  final int likesCount;
  final bool isLikedByCurrentUser; // Si el usuario actual le dio like

  // Metadatos
  final bool isEdited; // Si fue editado

  // Fechas
  final DateTime createdAt;
  final DateTime updatedAt;

  // 2. Serialización: Convertir modelo a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (entityId != null) 'entityId': entityId,
      if (entityType != null) 'entityType': entityType,
      if (postId != null) 'postId': postId,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'text': text,
      'parentCommentId': parentCommentId,
      'repliesCount': repliesCount,
      'likesCount': likesCount,
      'isLikedByCurrentUser': isLikedByCurrentUser,
      'isEdited': isEdited,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // 3. Método copyWith (ESENCIAL para BLoC/Cubit)
  CommentModel copyWith({
    String? id,
    String? entityId,
    String? entityType,
    String? postId,
    String? userId,
    String? userName,
    String? userAvatar,
    String? text,
    String? parentCommentId,
    int? repliesCount,
    int? likesCount,
    bool? isLikedByCurrentUser,
    bool? isEdited,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CommentModel(
      id: id ?? this.id,
      entityId: entityId ?? this.entityId,
      entityType: entityType ?? this.entityType,
      postId: postId ?? this.postId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      text: text ?? this.text,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      repliesCount: repliesCount ?? this.repliesCount,
      likesCount: likesCount ?? this.likesCount,
      isLikedByCurrentUser: isLikedByCurrentUser ?? this.isLikedByCurrentUser,
      isEdited: isEdited ?? this.isEdited,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper methods
  bool get isReply => parentCommentId != null;
  bool get hasReplies => repliesCount > 0;

  /// Get the entity ID (prioritizes entityId over postId for backward compatibility)
  String get getEntityId => entityId ?? postId ?? '';

  /// Get the entity type (defaults to 'post' if not set)
  String get getEntityType => entityType ?? (postId != null ? EntityType.post : '');

  @override
  List<Object?> get props => [
        id,
        entityId,
        entityType,
        postId,
        userId,
        userName,
        userAvatar,
        text,
        parentCommentId,
        repliesCount,
        likesCount,
        isLikedByCurrentUser,
        isEdited,
        createdAt,
        updatedAt,
      ];
}

// Typedef for convenience
typedef Comment = CommentModel;
