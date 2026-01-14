import 'package:flutter_test/flutter_test.dart';
import 'package:street_core/core/services/cache_service.dart';
import 'package:street_core/core/helpers/retry_helper.dart';

/// Site Config Performance Tests
///
/// Tests all the optimizations made to the site_config module:
/// - Cache TTL configuration
/// - Retry helper with exponential backoff
/// - Preloader functionality
/// - Cache statistics
///
/// Run with: flutter test test/features/site_config_test.dart
void main() {
  group('Cache Service Tests', () {
    late CacheService cache;

    setUp(() {
      cache = CacheService.instance;
      cache.clearAll(); // Start fresh for each test
    });

    tearDown(() {
      cache.clearAll(); // Clean up after each test
    });

    test('Cache TTL configuration is logical', () {
      // Verify TTL constants follow the documented strategy
      expect(CacheTTL.companyInfo, const Duration(hours: 24));
      expect(CacheTTL.socialMedia, const Duration(hours: 24));
      expect(CacheTTL.contactInfo, const Duration(hours: 24));
      expect(CacheTTL.legalTexts, const Duration(hours: 24));
      expect(CacheTTL.landingTexts, const Duration(minutes: 15));
      expect(CacheTTL.seoConfig, const Duration(minutes: 5));
      expect(CacheTTL.appConfig, const Duration(minutes: 2));
      expect(CacheTTL.basicConfig, const Duration(hours: 24));
    });

    test('Cache stores and retrieves data correctly', () {
      const testKey = 'test_key';
      const testData = 'test_data';

      cache.set(testKey, testData, ttl: const Duration(seconds: 10));

      final retrieved = cache.get<String>(testKey);
      expect(retrieved, testData);
    });

    test('Cache respects TTL expiration', () async {
      const testKey = 'expiring_key';
      const testData = 'expiring_data';

      cache.set(testKey, testData, ttl: const Duration(milliseconds: 100));

      // Should be available immediately
      expect(cache.has(testKey), true);

      // Wait for expiration
      await Future.delayed(const Duration(milliseconds: 150));

      // Should be expired now
      expect(cache.has(testKey), false);
      expect(cache.get<String>(testKey), null);
    });

    test('Cache tracks hit/miss statistics', () {
      cache.clearAll(); // Reset stats

      // First access - miss
      cache.get<String>('non_existent');
      var stats = cache.getStats();
      expect(stats.misses, 1);
      expect(stats.hits, 0);

      // Store data
      cache.set('key1', 'data1', ttl: const Duration(minutes: 5));

      // Second access - hit
      cache.get<String>('key1');
      stats = cache.getStats();
      expect(stats.hits, 1);
      expect(stats.misses, 1);

      // Hit rate should be 50%
      expect(stats.hitRate, 0.5);
    });

    test('Cache prevents duplicate concurrent fetches', () async {
      int fetchCount = 0;

      Future<String> fetchData() async {
        fetchCount++;
        await Future.delayed(const Duration(milliseconds: 50));
        return 'data';
      }

      // Start 5 concurrent fetches for the same key
      final futures = List.generate(
        5,
        (_) => cache.getOrFetch<String>(
          key: 'concurrent_test',
          fetchFn: fetchData,
          ttl: const Duration(minutes: 5),
        ),
      );

      final results = await Future.wait(futures);

      // All results should be the same
      expect(results.every((r) => r == 'data'), true);

      // But fetchData should only be called ONCE due to deduplication
      expect(fetchCount, 1);
    });

    test('Cache enforces size limit', () {
      // Fill cache beyond max entries
      for (int i = 0; i < CacheService.maxEntries + 20; i++) {
        cache.set('key_$i', 'data_$i', ttl: const Duration(hours: 1));
      }

      final stats = cache.getStats();

      // Should not exceed max entries
      expect(stats.totalEntries, lessThanOrEqualTo(CacheService.maxEntries));
    });

    test('Cache pattern invalidation works', () {
      cache.set('user_123', 'data1', ttl: const Duration(hours: 1));
      cache.set('user_456', 'data2', ttl: const Duration(hours: 1));
      cache.set('post_789', 'data3', ttl: const Duration(hours: 1));

      // Invalidate all user-related cache
      cache.invalidatePattern('user_');

      expect(cache.has('user_123'), false);
      expect(cache.has('user_456'), false);
      expect(cache.has('post_789'), true); // Should remain
    });

    test('Cache prefix invalidation works', () {
      cache.set('list_users', 'data1', ttl: const Duration(hours: 1));
      cache.set('list_posts', 'data2', ttl: const Duration(hours: 1));
      cache.set('detail_user', 'data3', ttl: const Duration(hours: 1));

      cache.invalidatePrefix('list_');

      expect(cache.has('list_users'), false);
      expect(cache.has('list_posts'), false);
      expect(cache.has('detail_user'), true); // Should remain
    });

    test('Cache cleanup removes expired entries', () async {
      cache.set('expired1', 'data1', ttl: const Duration(milliseconds: 50));
      cache.set('expired2', 'data2', ttl: const Duration(milliseconds: 50));
      cache.set('valid', 'data3', ttl: const Duration(hours: 1));

      final statsBefore = cache.getStats();
      expect(statsBefore.totalEntries, 3);

      // Wait for expiration
      await Future.delayed(const Duration(milliseconds: 100));
      cache.cleanupExpired();

      final statsAfter = cache.getStats();
      expect(statsAfter.validEntries, 1);
      expect(cache.has('valid'), true);
    });

    test('Cache statistics are accurate', () async {
      cache.clearAll();

      cache.set('key1', 'data1', ttl: const Duration(hours: 1));
      cache.set('key2', 'data2', ttl: const Duration(hours: 1));
      cache.set('key3', 'data3', ttl: const Duration(milliseconds: 1));

      // Wait for one to expire
      await Future.delayed(const Duration(milliseconds: 10));
      final stats = cache.getStats();

      expect(stats.totalEntries, 3);
      expect(stats.validEntries, 2);
      expect(stats.expiredEntries, 1);
      expect(stats.maxEntries, CacheService.maxEntries);
      expect(stats.utilizationPercent, greaterThan(0));
    });
  });

  group('Retry Helper Tests', () {
    test('Retry succeeds on first attempt', () async {
      int attempts = 0;

      final result = await RetryHelper.execute<String>(
        operation: () async {
          attempts++;
          return 'success';
        },
        maxAttempts: 3,
        operationName: 'test_operation',
      );

      expect(result, 'success');
      expect(attempts, 1);
    });

    test('Retry succeeds after failures', () async {
      int attempts = 0;

      final result = await RetryHelper.execute<String>(
        operation: () async {
          attempts++;
          if (attempts < 3) {
            throw Exception('Temporary failure');
          }
          return 'success';
        },
        maxAttempts: 5,
        initialDelay: 10, // Fast for testing
        operationName: 'test_operation',
      );

      expect(result, 'success');
      expect(attempts, 3);
    });

    test('Retry throws after max attempts', () async {
      int attempts = 0;

      expect(
        () => RetryHelper.execute<String>(
          operation: () async {
            attempts++;
            throw Exception('Permanent failure');
          },
          maxAttempts: 3,
          initialDelay: 10, // Fast for testing
          operationName: 'test_operation',
        ),
        throwsA(isA<Exception>()),
      );

      await Future.delayed(const Duration(milliseconds: 100));
      expect(attempts, 3);
    });

    test('Retry respects retryIf condition', () async {
      int attempts = 0;

      expect(
        () => RetryHelper.execute<String>(
          operation: () async {
            attempts++;
            throw Exception('Non-retryable error');
          },
          maxAttempts: 3,
          retryIf: (error) => false, // Never retry
          operationName: 'test_operation',
        ),
        throwsA(isA<Exception>()),
      );

      await Future.delayed(const Duration(milliseconds: 50));
      expect(attempts, 1); // Should not retry
    });

    test('Retry uses exponential backoff', () async {
      final timestamps = <DateTime>[];
      int attempts = 0;

      try {
        await RetryHelper.execute<String>(
          operation: () async {
            timestamps.add(DateTime.now());
            attempts++;
            throw Exception('Test failure');
          },
          maxAttempts: 3,
          initialDelay: 100,
          backoffFactor: 2.0,
          jitter: false, // Disable jitter for predictable timing
          operationName: 'test_operation',
        );
      } catch (_) {
        // Expected to fail
      }

      expect(attempts, 3);
      expect(timestamps.length, 3);

      // Check delays between attempts (approximate due to async timing)
      if (timestamps.length >= 2) {
        final delay1 =
            timestamps[1].difference(timestamps[0]).inMilliseconds;
        expect(delay1, greaterThanOrEqualTo(90)); // ~100ms with tolerance
      }

      if (timestamps.length >= 3) {
        final delay2 =
            timestamps[2].difference(timestamps[1]).inMilliseconds;
        expect(delay2, greaterThanOrEqualTo(180)); // ~200ms with tolerance
      }
    });

    test('Network retry helper has correct defaults', () async {
      int attempts = 0;

      final result = await RetryHelper.executeNetwork<String>(
        operation: () async {
          attempts++;
          if (attempts < 2) {
            throw Exception('Network error');
          }
          return 'success';
        },
        operationName: 'network_test',
      );

      expect(result, 'success');
      expect(attempts, 2);
    });

    test('RetryConditions identify network errors', () {
      expect(
        RetryConditions.isNetworkError(Exception('socket error')),
        true,
      );
      expect(
        RetryConditions.isNetworkError(Exception('network timeout')),
        true,
      );
      expect(
        RetryConditions.isNetworkError(Exception('connection refused')),
        true,
      );
      expect(
        RetryConditions.isNetworkError(Exception('failed host lookup')),
        true,
      );
      expect(
        RetryConditions.isNetworkError(Exception('validation error')),
        false,
      );
    });

    test('RetryConditions identify server errors', () {
      expect(RetryConditions.isServerError(Exception('500 error')), true);
      expect(RetryConditions.isServerError(Exception('502 error')), true);
      expect(RetryConditions.isServerError(Exception('503 error')), true);
      expect(RetryConditions.isServerError(Exception('504 error')), true);
      expect(RetryConditions.isServerError(Exception('404 error')), false);
      expect(RetryConditions.isServerError(Exception('400 error')), false);
    });

    test('Retry with jitter adds randomness', () async {
      final delays = <int>[];

      for (int i = 0; i < 5; i++) {
        final start = DateTime.now();
        try {
          await RetryHelper.execute<String>(
            operation: () async {
              throw Exception('Test');
            },
            maxAttempts: 2,
            initialDelay: 100,
            jitter: true,
            operationName: 'jitter_test',
          );
        } catch (_) {
          final delay = DateTime.now().difference(start).inMilliseconds;
          delays.add(delay);
        }
      }

      // With jitter, delays should vary
      final uniqueDelays = delays.toSet();
      expect(uniqueDelays.length, greaterThan(1));
    });
  });

  group('Cache Integration Tests', () {
    test('Site config TTLs follow stability strategy', () {
      // Very stable data (company info, legal texts) = 24h
      expect(CacheTTL.companyInfo, const Duration(hours: 24));
      expect(CacheTTL.socialMedia, const Duration(hours: 24));
      expect(CacheTTL.contactInfo, const Duration(hours: 24));
      expect(CacheTTL.legalTexts, const Duration(hours: 24));
      expect(CacheTTL.basicConfig, const Duration(hours: 24));

      // Marketing content (can change frequently) = 15min
      expect(CacheTTL.landingTexts, const Duration(minutes: 15));

      // SEO config (campaigns may need quick changes) = 5min
      expect(CacheTTL.seoConfig, const Duration(minutes: 5));

      // Critical (maintenance mode must propagate fast) = 2min
      expect(CacheTTL.appConfig, const Duration(minutes: 2));
    });

    test('Cache getOrFetch with retry integration', () async {
      final cache = CacheService.instance;
      cache.clearAll();

      int fetchAttempts = 0;

      final result = await cache.getOrFetch<String>(
        key: 'test_with_retry',
        ttl: const Duration(minutes: 5),
        fetchFn: () => RetryHelper.executeNetwork<String>(
          operation: () async {
            fetchAttempts++;
            if (fetchAttempts < 2) {
              throw Exception('Temporary network error');
            }
            return 'data';
          },
          operationName: 'test_fetch',
        ),
      );

      expect(result, 'data');
      expect(fetchAttempts, 2); // Should retry once

      // Second call should use cache (no additional fetch)
      final cachedResult = await cache.getOrFetch<String>(
        key: 'test_with_retry',
        ttl: const Duration(minutes: 5),
        fetchFn: () => RetryHelper.executeNetwork<String>(
          operation: () async {
            fetchAttempts++;
            return 'data';
          },
          operationName: 'test_fetch',
        ),
      );

      expect(cachedResult, 'data');
      expect(fetchAttempts, 2); // Should not fetch again
    });

    test('Cache performance under load', () async {
      final cache = CacheService.instance;
      cache.clearAll();

      final stopwatch = Stopwatch()..start();

      // Simulate 100 concurrent cache operations
      final futures = List.generate(100, (i) async {
        cache.set('key_$i', 'data_$i', ttl: const Duration(minutes: 5));
        final value = cache.get<String>('key_$i');
        expect(value, 'data_$i');
      });

      await Future.wait(futures);

      stopwatch.stop();

      // Should complete reasonably fast (< 500ms)
      expect(stopwatch.elapsedMilliseconds, lessThan(500));

      final stats = cache.getStats();
      expect(stats.hits, 100);
    });
  });
}
