// lib/core/media/bloc/media_upload_cubit.dart

import 'dart:io' show File;
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../services/media_upload_service.dart';
import '../validators/media_validator.dart';
import 'media_upload_state.dart';
import '../../helpers/logger.dart';

/// Cubit for managing media upload operations
///
/// Provides centralized state management for file uploads with:
/// - Progress tracking
/// - Validation
/// - Error handling
/// - Cancellation support (planned for Dio integration)
class MediaUploadCubit extends Cubit<MediaUploadState> {
  MediaUploadCubit(this._uploadService) : super(const MediaUploadInitial());

  final MediaUploadService _uploadService;

  // Cancel token support (for future Dio integration)
  // CancelToken? _cancelToken;

  /// Upload avatar image
  Future<void> uploadAvatar(File file) async {
    try {
      // Validate before upload
      final validation = MediaValidator.validateAvatar(file);
      if (!validation.isValid) {
        emit(MediaUploadError(
          errorCode: validation.errorCode ?? 'media.error.validation.failed',
          errorMessage: validation.errorMessage ?? 'Invalid file',
        ));
        return;
      }

      emit(const MediaUploadLoading(progress: 0.0));
      AppLogger.info('Uploading avatar: ${file.path}', tag: 'MediaUploadCubit');

      final response = await _uploadService.uploadAvatar(file);

      emit(MediaUploadSuccess(response));
      AppLogger.info('Avatar uploaded successfully', tag: 'MediaUploadCubit');
    } catch (e) {
      emit(MediaUploadError(
        errorCode: 'media.error.upload.failed',
        errorMessage: e.toString(),
      ));
    }
  }

  /// Upload avatar from web (bytes)
  Future<void> uploadAvatarWeb(Uint8List bytes, String filename) async {
    try {
      emit(const MediaUploadLoading(progress: 0.0));
      AppLogger.info('Uploading avatar (web): $filename', tag: 'MediaUploadCubit');

      final response = await _uploadService.uploadAvatarWeb(bytes, filename);

      emit(MediaUploadSuccess(response));
      AppLogger.info('Avatar uploaded successfully (web)', tag: 'MediaUploadCubit');
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to upload avatar (web)',
        error: e,
        stackTrace: stackTrace,
        tag: 'MediaUploadCubit',
      );

      emit(MediaUploadError(
        errorCode: 'media.error.upload_failed',
        errorMessage: e.toString(),
      ));
    }
  }

  /// Upload single image
  Future<void> uploadImage(File file) async {
    try {
      // Validate before upload
      final validation = MediaValidator.validateImage(file);
      if (!validation.isValid) {
        emit(MediaUploadError(
          errorCode: validation.errorCode ?? 'media.error.validation.failed',
          errorMessage: validation.errorMessage ?? 'Invalid file',
        ));
        return;
      }

      emit(const MediaUploadLoading(progress: 0.0));
      AppLogger.info('Uploading image: ${file.path}', tag: 'MediaUploadCubit');

      final response = await _uploadService.uploadImage(file);

      emit(MediaUploadSuccess(response));
      AppLogger.info('Image uploaded successfully', tag: 'MediaUploadCubit');
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to upload image',
        error: e,
        stackTrace: stackTrace,
        tag: 'MediaUploadCubit',
      );

      emit(MediaUploadError(
        errorCode: 'media.error.upload.failed',
        errorMessage: e.toString(),
      ));
    }
  }

  /// Upload single image from web
  Future<void> uploadImageWeb(Uint8List bytes, String filename) async {
    try {
      emit(const MediaUploadLoading(progress: 0.0));
      AppLogger.info('Uploading image (web): $filename', tag: 'MediaUploadCubit');

      final response = await _uploadService.uploadImageWeb(bytes, filename);

      emit(MediaUploadSuccess(response));
      AppLogger.info('Image uploaded successfully (web)', tag: 'MediaUploadCubit');
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to upload image (web)',
        error: e,
        stackTrace: stackTrace,
        tag: 'MediaUploadCubit',
      );

      emit(MediaUploadError(
        errorCode: 'media.error.upload_failed',
        errorMessage: e.toString(),
      ));
    }
  }

  /// Upload multiple images (cross-platform via XFile)
  Future<void> uploadMultiple(List<XFile> files) async {
    try {
      // Validate files
      final validation = await MediaValidator.validateMultipleFiles(files);
      if (!validation.isValid) {
        emit(MediaUploadError(
          errorCode: validation.errorCode ?? 'media.error.validation.failed',
          errorMessage: validation.errorMessage ?? 'Invalid files',
        ));
        return;
      }

      emit(MediaUploadLoading(
        progress: 0.0,
        fileName: '${files.length} files',
      ));
      AppLogger.info('Uploading ${files.length} files', tag: 'MediaUploadCubit');

      final responses = await _uploadService.uploadMultipleXFile(files);

      emit(MediaUploadMultipleSuccess(responses));
      AppLogger.info('${responses.length} files uploaded successfully', tag: 'MediaUploadCubit');
    } catch (e) {
      emit(MediaUploadError(
        errorCode: 'media.error.upload.failed',
        errorMessage: e.toString(),
      ));
    }
  }

  /// Cancel ongoing upload
  /// Note: Full cancellation support requires Dio integration
  void cancelUpload() {
    // Future implementation with Dio:
    // _cancelToken?.cancel('Upload cancelled by user');
    // _cancelToken = null;

    AppLogger.info('Upload cancelled', tag: 'MediaUploadCubit');
    emit(const MediaUploadCancelled());
  }

  /// Reset to initial state
  void reset() {
    emit(const MediaUploadInitial());
  }
}
