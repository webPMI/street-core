import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:street_core/core/helpers/device_storage.dart';
import 'package:street_core/core/helpers/logger.dart';
import 'package:street_core/core/services/api_address.dart';
import 'package:street_core/core/di/injection.dart';

class CsrfService {
  CsrfService._internal();
  static final CsrfService _instance = CsrfService._internal();
  factory CsrfService() => _instance;

  // Storage keys
  static const String _tokenKey = 'csrf_token';
  static const String _expiresKey = 'csrf_expires';

  // API endpoint
  static const String _csrfEndpoint = '/csrf-token';

  // Cached token (memory cache for performance)
  String? _cachedToken;
  DateTime? _cachedExpires;

  // Completer para manejar múltiples solicitudes simultáneas
  Completer<String?>? _fetchCompleter;

  // Get StorageService from DI when needed
  StorageService get storage => getIt<StorageService>();

  /// Obtener CSRF token del backend
  Future<String?> getToken() async {
    // 1: Verificar caché en memoria
    if (_cachedToken != null && _cachedExpires != null) {
      // Add 5 minute buffer before expiration
      final bufferTime = DateTime.now().add(const Duration(minutes: 5));
      if (_cachedExpires!.isAfter(bufferTime)) {
        return _cachedToken;
      }
    } else {
      AppLogger.debug('[CSRF] No hay token en cache memoria');
    }

    // 2: Verificar almacenamiento local
    final token = await storage.readSecure(_tokenKey);
    final expiresStr = await storage.readSecure(_expiresKey);

    AppLogger.debug('[CSRF] Storage expires: ${expiresStr ?? "null"}');

    if (token != null && expiresStr != null) {
      try {
        final expires = DateTime.parse(expiresStr);
        AppLogger.debug('[CSRF] Fecha parseada: $expires');
        if (expires.isAfter(DateTime.now())) {
          // Cache in memory
          _cachedToken = token;
          _cachedExpires = expires;
          return token;
        }
      } catch (e) {
        AppLogger.debug('[CSRF] Error parseando fecha expiracion: $e');
      }
    } else {}

    // 3: Solicitar nuevo token al backend
    AppLogger.debug('[CSRF] Necesario solicitar nuevo token al backend');
    return await _fetchNewToken();
  }

  Future<void> clearToken() async {
    _cachedToken = null;
    _cachedExpires = null;
    await storage.deleteSecure(_tokenKey);
    await storage.deleteSecure(_expiresKey);
    AppLogger.debug('[CSRF] Token CSRF eliminado de cache y storage');
  }

  /// Solicitar nuevo CSRF token al backend y almacenarlo
  /// Usa http directamente para evitar loop con ApiService
  Future<String?> _fetchNewToken() async {
    AppLogger.debug('[CSRF] _fetchNewToken() iniciado');

    // Si ya hay una solicitud en curso, esperar a que termine
    if (_fetchCompleter != null) {
      AppLogger.debug('[CSRF] Solicitud ya en curso, esperando resultado...');
      return _fetchCompleter!.future;
    }

    AppLogger.debug('[CSRF] Creando nueva solicitud al backend');
    _fetchCompleter = Completer<String?>();

    try {
      final baseUrl = await getApiAddress();
      final url = '$baseUrl$_csrfEndpoint';
      AppLogger.debug('[CSRF] GET $url');

      final response = await http
          .get(Uri.parse(url), headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 15));

      AppLogger.debug('[CSRF] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'success') {
          final token = data['csrf_token'] as String;
          final expiresAt = data['expires_at'];

          // Backend returns Unix timestamp (seconds since epoch)
          DateTime expires;
          if (expiresAt is int) {
            expires = DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000);
          } else if (expiresAt is String) {
            expires = DateTime.parse(expiresAt);
          } else {
            // Default: 1 hour from now
            expires = DateTime.now().add(const Duration(hours: 1));
          }

          final expiresStr = expires.toIso8601String();

          await storage.saveSecure(_tokenKey, token);
          await storage.saveSecure(_expiresKey, expiresStr);

          _cachedToken = token;
          _cachedExpires = expires;

          _fetchCompleter!.complete(token);
          AppLogger.debug('[CSRF] Token obtenido OK, expires: $expiresStr');
          return token;
        }
      }
      _fetchCompleter!.complete(null);
      return null;
    } catch (e) {
      AppLogger.debug('[CSRF] ERROR: $e');
      _fetchCompleter!.complete(null);
      return null;
    } finally {
      _fetchCompleter = null;
    }
  }
}
