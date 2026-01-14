// api_media_service.dart

import 'dart:convert';
import 'dart:io' show File;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

import '../helpers/device_storage.dart';
import '../helpers/logger.dart';
import '../lang/locale_keys.dart';
import '../lang/locale_service.dart';
import '../di/injection.dart';
import 'api_address.dart';
import 'api_response.dart';
import 'csrf_service.dart';

/// Media upload/download service
class ApiMediaService {
  ApiMediaService({
    LocaleService? localeService,
    StorageService? storageService,
  }) : _localeServiceParam = localeService,
       _storageServiceParam = storageService;

  final LocaleService? _localeServiceParam;
  final StorageService? _storageServiceParam;
  final CsrfService _csrfService = CsrfService();

  final Duration _uploadTimeout = const Duration(minutes: 5);
  final Duration _multiUploadTimeout = const Duration(minutes: 10);
  final Duration _downloadTimeout = const Duration(seconds: 30);

  // Get services from DI when not injected
  LocaleService get _localeService => _localeServiceParam ?? getIt<LocaleService>();
  StorageService get _storageService => _storageServiceParam ?? getIt<StorageService>();

  String get _lang => _localeService.currentLocale;

  Future<String?> _getToken() async {
    return _storageService.readSecure('auth_token');
  }

  Future<String> get baseUrl async => getApiAddress();

  Future<Map<String, String>> _buildHeaders() async {
    final Map<String, String> headers = {'Accept-Language': _lang};

    final token = await _getToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    } else {
      AppLogger.warning('No auth token for media upload', tag: 'MEDIA');
    }

    final csrfToken = await _csrfService.getToken();
    if (csrfToken != null) {
      headers['X-CSRF-Token'] = csrfToken;
    }

