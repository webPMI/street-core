import 'dart:io' show File;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:street_core/core/helpers/logger.dart';
import 'package:street_core/core/storage/hive_service.dart';

/// Device Storage Service
///
/// Provides unified access to device storage capabilities:
/// - Hive for non-sensitive data (replaces SharedPreferences - faster & type-safe)
/// - FlutterSecureStorage for sensitive data (tokens, credentials)
/// - File system for documents and media
class StorageService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final HiveService _hive;

  StorageService(this._hive);

  // --- 1. DATOS NO SENSIBLES (Hive - Replaces SharedPreferences) ---

  /// Guarda un valor, soporta Maps/Objects/primitivos directamente.
  /// Hive maneja tipos nativamente, no necesita JSON encoding.
  Future<void> saveJson<T>(String key, T value) async {
    await _hive.savePref(key, value);
  }

  /// Obtiene un valor con tipado fuerte.
  /// Hive retorna el tipo correcto automáticamente.
  Future<T?> readJson<T>(String key) async {
    return _hive.readPref<T>(key);
  }

  /// Guarda un valor String.
  Future<void> save(String key, String value) async {
    await _hive.savePref(key, value);
  }

  /// Obtiene un valor String.
  Future<String?> read(String key) async {
    return _hive.readPref<String>(key);
  }

  /// Elimina una clave.
  Future<void> delete(String key) async {
    await _hive.deletePref(key);
  }

  // --- 2. DATOS SENSIBLES (FlutterSecureStorage) ---

  /// Guarda un valor de forma encriptada (para tokens, credenciales).
  Future<void> saveSecure(String key, String value) async {
    try {
      await _secureStorage.write(key: key, value: value);
    } catch (e) {
      // Manejar errores si es necesario
      AppLogger.error(
        'Failed to save secure key: $key',
        error: e,
        tag: 'StorageService',
      );
    }
  }

  /// Obtiene un valor encriptado.
  Future<String?> readSecure(String key) async {
    try {
      return await _secureStorage.read(key: key);
    } catch (e) {
      // Manejar errores si es necesario
      AppLogger.error(
        'Failed to read secure key: $key',
        error: e,
        tag: 'StorageService',
      );
      return null;
    }
  }

  /// Elimina una clave encriptada.
  Future<void> deleteSecure(String key) async {
    try {
      await _secureStorage.delete(key: key);
    } catch (e) {
      // Manejar errores si es necesario
      AppLogger.error(
        'Failed to delete secure key: $key',
        error: e,
        tag: 'StorageService',
      );
    }
  }

  // --- 3. GESTIÓN DE ARCHIVOS LOCALES (path_provider) ---

  /// Guarda un archivo (ej: imagen) en el directorio de documentos.
  /// Retorna la ruta completa al archivo guardado.
  Future<String> saveFile({
    required File file,
    required String fileName,
  }) async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/$fileName';
    final savedFile = await file.copy(path);
    return savedFile.path;
  }

  /// Lee un archivo basado en su nombre (ej: 'profile.jpg').
  Future<File?> fetchFile(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$fileName';
    final file = File(filePath);
    return file.existsSync() ? file : null;
  }

  /// Lista las rutas completas de todos los archivos en el directorio de documentos.
  Future<List<String>> listLocalFiles() async {
    final directory = await getApplicationDocumentsDirectory();
    final files = directory.listSync().whereType<File>();
    return files.map((file) => file.path).toList();
  }

  /// Elimina un archivo local.
  Future<void> deleteLocalFile(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$fileName';
    final file = File(filePath);
    // Use synchronous existsSync() to avoid slow async IO warning
    if (file.existsSync()) {
      await file.delete();
    }
  }

  // --- 4. LIMPIEZA GLOBAL ---

  /// Limpia todos los datos almacenados (Hive y SecureStorage).
  Future<void> clearAllData() async {
    await _hive.clearAll();
    await _secureStorage.deleteAll();
    // NOTA: No elimina archivos locales, ya que eso podría ser destructivo.
  }
}
