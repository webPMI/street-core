import 'dart:async';

/// Predefined TTL durations categorized by data sensitivity
///
/// Use these constants to ensure consistent caching behavior across the app.
/// More sensitive data should have shorter TTLs.
class CacheTTL {
  CacheTTL._(); // Private constructor to prevent instantiation

  // ===========================================================================
  // SITE CONFIG TTLs (on-demand loading by section)
  // ===========================================================================
  // Strategy: Stable data = 24h, Marketing = 15min, Critical = 2min

  /// Company info - name, logo, slogan (very stable, changes rarely)
  static const Duration companyInfo = Duration(hours: 24);

  /// Social media links (very stable, links rarely change)
  static const Duration socialMedia = Duration(hours: 24);

  /// Contact info - email, phone, address (stable, may include business hours)
  static const Duration contactInfo = Duration(hours: 24);

  /// Legal texts - privacy policy, terms (very stable, regulatory documents)
  static const Duration legalTexts = Duration(hours: 24);

  /// Landing page texts - marketing content (may update frequently)
  static const Duration landingTexts = Duration(minutes: 15);

  /// SEO config - meta tags, titles (may need quick changes for campaigns)
  static const Duration seoConfig = Duration(minutes: 5);

  /// App config - maintenance mode, versions (critical, must propagate fast)
  static const Duration appConfig = Duration(minutes: 2);

  /// Basic config (company + social combined) - match component TTLs
  static const Duration basicConfig = Duration(hours: 24);

  // ===========================================================================
  // CRUD/REPOSITORY TTLs
  // ===========================================================================

  /// Default TTL for generic data
  static const Duration defaultTTL = Duration(minutes: 5);

  /// Lists fetched from API (e.g., paginated results)
  static const Duration listData = Duration(minutes: 3);

  /// Detail/single item views
  static const Duration detailData = Duration(minutes: 10);

  /// User-specific data
  static const Duration userData = Duration(minutes: 15);

  // ===========================================================================
  // GENERAL TTLs
  // ===========================================================================

  /// Public data that rarely changes (e.g., static content)
  static const Duration publicData = Duration(minutes: 30);

  /// User profile data (e.g., name, avatar, bio)
  static const Duration userProfile = Duration(minutes: 5);

  /// Data that affects permissions or access control
  /// Short TTL to ensure security changes propagate quickly
  static const Duration permissions = Duration(seconds: 30);

  /// Lists that may change frequently (e.g., feeds, notifications)
  static const Duration lists = Duration(minutes: 2);

  /// Search results and temporary data
  static const Duration temporary = Duration(minutes: 1);

  /// NEVER cache sensitive data like tokens, passwords, etc.
  /// This is here as documentation - tokens should use SecureStorage
  static const Duration never = Duration.zero;
}

/// Unified cache service with TTL (Time To Live) support
///
/// Features:
/// - In-memory caching with automatic expiration
/// - Race condition prevention (deduplicates concurrent requests)
/// - Memory limit enforcement (prevents unbounded growth)
/// - Pattern-based and prefix-based invalidation
/// - Hit/miss statistics tracking
/// - LRU eviction when memory limit reached
///
/// Security considerations:
/// - Data is stored in RAM only (cleared on app close)
/// - No encryption (use SecureStorage for sensitive data)
/// - TTL ensures data freshness
/// - Invalidation on logout clears user data
///
/// Usage:
/// ```dart
/// final cache = CacheService.instance;
///
/// // Pattern 1: getOrFetch (recommended for most cases)
/// final data = await cache.getOrFetch(
///   key: 'user_profile',
///   fetchFn: () => api.getProfile(),
///   ttl: CacheTTL.userProfile,
/// );
///
/// // Pattern 2: Manual get/set
/// final cached = cache.get<User>('user_123');
/// if (cached == null) {
///   final user = await api.getUser('123');
///   cache.set('user_123', user, ttl: CacheTTL.userData);
/// }
/// ```
class CacheService {
  /// Factory constructor returns singleton
  factory CacheService() => _instance;

  // Private constructor
  CacheService._internal();
  // Singleton instance
  static final CacheService _instance = CacheService._internal();

  /// Get the singleton instance
  static CacheService get instance => _instance;

  /// Maximum number of cache entries to prevent memory exhaustion
  static const int maxEntries = 100;

  /// Internal cache storage
  final Map<String, CacheEntry<dynamic>> _cache = {};

  /// Track pending requests to prevent race conditions
  /// When multiple calls request the same key simultaneously,
  /// only one API call is made and others wait for the result
  final Map<String, Future<dynamic>> _pendingRequests = {};

  // Hit/miss tracking for statistics
  int _hits = 0;
  int _misses = 0;

