// lib/data/models/post_model.dart
import '../../../core/services/api_address.dart';

class PostModel {
  PostModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.caption,
    this.mediaType = 'image',
    this.mediaUrls = const [],
    this.thumbnailUrl,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.sharesCount = 0,
    this.viewsCount = 0,
    this.savesCount = 0,
    this.location,
    this.tags = const [],
    this.mentions = const [],
    this.visibility = 'public',
    this.isActive = true,
    this.isArchived = false,
    this.isLikedByCurrentUser = false,
    this.isSavedByCurrentUser = false,
    required this.createdAt,
    required this.updatedAt,
  });

  // 1. Deserialización: Crear modelo desde JSON
  factory PostModel.fromJson(Map<String, dynamic> json) {
    // Helper para convertir listas dinámicas a List<String>
    List<String> parseStringList(dynamic value) {
      if (value == null) return [];
      if (value is List) {
        return value.map((e) => e.toString()).toList();
      }
      return [];
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

    // Helper para convertir cadena vacía a null
    String? stringOrNull(dynamic value) {
      if (value == null) return null;
      final str = value.toString().trim();
      return str.isEmpty ? null : str;
    }

    final now = DateTime.now();

    return PostModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String? ?? 'Unknown User',
      userAvatar: mediaUrlOrNull(json['userAvatar']),
      caption: json['caption'] as String? ?? '',
      mediaType: json['mediaType'] as String? ?? 'image',
      mediaUrls: parseMediaUrls(json['mediaUrls']),
      thumbnailUrl: mediaUrlOrNull(json['thumbnailUrl']),
      likesCount: json['likesCount'] as int? ?? 0,
      commentsCount: json['commentsCount'] as int? ?? 0,
      sharesCount: json['sharesCount'] as int? ?? 0,
      viewsCount: json['viewsCount'] as int? ?? 0,
      savesCount: json['savesCount'] as int? ?? 0,
      location: stringOrNull(json['location']),
      tags: parseStringList(json['tags']),
      mentions: parseStringList(json['mentions']),
      visibility: json['visibility'] as String? ?? 'public',
      isActive: json['isActive'] as bool? ?? true,
      isArchived: json['isArchived'] as bool? ?? false,
      isLikedByCurrentUser: json['isLikedByCurrentUser'] as bool? ?? false,
      isSavedByCurrentUser: json['isSavedByCurrentUser'] as bool? ?? false,
      createdAt: parseDate(json['createdAt'], now),
      updatedAt: parseDate(json['updatedAt'], now),
    );
  }
  // Identificación básica
  final String id;
  final String userId; // Usuario que creó el post
  final String userName; // Nombre del usuario
  final String? userAvatar; // Avatar del usuario

  // Contenido
  final String caption; // Texto del post
  final String mediaType; // 'image', 'video', 'carousel'
  final List<String> mediaUrls; // URLs de las imágenes/videos
  final String? thumbnailUrl; // Thumbnail para videos

  // Estadísticas de interacción
  final int likesCount;
  final int commentsCount;
  final int sharesCount;
  final int viewsCount;
  final int savesCount;

  // Metadatos
  final String? location; // Ubicación del post
  final List<String> tags; // Hashtags
  final List<String> mentions; // Usuarios mencionados (@username)

  // Estado y visibilidad
  final String visibility; // 'public', 'private', 'followers'
  final bool isActive;
  final bool isArchived;

  // User interaction tracking (for current user)
  final bool isLikedByCurrentUser;
  final bool isSavedByCurrentUser;

  // Fechas
  final DateTime createdAt;
  final DateTime updatedAt;

  // 2. Serialización: Convertir modelo a JSON (para enviar a la API)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'caption': caption,
      'mediaType': mediaType,
      'mediaUrls': mediaUrls,
      'thumbnailUrl': thumbnailUrl,
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'sharesCount': sharesCount,
      'viewsCount': viewsCount,
      'savesCount': savesCount,
      'location': location,
      'tags': tags,
      'mentions': mentions,
      'visibility': visibility,
      'isActive': isActive,
      'isArchived': isArchived,
      'isLikedByCurrentUser': isLikedByCurrentUser,
      'isSavedByCurrentUser': isSavedByCurrentUser,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // 3. Método copyWith (ESENCIAL para BLoC/Cubit)
  PostModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userAvatar,
    String? caption,
    String? mediaType,
    List<String>? mediaUrls,
    String? thumbnailUrl,
    int? likesCount,
    int? commentsCount,
    int? sharesCount,
    int? viewsCount,
    int? savesCount,
    String? location,
    List<String>? tags,
    List<String>? mentions,
    String? visibility,
    bool? isActive,
    bool? isArchived,
    bool? isLikedByCurrentUser,
    bool? isSavedByCurrentUser,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PostModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      caption: caption ?? this.caption,
      mediaType: mediaType ?? this.mediaType,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      sharesCount: sharesCount ?? this.sharesCount,
      viewsCount: viewsCount ?? this.viewsCount,
      savesCount: savesCount ?? this.savesCount,
      location: location ?? this.location,
      tags: tags ?? this.tags,
      mentions: mentions ?? this.mentions,
      visibility: visibility ?? this.visibility,
      isActive: isActive ?? this.isActive,
      isArchived: isArchived ?? this.isArchived,
      isLikedByCurrentUser: isLikedByCurrentUser ?? this.isLikedByCurrentUser,
      isSavedByCurrentUser: isSavedByCurrentUser ?? this.isSavedByCurrentUser,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper method para saber si tiene multimedia
  bool get hasMedia => mediaUrls.isNotEmpty;

  // Helper method para saber si es un video
  bool get isVideo => mediaType == 'video';

  // Helper method para saber si es un carousel
  bool get isCarousel => mediaType == 'carousel';

  // Helper method para saber si es una sola imagen
  bool get isSingleImage => mediaType == 'image' && mediaUrls.length == 1;
}

// Typedef for convenience
typedef Post = PostModel;
