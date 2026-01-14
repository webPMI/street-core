// lib/presentation/dashboard/posts/bloc/create_post_state.dart

import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';

/// Clase base para todos los estados de creación de post
abstract class CreatePostState extends Equatable {
  const CreatePostState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class CreatePostInitial extends CreatePostState {}

/// Estado durante la edición del formulario
/// Uses XFile instead of File for web compatibility
class CreatePostEditing extends CreatePostState {

  const CreatePostEditing({
    this.caption = '',
    this.mediaFiles = const [],
    this.location,
    this.visibility = 'public',
    this.hashtags = const [],
    this.mentions = const [],
  });
  final String caption;
  final List<XFile> mediaFiles; // XFile works on all platforms (web, mobile, desktop)
  final String? location;
  final String visibility;
  final List<String> hashtags;
  final List<String> mentions;

  CreatePostEditing copyWith({
    String? caption,
    List<XFile>? mediaFiles,
    String? location,
    String? visibility,
    List<String>? hashtags,
    List<String>? mentions,
  }) {
    return CreatePostEditing(
      caption: caption ?? this.caption,
      mediaFiles: mediaFiles ?? this.mediaFiles,
      location: location ?? this.location,
      visibility: visibility ?? this.visibility,
      hashtags: hashtags ?? this.hashtags,
      mentions: mentions ?? this.mentions,
    );
  }

  @override
  List<Object?> get props => [
        caption,
        mediaFiles,
        location,
        visibility,
        hashtags,
        mentions,
      ];
}

/// Estado de subida de archivos
class CreatePostUploading extends CreatePostState {

  const CreatePostUploading({
    this.progress = 0.0,
    this.message = 'uploading_media',
  });
  final double progress;
  final String message;

  @override
  List<Object> get props => [progress, message];
}

/// Estado de creación del post
class CreatePostSubmitting extends CreatePostState {}

/// Estado de éxito
class CreatePostSuccess extends CreatePostState {

  const CreatePostSuccess(this.message);
  final String message;

  @override
  List<Object> get props => [message];
}

/// Estado de error
class CreatePostError extends CreatePostState {

  const CreatePostError(this.message);
  final String message;

  @override
  List<Object> get props => [message];
}