  // ===========================================================================
  // CORE METHODS
  // ===========================================================================

  /// Get cached data or fetch from source if expired/missing
  ///
  /// Features:
  /// - Returns cached data if valid and not expired
  /// - Prevents duplicate API calls for concurrent requests (race condition safe)
  /// - Automatically enforces cache size limit
  /// - Tracks hit/miss statistics
  ///
  /// Parameters:
  /// - [key]: Unique identifier for the cached data
  /// - [fetchFn]: Async function to fetch data if not cached
  /// - [ttl]: Time-to-live duration (use [CacheTTL] constants)
  ///
  /// Returns the cached or freshly fetched data
  Future<T> getOrFetch<T>({
    required String key,
    required Future<T> Function() fetchFn,
    required Duration ttl,
  }) async {
    // Check if cached and not expired
    if (_cache.containsKey(key)) {
      final entry = _cache[key];
      if (entry != null && !entry.isExpired) {
        _hits++;
        return entry.data as T;
      }
    }

    // Check if there's already a pending request for this key
    // This prevents race conditions where multiple concurrent calls
    // would all make separate API requests
    if (_pendingRequests.containsKey(key)) {
      try {
        return await _pendingRequests[key] as T;
      } catch (_) {
        // If the pending request failed, we'll try again below
        _pendingRequests.remove(key);
      }
    }

    _misses++;

    // Create the fetch future and track it
    final fetchFuture = _fetchAndCache<T>(key, fetchFn, ttl);
    _pendingRequests[key] = fetchFuture;

    try {
      return await fetchFuture;
    } finally {
      // Always clean up pending request tracker
      _pendingRequests.remove(key);
    }
  }

  /// Internal method to fetch data and store in cache
  Future<T> _fetchAndCache<T>(
    String key,
    Future<T> Function() fetchFn,
    Duration ttl,
  ) async {
    // Fetch fresh data
    final data = await fetchFn();

    // Store in cache
    _cache[key] = CacheEntry<T>(
      data: data,
      timestamp: DateTime.now(),
      ttl: ttl,
    );

    // Enforce size limit after adding new entry
    _enforceLimit();

    return data;
  }

  /// Get cached data without fetching
  ///
  /// Returns null if not cached or expired.
  /// Tracks hit/miss statistics.
  T? get<T>(String key) {
    final entry = _cache[key];

    if (entry == null) {
      _misses++;
      return null;
    }

    if (entry.isExpired) {
      _cache.remove(key);
      _misses++;
      return null;
    }

    _hits++;
    return entry.data as T;
  }

  /// Manually store data in cache
  ///
  /// Use this when you already have data and want to cache it
  /// (e.g., after a POST request that returns the created entity)
  void set<T>(String key, T data, {required Duration ttl}) {
    _cache[key] = CacheEntry<T>(
      data: data,
      timestamp: DateTime.now(),
      ttl: ttl,
    );
    _enforceLimit();
  }

  /// Check if a key exists and is not expired
  bool has(String key) {
    final entry = _cache[key];
    if (entry == null) return false;
    if (entry.isExpired) {
      _cache.remove(key);
      return false;
    }
    return true;
  }

  // ===========================================================================
  // INVALIDATION METHODS
  // ===========================================================================

  /// Invalidate specific cache entry
  void invalidate(String key) {
    _cache.remove(key);
    _pendingRequests.remove(key);
  }

  /// Invalidate all entries matching a substring pattern
  ///
  /// Useful for invalidating related data (e.g., all user-related cache)
  /// Example: invalidatePattern('user_') removes 'user_profile', 'user_settings', etc.
  void invalidatePattern(String pattern) {
    _cache.removeWhere((key, _) => key.contains(pattern));
    _pendingRequests.removeWhere((key, _) => key.contains(pattern));
  }

  /// Invalidate all entries starting with a prefix
  ///
  /// More efficient than pattern matching for prefix-based keys.
  /// Example: invalidatePrefix('list_') removes 'list_users', 'list_products', etc.
  void invalidatePrefix(String prefix) {
    final keysToRemove = _cache.keys
        .where((key) => key.startsWith(prefix))
        .toList();
    for (final key in keysToRemove) {
      _cache.remove(key);
    }
    _pendingRequests.removeWhere((key, _) => key.startsWith(prefix));
  }

  /// Invalidate all entries matching a regex pattern
  ///
  /// Use for complex patterns. Pattern uses '*' as wildcard.
  /// Example: invalidateRegex('item_*_details') removes 'item_123_details', etc.
  void invalidateRegex(String pattern) {
    final regex = RegExp(pattern.replaceAll('*', '.*'));
    final keysToRemove = _cache.keys.where(regex.hasMatch).toList();
    for (final key in keysToRemove) {
      _cache.remove(key);
    }
    _pendingRequests.removeWhere((key, _) => regex.hasMatch(key));
  }

