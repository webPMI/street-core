// lib/features/profile/models/story_model.dart

import '../../../core/services/api_address.dart';

class StoryModel {
  StoryModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.mediaUrl,
    required this.mediaType,
    this.caption,
    this.viewsCount = 0,
    this.viewers = const [],
    required this.createdAt,
    required this.expiresAt,
  });

  // Deserialización: Crear modelo desde JSON
  factory StoryModel.fromJson(Map<String, dynamic> json) {
    // Helper para convertir cadena vacía a null
    String? stringOrNull(dynamic value) {
      if (value == null) return null;
      final str = value.toString().trim();
      return str.isEmpty ? null : str;
    }

    // Helper para listas de strings
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

    final now = DateTime.now();
    final expiresAt = now.add(const Duration(hours: 24));

    return StoryModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String? ?? 'Unknown User',
      userAvatar: mediaUrlOrNull(json['userAvatar']),
      mediaUrl: buildMediaUrl(json['mediaUrl'] as String? ?? ''),
      mediaType: json['mediaType'] as String? ?? 'image',
      caption: stringOrNull(json['caption']),
      viewsCount: json['viewsCount'] as int? ?? 0,
      viewers: parseStringList(json['viewers']),
      createdAt: parseDate(json['createdAt'], now),
      expiresAt: parseDate(json['expiresAt'], expiresAt),
    );
  }

  // Identificación básica
  final String id;
  final String userId; // Usuario que creó la historia
  final String userName; // Nombre del usuario
  final String? userAvatar; // Avatar del usuario

  // Contenido
  final String mediaUrl; // URL de la imagen o video
  final String mediaType; // 'image' o 'video'
  final String? caption; // Texto opcional

  // Estadísticas
  final int viewsCount; // Número de vistas
  final List<String> viewers; // IDs de usuarios que vieron la historia

  // Fechas
  final DateTime createdAt;
  final DateTime expiresAt; // Las historias expiran después de 24 horas

  // Serialización: Convertir modelo a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'mediaUrl': mediaUrl,
      'mediaType': mediaType,
      'caption': caption,
      'viewsCount': viewsCount,
      'viewers': viewers,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
    };
  }

  // Método copyWith
  StoryModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userAvatar,
    String? mediaUrl,
    String? mediaType,
    String? caption,
    int? viewsCount,
    List<String>? viewers,
    DateTime? createdAt,
    DateTime? expiresAt,
  }) {
    return StoryModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaType: mediaType ?? this.mediaType,
      caption: caption ?? this.caption,
      viewsCount: viewsCount ?? this.viewsCount,
      viewers: viewers ?? this.viewers,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  // Métodos ayudantes
  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isVideo => mediaType == 'video';
  bool get isImage => mediaType == 'image';
  bool get hasCaption => caption != null && caption!.isNotEmpty;

  // Verificar si un usuario ha visto esta historia
  bool hasBeenViewedBy(String userId) => viewers.contains(userId);

  // Obtener tiempo restante antes de la expiración
  Duration get timeRemaining {
    if (isExpired) return Duration.zero;
    return expiresAt.difference(DateTime.now());
  }

  // Obtener horas restantes
  int get hoursRemaining => timeRemaining.inHours;
}

// Typedef para conveniencia
typedef Story = StoryModel;
