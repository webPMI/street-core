// lib/core/media/bloc/media_upload_state.dart

import 'package:equatable/equatable.dart';
import '../models/media_response.dart';

/// Base state for media upload operations
abstract class MediaUploadState extends Equatable {
  const MediaUploadState();

  @override
  List<Object?> get props => [];
}

/// Initial state - no upload in progress
class MediaUploadInitial extends MediaUploadState {
  const MediaUploadInitial();
}

/// Upload in progress with progress tracking
class MediaUploadLoading extends MediaUploadState {
  const MediaUploadLoading({
    this.progress = 0.0,
    this.fileName,
  });

  /// Upload progress (0.0 to 1.0)
  final double progress;

  /// Name of the file being uploaded
  final String? fileName;

  @override
  List<Object?> get props => [progress, fileName];
}

/// Upload completed successfully
class MediaUploadSuccess extends MediaUploadState {
  const MediaUploadSuccess(this.response);

  final MediaUploadResponse response;

  @override
  List<Object?> get props => [response];
}

/// Multiple files uploaded successfully
class MediaUploadMultipleSuccess extends MediaUploadState {
  const MediaUploadMultipleSuccess(this.responses);

  final List<MediaUploadResponse> responses;

  @override
  List<Object?> get props => [responses];
}

/// Upload failed with error
class MediaUploadError extends MediaUploadState {
  const MediaUploadError({
    required this.errorCode,
    required this.errorMessage,
  });

  /// Error code for translation
  final String errorCode;

  /// Error message (fallback)
  final String errorMessage;

  @override
  List<Object?> get props => [errorCode, errorMessage];
}

/// Upload cancelled by user
class MediaUploadCancelled extends MediaUploadState {
  const MediaUploadCancelled();
}
