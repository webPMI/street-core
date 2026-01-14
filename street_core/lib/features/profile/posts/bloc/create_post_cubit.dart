// lib/presentation/dashboard/posts/bloc/create_post_cubit.dart

import 'package:image_picker/image_picker.dart';

import '../../services/post_service.dart';
import 'create_post_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CreatePostCubit extends Cubit<CreatePostState> {
  CreatePostCubit(this._postService) : super(CreatePostInitial());
  final PostService _postService;

  // --------------------------------------------------
  // OPERACIONES DE EDICIÓN DE FORMULARIO
  // --------------------------------------------------

  /// Iniciar edición (cambiar a estado de edición)
  void startEditing() {
    emit(const CreatePostEditing());
  }

  /// Actualizar el caption
  void updateCaption(String caption) {
    final currentState = state;
    if (currentState is CreatePostEditing) {
      // Extraer hashtags y menciones
      final hashtags = _extractHashtags(caption);
      final mentions = _extractMentions(caption);

      emit(
        currentState.copyWith(
          caption: caption,
          hashtags: hashtags,
          mentions: mentions,
        ),
      );
    }
  }

  /// Agregar archivos multimedia (XFile for web compatibility)
  void addMediaFiles(List<XFile> files) {
    final currentState = state;
    if (currentState is CreatePostEditing) {
      final updatedFiles = [...currentState.mediaFiles, ...files];
      emit(currentState.copyWith(mediaFiles: updatedFiles));
    }
  }

  /// Remover un archivo multimedia
  void removeMediaFile(int index) {
    final currentState = state;
    if (currentState is CreatePostEditing) {
      final updatedFiles = List<XFile>.from(currentState.mediaFiles);
      updatedFiles.removeAt(index);
      emit(currentState.copyWith(mediaFiles: updatedFiles));
    }
  }

  /// Actualizar ubicación
  void updateLocation(String? location) {
    final currentState = state;
    if (currentState is CreatePostEditing) {
      emit(currentState.copyWith(location: location));
    }
  }

  /// Actualizar visibilidad
  void updateVisibility(String visibility) {
    final currentState = state;
    if (currentState is CreatePostEditing) {
      emit(currentState.copyWith(visibility: visibility));
    }
  }

  // --------------------------------------------------
  // OPERACIONES DE CREACIÓN
  // --------------------------------------------------

  /// Crear el post
  Future<void> createPost() async {
    final currentState = state;
    if (currentState is! CreatePostEditing) return;

    try {
      // 1. Validar que haya al menos un archivo multimedia (requerido por backend)
      if (currentState.mediaFiles.isEmpty) {
        emit(const CreatePostError('post.requires.media'));
        emit(currentState);
        return;
      }

      // 2. Crear el post (service handles media upload internally)
      emit(const CreatePostUploading(progress: 0.1, message: 'uploading_media'));

      await _postService.createPost(
        content: currentState.caption.trim(),
        images: currentState.mediaFiles,
        tags: currentState.hashtags,
        mentions: currentState.mentions,
        visibility: currentState.visibility,
      );

      emit(const CreatePostSuccess('post.created.successfully'));
    } catch (e) {
      emit(CreatePostError(e.toString().replaceAll('Exception: ', '')));
      emit(currentState);
    }
  }

  /// Resetear el formulario
  void reset() {
    emit(CreatePostInitial());
  }

  // --------------------------------------------------
  // MÉTODOS AUXILIARES
  // --------------------------------------------------

  /// Extraer hashtags del texto
  List<String> _extractHashtags(String text) {
    final regex = RegExp(r'#(\w+)');
    final matches = regex.allMatches(text);
    return matches.map((match) => match.group(1)!).toList();
  }

  /// Extraer menciones del texto
  List<String> _extractMentions(String text) {
    final regex = RegExp(r'@(\w+)');
    final matches = regex.allMatches(text);
    return matches.map((match) => match.group(1)!).toList();
  }
}
