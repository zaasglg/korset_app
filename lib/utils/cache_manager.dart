import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Advanced cache manager with persistent storage and memory optimization
class CacheManager {
  static CacheManager? _instance;
  
  final Map<String, dynamic> _memoryCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  final Map<String, Duration> _cacheDurations = {};
  
  SharedPreferences? _prefs;
  Timer? _cleanupTimer;
  
  static const String _cachePrefix = 'cache_';
  static const String _timestampPrefix = 'timestamp_';
  static const Duration _defaultCacheDuration = Duration(minutes: 5);
  static const Duration _cleanupInterval = Duration(minutes: 10);
  static const int _maxMemoryCacheSize = 50; // Maximum number of items in memory cache

  CacheManager._() {
    _startCleanupTimer();
  }

  factory CacheManager() {
    return _instance ??= CacheManager._();
  }

  /// Initialize the cache manager
  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _loadCacheFromDisk();
  }

  /// Store data in cache with optional duration
  Future<void> store(
    String key, 
    dynamic data, {
    Duration? duration,
    bool persistToDisk = false,
  }) async {
    await initialize();
    
    final cacheDuration = duration ?? _defaultCacheDuration;
    final timestamp = DateTime.now();
    
    // Store in memory cache
    _memoryCache[key] = data;
    _cacheTimestamps[key] = timestamp;
    _cacheDurations[key] = cacheDuration;
    
    // Persist to disk if requested
    if (persistToDisk && _prefs != null) {
      try {
        final jsonData = json.encode(data);
        await _prefs!.setString('$_cachePrefix$key', jsonData);
        await _prefs!.setString('$_timestampPrefix$key', timestamp.toIso8601String());
      } catch (e) {
        // If JSON encoding fails, don't persist
        print('CacheManager: Failed to persist $key to disk: $e');
      }
    }
    
    // Limit memory cache size
    _limitMemoryCacheSize();
  }

  /// Retrieve data from cache
  Future<T?> get<T>(String key) async {
    await initialize();
    
    // Check memory cache first
    if (_memoryCache.containsKey(key)) {
      if (_isCacheValid(key)) {
        return _memoryCache[key] as T?;
      } else {
        // Remove expired cache
        await remove(key);
        return null;
      }
    }
    
    // Check disk cache
    if (_prefs != null) {
      final diskData = await _getFromDisk<T>(key);
      if (diskData != null) {
        // Load back to memory cache
        _memoryCache[key] = diskData;
        return diskData;
      }
    }
    
    return null;
  }

  /// Check if cache entry exists and is valid
  Future<bool> exists(String key) async {
    await initialize();
    
    if (_memoryCache.containsKey(key) && _isCacheValid(key)) {
      return true;
    }
    
    if (_prefs != null) {
      final diskData = await _getFromDisk(key);
      return diskData != null;
    }
    
    return false;
  }

  /// Remove specific cache entry
  Future<void> remove(String key) async {
    await initialize();
    
    // Remove from memory
    _memoryCache.remove(key);
    _cacheTimestamps.remove(key);
    _cacheDurations.remove(key);
    
    // Remove from disk
    if (_prefs != null) {
      await _prefs!.remove('$_cachePrefix$key');
      await _prefs!.remove('$_timestampPrefix$key');
    }
  }

  /// Clear all cache
  Future<void> clear() async {
    await initialize();
    
    // Clear memory cache
    _memoryCache.clear();
    _cacheTimestamps.clear();
    _cacheDurations.clear();
    
    // Clear disk cache
    if (_prefs != null) {
      final keys = _prefs!.getKeys();
      final cacheKeys = keys.where((key) => 
        key.startsWith(_cachePrefix) || key.startsWith(_timestampPrefix)
      ).toList();
      
      for (final key in cacheKeys) {
        await _prefs!.remove(key);
      }
    }
  }

  /// Clear expired cache entries
  Future<void> clearExpired() async {
    await initialize();
    
    final expiredKeys = <String>[];
    
    // Find expired memory cache entries
    for (final key in _memoryCache.keys) {
      if (!_isCacheValid(key)) {
        expiredKeys.add(key);
      }
    }
    
    // Remove expired entries
    for (final key in expiredKeys) {
      await remove(key);
    }
    
    // Check disk cache for expired entries
    if (_prefs != null) {
      await _clearExpiredDiskCache();
    }
  }

  /// Get cache statistics
  Map<String, dynamic> getStats() {
    final now = DateTime.now();
    int validEntries = 0;
    int expiredEntries = 0;
    
    for (final key in _memoryCache.keys) {
      if (_isCacheValid(key)) {
        validEntries++;
      } else {
        expiredEntries++;
      }
    }
    
    return {
      'totalMemoryEntries': _memoryCache.length,
      'validEntries': validEntries,
      'expiredEntries': expiredEntries,
      'memoryUsage': _estimateMemoryUsage(),
      'oldestEntry': _getOldestEntryAge(),
      'newestEntry': _getNewestEntryAge(),
    };
  }

  /// Get all cache keys
  List<String> getKeys() {
    return _memoryCache.keys.toList();
  }

  /// Get cache entry info
  Map<String, dynamic>? getEntryInfo(String key) {
    if (!_memoryCache.containsKey(key)) return null;
    
    final timestamp = _cacheTimestamps[key];
    final duration = _cacheDurations[key];
    final isValid = _isCacheValid(key);
    
    return {
      'key': key,
      'timestamp': timestamp?.toIso8601String(),
      'duration': duration?.inMilliseconds,
      'isValid': isValid,
      'expiresAt': timestamp != null && duration != null 
        ? timestamp.add(duration).toIso8601String() 
        : null,
      'size': _estimateEntrySize(key),
    };
  }

  /// Check if cache entry is valid
  bool _isCacheValid(String key) {
    final timestamp = _cacheTimestamps[key];
    final duration = _cacheDurations[key];
    
    if (timestamp == null || duration == null) return false;
    
    return DateTime.now().difference(timestamp) < duration;
  }

  /// Load cache from disk storage
  Future<void> _loadCacheFromDisk() async {
    if (_prefs == null) return;
    
    final keys = _prefs!.getKeys();
    final cacheKeys = keys.where((key) => key.startsWith(_cachePrefix)).toList();
    
    for (final cacheKey in cacheKeys) {
      final key = cacheKey.substring(_cachePrefix.length);
      final timestampKey = '$_timestampPrefix$key';
      
      if (_prefs!.containsKey(timestampKey)) {
        try {
          final timestampStr = _prefs!.getString(timestampKey);
          if (timestampStr != null) {
            final timestamp = DateTime.parse(timestampStr);
            
            // Check if still valid (using default duration for disk cache)
            if (DateTime.now().difference(timestamp) < _defaultCacheDuration) {
              final dataStr = _prefs!.getString(cacheKey);
              if (dataStr != null) {
                final data = json.decode(dataStr);
                _memoryCache[key] = data;
                _cacheTimestamps[key] = timestamp;
                _cacheDurations[key] = _defaultCacheDuration;
              }
            } else {
              // Remove expired disk cache
              await _prefs!.remove(cacheKey);
              await _prefs!.remove(timestampKey);
            }
          }
        } catch (e) {
          // Remove corrupted cache entry
          await _prefs!.remove(cacheKey);
          await _prefs!.remove(timestampKey);
        }
      }
    }
  }

  /// Get data from disk cache
  Future<T?> _getFromDisk<T>(String key) async {
    if (_prefs == null) return null;
    
    final cacheKey = '$_cachePrefix$key';
    final timestampKey = '$_timestampPrefix$key';
    
    if (!_prefs!.containsKey(cacheKey) || !_prefs!.containsKey(timestampKey)) {
      return null;
    }
    
    try {
      final timestampStr = _prefs!.getString(timestampKey);
      if (timestampStr != null) {
        final timestamp = DateTime.parse(timestampStr);
        
        // Check if still valid
        if (DateTime.now().difference(timestamp) < _defaultCacheDuration) {
          final dataStr = _prefs!.getString(cacheKey);
          if (dataStr != null) {
            final data = json.decode(dataStr);
            
            // Update memory cache
            _cacheTimestamps[key] = timestamp;
            _cacheDurations[key] = _defaultCacheDuration;
            
            return data as T?;
          }
        } else {
          // Remove expired entry
          await _prefs!.remove(cacheKey);
          await _prefs!.remove(timestampKey);
        }
      }
    } catch (e) {
      // Remove corrupted entry
      await _prefs!.remove(cacheKey);
      await _prefs!.remove(timestampKey);
    }
    
    return null;
  }

  /// Clear expired disk cache entries
  Future<void> _clearExpiredDiskCache() async {
    if (_prefs == null) return;
    
    final keys = _prefs!.getKeys();
    final timestampKeys = keys.where((key) => key.startsWith(_timestampPrefix)).toList();
    
    for (final timestampKey in timestampKeys) {
      try {
        final timestampStr = _prefs!.getString(timestampKey);
        if (timestampStr != null) {
          final timestamp = DateTime.parse(timestampStr);
          
          if (DateTime.now().difference(timestamp) >= _defaultCacheDuration) {
            final key = timestampKey.substring(_timestampPrefix.length);
            final cacheKey = '$_cachePrefix$key';
            
            await _prefs!.remove(cacheKey);
            await _prefs!.remove(timestampKey);
          }
        }
      } catch (e) {
        // Remove corrupted timestamp entry
        await _prefs!.remove(timestampKey);
      }
    }
  }

  /// Limit memory cache size to prevent memory issues
  void _limitMemoryCacheSize() {
    if (_memoryCache.length <= _maxMemoryCacheSize) return;
    
    // Remove oldest entries
    final sortedEntries = _cacheTimestamps.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    
    final entriesToRemove = _memoryCache.length - _maxMemoryCacheSize;
    
    for (int i = 0; i < entriesToRemove; i++) {
      final key = sortedEntries[i].key;
      _memoryCache.remove(key);
      _cacheTimestamps.remove(key);
      _cacheDurations.remove(key);
    }
  }

  /// Estimate memory usage of cache
  int _estimateMemoryUsage() {
    int totalSize = 0;
    
    for (final key in _memoryCache.keys) {
      totalSize += _estimateEntrySize(key);
    }
    
    return totalSize;
  }

  /// Estimate size of a cache entry
  int _estimateEntrySize(String key) {
    try {
      final data = _memoryCache[key];
      if (data == null) return 0;
      
      final jsonStr = json.encode(data);
      return jsonStr.length * 2; // Rough estimate (UTF-16)
    } catch (e) {
      return 0;
    }
  }

  /// Get age of oldest cache entry
  Duration? _getOldestEntryAge() {
    if (_cacheTimestamps.isEmpty) return null;
    
    final oldest = _cacheTimestamps.values.reduce((a, b) => a.isBefore(b) ? a : b);
    return DateTime.now().difference(oldest);
  }

  /// Get age of newest cache entry
  Duration? _getNewestEntryAge() {
    if (_cacheTimestamps.isEmpty) return null;
    
    final newest = _cacheTimestamps.values.reduce((a, b) => a.isAfter(b) ? a : b);
    return DateTime.now().difference(newest);
  }

  /// Start cleanup timer
  void _startCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(_cleanupInterval, (_) {
      clearExpired();
    });
  }

  /// Dispose resources
  void dispose() {
    _cleanupTimer?.cancel();
    _memoryCache.clear();
    _cacheTimestamps.clear();
    _cacheDurations.clear();
  }
}

/// Global cache manager instance
final cacheManager = CacheManager();