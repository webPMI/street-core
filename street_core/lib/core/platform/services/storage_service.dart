/// Abstract Storage Service Interface
///
/// Define the contract for platform-specific storage implementations.
/// Each platform (web, mobile, desktop) will have its own implementation.
abstract class StorageService {
  /// Save a string value
  Future<bool> saveString(String key, String value);

  /// Get a string value
  Future<String?> getString(String key);

  /// Save a boolean value
  Future<bool> saveBool(String key, bool value);

  /// Get a boolean value
  Future<bool?> getBool(String key);

  /// Save an integer value
  Future<bool> saveInt(String key, int value);

  /// Get an integer value
  Future<int?> getInt(String key);

  /// Remove a value
  Future<bool> remove(String key);

  /// Clear all values
  Future<bool> clearAll();

  /// Check if key exists
  Future<bool> containsKey(String key);

  /// Get all keys
  Future<Set<String>> getAllKeys();
}

/// Secure Storage Service Interface (for sensitive data)
///
/// Use this for storing tokens, passwords, etc.
/// Only available on mobile platforms.
abstract class SecureStorageService {
  /// Save secure string
  Future<void> saveSecure(String key, String value);

  /// Get secure string
  Future<String?> getSecure(String key);

  /// Delete secure value
  Future<void> deleteSecure(String key);

  /// Delete all secure values
  Future<void> deleteAllSecure();

  /// Check if available
  bool get isAvailable;
}