  /// Clear all cache
  ///
  /// Call this on logout to ensure no user data persists
  void clearAll() {
    _cache.clear();
    _pendingRequests.clear();
    _resetStats();
  }

  // ===========================================================================
  // MEMORY MANAGEMENT
  // ===========================================================================

  /// Enforce maximum cache size by removing oldest entries
  ///
  /// Strategy: Remove expired entries first, then oldest entries (LRU)
  /// This prevents memory exhaustion attacks
  void _enforceLimit() {
    // First, remove all expired entries (free cleanup)
    _cache.removeWhere((_, entry) => entry.isExpired);

    // If still over limit, remove oldest entries (LRU eviction)
    if (_cache.length > maxEntries) {
      final entriesToRemove = _cache.length - maxEntries;

      // Sort by timestamp (oldest first) and get keys to remove
      final sortedEntries = _cache.entries.toList()
        ..sort((a, b) => a.value.timestamp.compareTo(b.value.timestamp));

      final keysToRemove = sortedEntries
          .take(entriesToRemove)
          .map((e) => e.key)
          .toList();

      for (final key in keysToRemove) {
        _cache.remove(key);
      }
    }
  }

  /// Clean up expired entries manually
  ///
  /// Called automatically during normal operation,
  /// but can be called manually for immediate cleanup
  void cleanupExpired() {
    _cache.removeWhere((_, entry) => entry.isExpired);
  }

  // ===========================================================================
  // STATISTICS & DEBUGGING
  // ===========================================================================

  /// Reset hit/miss statistics
  void _resetStats() {
    _hits = 0;
    _misses = 0;
  }

  /// Get cache statistics for debugging/monitoring
  CacheStats getStats() {
    final total = _cache.length;
    final expired = _cache.values.where((e) => e.isExpired).length;

    return CacheStats(
      totalEntries: total,
      validEntries: total - expired,
      expiredEntries: expired,
      pendingRequests: _pendingRequests.length,
      hits: _hits,
      misses: _misses,
      maxEntries: maxEntries,
    );
  }

  /// Get all cache keys (for debugging)
  List<String> get keys => _cache.keys.toList();
}

/// Cache statistics
class CacheStats {
  CacheStats({
    required this.totalEntries,
    required this.validEntries,
    required this.expiredEntries,
    required this.pendingRequests,
    required this.hits,
    required this.misses,
    required this.maxEntries,
  });
  final int totalEntries;
  final int validEntries;
  final int expiredEntries;
  final int pendingRequests;
  final int hits;
  final int misses;
  final int maxEntries;

  /// Calculate actual hit rate based on get() calls
  double get hitRate {
    final total = hits + misses;
    if (total == 0) return 0;
    return hits / total;
  }

  /// Calculate miss rate
  double get missRate => 1.0 - hitRate;

  /// Cache utilization percentage
  double get utilizationPercent => totalEntries / maxEntries * 100;

  @override
  String toString() {
    return 'CacheStats('
        'entries: $totalEntries/$maxEntries, '
        'valid: $validEntries, '
        'pending: $pendingRequests, '
        'hitRate: ${(hitRate * 100).toStringAsFixed(1)}%)';
  }

  /// Convert to map (for logging/analytics)
  Map<String, dynamic> toMap() {
    return {
      'total': totalEntries,
      'valid': validEntries,
      'expired': expiredEntries,
      'pending': pendingRequests,
      'hits': hits,
      'misses': misses,
      'maxEntries': maxEntries,
      'hitRate': hitRate,
      'utilizationPercent': utilizationPercent.round(),
    };
  }
}

/// Cache entry with expiration tracking
class CacheEntry<T> {
  CacheEntry({required this.data, required this.timestamp, required this.ttl});
  final T data;
  final DateTime timestamp;
  final Duration ttl;

  /// Check if cache entry has expired
  bool get isExpired {
    if (ttl == Duration.zero) return true; // Never cache
    final now = DateTime.now();
    final expiryTime = timestamp.add(ttl);
    return now.isAfter(expiryTime);
  }

  /// Check if cache entry is valid (not expired)
  bool get isValid => !isExpired;

  /// Get remaining time until expiry
  Duration get remainingTime {
    final now = DateTime.now();
    final expiryTime = timestamp.add(ttl);
    final remaining = expiryTime.difference(now);
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Get age of the cache entry
  Duration get age => DateTime.now().difference(timestamp);
}