    return headers;
  }

  /// Upload a single file
  Future<ApiResponse<Map<String, dynamic>>> uploadFile({
    required File file,
    required String endpoint,
    String fieldName = 'file',
    Map<String, String>? additionalFields,
    Function(double progress)? onProgress,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      final urlBase = await getApiAddress();
      final String finalUri = '$urlBase$endpoint';
      final fileSize = await file.length();

      AppLogger.apiRequest('POST', finalUri, data: {'file': file.path, 'size': '${(fileSize / 1024).toStringAsFixed(1)}KB'});

      final request = http.MultipartRequest('POST', Uri.parse(finalUri));
      request.headers.addAll(await _buildHeaders());

      final mimeType = _getMimeType(file.path);
      final multipartFile = await http.MultipartFile.fromPath(
        fieldName,
        file.path,
        contentType: MediaType.parse(mimeType),
      );
      request.files.add(multipartFile);

      if (additionalFields != null) {
        request.fields.addAll(additionalFields);
      }

      final streamedResponse = await request.send().timeout(
        _uploadTimeout,
        onTimeout: () {
          AppLogger.error('Upload timeout after ${_uploadTimeout.inMinutes}min', tag: 'MEDIA');
          throw Exception(LocaleKeys.mediaErrorUploadTimeout);
        },
      );

      final response = await http.Response.fromStream(streamedResponse);
      stopwatch.stop();
      AppLogger.apiResponse(
        response.statusCode,
        finalUri,
        ms: stopwatch.elapsedMilliseconds,
        data: response.statusCode >= 400 ? response.body : null,
      );

      return _handleResponse<Map<String, dynamic>>(response);
    } on Exception catch (error, stackTrace) {
      stopwatch.stop();
      AppLogger.error('File upload failed: $endpoint', error: error, stackTrace: stackTrace, tag: 'MEDIA');
      return const ApiResponse<Map<String, dynamic>>(
        status: 'error',
        message: LocaleKeys.mediaErrorUploadFailed,
        statusCode: 500,
      );
    }
  }

  /// Upload file from bytes (web)
  Future<ApiResponse<Map<String, dynamic>>> uploadBytes({
    required Uint8List bytes,
    required String filename,
    required String endpoint,
    String fieldName = 'file',
    Map<String, String>? additionalFields,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      final urlBase = await getApiAddress();
      final String finalUri = '$urlBase$endpoint';

      AppLogger.apiRequest('POST', finalUri, data: {'filename': filename, 'size': '${(bytes.length / 1024).toStringAsFixed(1)}KB'});

      final request = http.MultipartRequest('POST', Uri.parse(finalUri));
      request.headers.addAll(await _buildHeaders());

      final mimeType = _getMimeType(filename);
      final multipartFile = http.MultipartFile.fromBytes(
        fieldName,
        bytes,
        filename: filename,
        contentType: MediaType.parse(mimeType),
      );
      request.files.add(multipartFile);

      if (additionalFields != null) {
        request.fields.addAll(additionalFields);
      }

      final streamedResponse = await request.send().timeout(
        _uploadTimeout,
        onTimeout: () {
          AppLogger.error('Upload timeout', tag: 'MEDIA');
          throw Exception(LocaleKeys.mediaErrorUploadTimeout);
        },
      );

      final response = await http.Response.fromStream(streamedResponse);
      stopwatch.stop();
      AppLogger.apiResponse(
        response.statusCode,
        finalUri,
        ms: stopwatch.elapsedMilliseconds,
        data: response.statusCode >= 400 ? response.body : null,
      );

      return _handleResponse(response);
    } on Exception catch (error, stackTrace) {
      stopwatch.stop();
      AppLogger.error('Bytes upload failed: $endpoint', error: error, stackTrace: stackTrace, tag: 'MEDIA');
      return const ApiResponse<Map<String, dynamic>>(
        status: 'error',
        message: LocaleKeys.mediaErrorUploadFailed,
        statusCode: 500,
      );
    }
  }

  /// Upload multiple files
  Future<ApiResponse<Map<String, dynamic>>> uploadMultipleFiles({
    required List<File> files,
    required String endpoint,
    String fieldName = 'files',
    Map<String, String>? additionalFields,
    Function(double progress)? onProgress,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      if (files.isEmpty) {
        AppLogger.warning('No files to upload', tag: 'MEDIA');
        return const ApiResponse<Map<String, dynamic>>(
          status: 'error',
          message: LocaleKeys.mediaErrorNoFilesSelected,
          statusCode: 400,
        );
      }

      final urlBase = await getApiAddress();
      final String finalUri = '$urlBase$endpoint';

      AppLogger.apiRequest('POST', '$finalUri (${files.length} files)');

      final request = http.MultipartRequest('POST', Uri.parse(finalUri));
      request.headers.addAll(await _buildHeaders());

      for (final file in files) {
        final multipartFile = await http.MultipartFile.fromPath(
          fieldName,
          file.path,
          contentType: MediaType.parse(_getMimeType(file.path)),
        );
        request.files.add(multipartFile);
      }

      if (additionalFields != null) {
        request.fields.addAll(additionalFields);
      }

      final streamedResponse = await request.send().timeout(
        _multiUploadTimeout,
        onTimeout: () {
          AppLogger.error('Multi-upload timeout', tag: 'MEDIA');
          throw Exception(LocaleKeys.mediaErrorUploadTimeout);
        },
      );

      final response = await http.Response.fromStream(streamedResponse);
      stopwatch.stop();
      AppLogger.apiResponse(
        response.statusCode,
        finalUri,
        ms: stopwatch.elapsedMilliseconds,
        data: response.statusCode >= 400 ? response.body : null,
      );

      return _handleResponse(response);
    } on Exception catch (error, stackTrace) {
      stopwatch.stop();
      AppLogger.error('Multi-file upload failed: $endpoint', error: error, stackTrace: stackTrace, tag: 'MEDIA');
      return const ApiResponse<Map<String, dynamic>>(
        status: 'error',
        message: LocaleKeys.mediaErrorUploadFailed,
        statusCode: 500,
      );
    }
  }

  /// Upload multiple XFiles (cross-platform)
  Future<ApiResponse<Map<String, dynamic>>> uploadMultipleXFiles({
    required List<XFile> files,
    required String endpoint,
    String fieldName = 'files',
    Map<String, String>? additionalFields,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      if (files.isEmpty) {
        AppLogger.warning('No files to upload', tag: 'MEDIA');
        return const ApiResponse<Map<String, dynamic>>(
          status: 'error',
          message: LocaleKeys.mediaErrorNoFilesSelected,
          statusCode: 400,
        );
      }

      final urlBase = await getApiAddress();
      final String finalUri = '$urlBase$endpoint';

      AppLogger.apiRequest('POST', '$finalUri (${files.length} files)');

      final request = http.MultipartRequest('POST', Uri.parse(finalUri));
      request.headers.addAll(await _buildHeaders());

      for (final xfile in files) {
        final bytes = await xfile.readAsBytes();
        final multipartFile = http.MultipartFile.fromBytes(
          fieldName,
          bytes,
          filename: xfile.name,
          contentType: MediaType.parse(_getMimeType(xfile.name)),
        );
        request.files.add(multipartFile);
      }

      if (additionalFields != null) {
        request.fields.addAll(additionalFields);
      }

      final streamedResponse = await request.send().timeout(
        _multiUploadTimeout,
        onTimeout: () {
          AppLogger.error('Multi-upload timeout', tag: 'MEDIA');
          throw Exception(LocaleKeys.mediaErrorUploadTimeout);
        },
      );

      final response = await http.Response.fromStream(streamedResponse);
      stopwatch.stop();
      AppLogger.apiResponse(
        response.statusCode,
        finalUri,
        ms: stopwatch.elapsedMilliseconds,
        data: response.statusCode >= 400 ? response.body : null,
      );

      return _handleResponse(response);
    } on Exception catch (error, stackTrace) {
      stopwatch.stop();
      AppLogger.error('Multi-XFile upload failed: $endpoint', error: error, stackTrace: stackTrace, tag: 'MEDIA');
      return const ApiResponse<Map<String, dynamic>>(
        status: 'error',
        message: LocaleKeys.mediaErrorUploadFailed,
        statusCode: 500,
      );
    }
  }

  /// Download file as bytes
  Future<ApiResponse<Uint8List>> downloadFile(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    bool requiredToken = true,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      final urlBase = await getApiAddress();
      String uri = endpoint;

      if (queryParameters != null && queryParameters.isNotEmpty) {
        final queryString = queryParameters.entries
            .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}')
            .join('&');
        uri = '$endpoint?$queryString';
      }

      final String finalUri = '$urlBase$uri';
      final Map<String, String> headers = {'Accept-Language': _lang};

      if (requiredToken) {
        final token = await _getToken();
        if (token != null) {
          headers['Authorization'] = 'Bearer $token';
        }
      }

      AppLogger.apiRequest('GET', finalUri);

      final response = await http.get(Uri.parse(finalUri), headers: headers).timeout(
        _downloadTimeout,
        onTimeout: () {
          AppLogger.error('Download timeout', tag: 'MEDIA');
          throw Exception(LocaleKeys.errorTimeoutDownload);
        },
      );

      stopwatch.stop();
      AppLogger.apiResponse(
        response.statusCode,
        finalUri,
        ms: stopwatch.elapsedMilliseconds,
        data: response.statusCode >= 400 ? response.body : null,
      );

      if (response.statusCode >= 400) {
        String errorMessage = LocaleKeys.errorDownloadFailed;
        try {
          if (response.body.isNotEmpty) {
            final json = jsonDecode(response.body) as Map<String, dynamic>;
            errorMessage = (json['message'] as String?) ?? errorMessage;
          }
        } catch (_) {}

        return ApiResponse<Uint8List>(
          status: 'error',
          message: errorMessage,
          statusCode: response.statusCode,
        );
      }

      AppLogger.info('Downloaded ${(response.bodyBytes.length / 1024).toStringAsFixed(1)}KB', tag: 'MEDIA');
      return ApiResponse<Uint8List>(
        status: 'success',
        message: 'File downloaded successfully',
        data: response.bodyBytes,
        statusCode: response.statusCode,
      );
    } on Exception catch (error, stackTrace) {
      stopwatch.stop();
      AppLogger.error('Download failed: $endpoint', error: error, stackTrace: stackTrace, tag: 'MEDIA');
      return const ApiResponse<Uint8List>(
        status: 'error',
        message: LocaleKeys.errorNetwork,
        statusCode: 500,
      );
    }
  }

  ApiResponse<T> _handleResponse<T>(http.Response response) {
    Map<String, dynamic> responseBody;
    try {
      responseBody = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e, stackTrace) {
      AppLogger.error('Invalid JSON in media response', error: e, stackTrace: stackTrace, tag: 'MEDIA');
      return ApiResponse<T>(
        status: 'error',
        message:  LocaleKeys.errorInvalidResponse,
        statusCode: response.statusCode,
      );
    }

    if (response.statusCode >= 400) {
      final apiMessage = responseBody['message'] ?? LocaleKeys.errorUnknown;
      AppLogger.debug('Media API error: $apiMessage', tag: 'MEDIA');
      return ApiResponse<T>(
        status: 'error',
        message: apiMessage,
        statusCode: response.statusCode,
      );
    }

    return ApiResponse<T>.fromJson(responseBody, null);
  }

  String _getMimeType(String path) {
    final ext = path.split('.').last.toLowerCase();
    const mimeTypes = {
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'webp': 'image/webp',
      'bmp': 'image/bmp',
      'svg': 'image/svg+xml',
      'mp4': 'video/mp4',
      'webm': 'video/webm',
      'mov': 'video/quicktime',
      'avi': 'video/x-msvideo',
      'mpeg': 'video/mpeg',
      'mpg': 'video/mpeg',
      'pdf': 'application/pdf',
      'doc': 'application/msword',
      'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    };
    return mimeTypes[ext] ?? 'application/octet-stream';
  }
}
