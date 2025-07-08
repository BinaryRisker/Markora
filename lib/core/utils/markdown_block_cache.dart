import 'package:flutter/widgets.dart';
import 'markdown_block_parser.dart';

/// Cache statistics
class CacheStatistics {
  CacheStatistics({
    this.hitCount = 0,
    this.missCount = 0,
    this.evictionCount = 0,
    this.totalSize = 0,
  });

  /// Number of cache hits
  final int hitCount;
  
  /// Number of cache misses
  final int missCount;
  
  /// Number of cache evictions
  final int evictionCount;
  
  /// Total cache size (number of items)
  final int totalSize;

  /// Cache hit ratio
  double get hitRatio {
    final total = hitCount + missCount;
    return total > 0 ? hitCount / total : 0.0;
  }

  CacheStatistics copyWith({
    int? hitCount,
    int? missCount,
    int? evictionCount,
    int? totalSize,
  }) {
    return CacheStatistics(
      hitCount: hitCount ?? this.hitCount,
      missCount: missCount ?? this.missCount,
      evictionCount: evictionCount ?? this.evictionCount,
      totalSize: totalSize ?? this.totalSize,
    );
  }

  @override
  String toString() {
    return 'CacheStats(hits: $hitCount, misses: $missCount, ratio: ${(hitRatio * 100).toStringAsFixed(1)}%, size: $totalSize)';
  }
}

/// Cache entry with metadata
class _CacheEntry {
  _CacheEntry({
    required this.widget,
    required this.accessTime,
    required this.createTime,
    this.accessCount = 1,
  });

  /// Cached widget
  final Widget widget;
  
  /// Last access time
  DateTime accessTime;
  
  /// Creation time
  final DateTime createTime;
  
  /// Access count
  int accessCount;

  /// Update access information
  void updateAccess() {
    accessTime = DateTime.now();
    accessCount++;
  }

  /// Age of the cache entry
  Duration get age => DateTime.now().difference(createTime);
}

/// LRU cache for markdown block widgets
class MarkdownBlockCache {
  MarkdownBlockCache({
    this.maxSize = 100,
    this.maxAge = const Duration(minutes: 10),
  });

  /// Maximum cache size
  final int maxSize;
  
  /// Maximum age for cache entries
  final Duration maxAge;

  /// Cache storage
  final Map<String, _CacheEntry> _cache = {};
  
  /// Access order (for LRU)
  final List<String> _accessOrder = [];
  
  /// Cache statistics
  CacheStatistics _stats = CacheStatistics();

  /// Get cache statistics
  CacheStatistics get statistics => _stats;

  /// Get cached widget
  Widget? get(String key) {
    final entry = _cache[key];
    if (entry == null) {
      _stats = _stats.copyWith(missCount: _stats.missCount + 1);
      return null;
    }

    // Check if entry is expired
    if (entry.age > maxAge) {
      _remove(key);
      _stats = _stats.copyWith(missCount: _stats.missCount + 1);
      return null;
    }

    // Update access information
    entry.updateAccess();
    _updateAccessOrder(key);
    
    _stats = _stats.copyWith(hitCount: _stats.hitCount + 1);
    return entry.widget;
  }

  /// Put widget in cache
  void put(String key, Widget widget) {
    final now = DateTime.now();
    
    // If key already exists, update it
    if (_cache.containsKey(key)) {
      _cache[key] = _CacheEntry(
        widget: widget,
        accessTime: now,
        createTime: now,
      );
      _updateAccessOrder(key);
      return;
    }

    // Check if cache is full
    if (_cache.length >= maxSize) {
      _evictLRU();
    }

    // Add new entry
    _cache[key] = _CacheEntry(
      widget: widget,
      accessTime: now,
      createTime: now,
    );
    _accessOrder.add(key);
    
    _stats = _stats.copyWith(totalSize: _cache.length);
  }

  /// Remove entry from cache
  void remove(String key) {
    _remove(key);
    _stats = _stats.copyWith(totalSize: _cache.length);
  }

  /// Clear all cache
  void clear() {
    _cache.clear();
    _accessOrder.clear();
    _stats = CacheStatistics();
  }

  /// Clean expired entries
  void cleanExpired() {
    final now = DateTime.now();
    final expiredKeys = <String>[];
    
    for (final entry in _cache.entries) {
      if (now.difference(entry.value.createTime) > maxAge) {
        expiredKeys.add(entry.key);
      }
    }
    
    for (final key in expiredKeys) {
      _remove(key);
    }
    
    _stats = _stats.copyWith(totalSize: _cache.length);
  }

  /// Get cache size
  int get size => _cache.length;

  /// Check if cache is empty
  bool get isEmpty => _cache.isEmpty;

  /// Check if cache contains key
  bool containsKey(String key) => _cache.containsKey(key);

  /// Get all cached keys
  List<String> get keys => List.unmodifiable(_cache.keys);

  /// Get memory usage estimation (approximate)
  int get estimatedMemoryUsage {
    // Rough estimation: each widget entry ~1KB
    return _cache.length * 1024;
  }

  /// Update access order for LRU
  void _updateAccessOrder(String key) {
    _accessOrder.remove(key);
    _accessOrder.add(key);
  }

  /// Evict least recently used entry
  void _evictLRU() {
    if (_accessOrder.isNotEmpty) {
      final lruKey = _accessOrder.first;
      _remove(lruKey);
      _stats = _stats.copyWith(evictionCount: _stats.evictionCount + 1);
    }
  }

  /// Remove entry (internal)
  void _remove(String key) {
    _cache.remove(key);
    _accessOrder.remove(key);
  }

  /// Get cache efficiency report
  String getEfficiencyReport() {
    final buffer = StringBuffer();
    buffer.writeln('=== Markdown Block Cache Report ===');
    buffer.writeln('Cache Size: ${_cache.length}/$maxSize');
    buffer.writeln('Hit Ratio: ${(_stats.hitRatio * 100).toStringAsFixed(1)}%');
    buffer.writeln('Total Hits: ${_stats.hitCount}');
    buffer.writeln('Total Misses: ${_stats.missCount}');
    buffer.writeln('Evictions: ${_stats.evictionCount}');
    buffer.writeln('Memory Usage: ~${(estimatedMemoryUsage / 1024).toStringAsFixed(1)} KB');
    
    if (_cache.isNotEmpty) {
      buffer.writeln('\n=== Most Accessed Blocks ===');
      final sortedEntries = _cache.entries.toList()
        ..sort((a, b) => b.value.accessCount.compareTo(a.value.accessCount));
      
      for (int i = 0; i < 5 && i < sortedEntries.length; i++) {
        final entry = sortedEntries[i];
        buffer.writeln('${entry.key.substring(0, 8)}... (${entry.value.accessCount} hits)');
      }
    }
    
    return buffer.toString();
  }
}

/// Global cache instance for markdown blocks
final markdownBlockCache = MarkdownBlockCache();

/// Cache key generator for markdown blocks
class CacheKeyGenerator {
  /// Generate cache key for a markdown block
  static String forBlock(MarkdownBlock block, {
    String? fontFamily,
    double? fontSize,
    String? theme,
    String? language,
  }) {
    final buffer = StringBuffer();
    buffer.write(block.hash);
    
    if (fontFamily != null) {
      buffer.write('_font:$fontFamily');
    }
    
    if (fontSize != null) {
      buffer.write('_size:$fontSize');
    }
    
    if (theme != null) {
      buffer.write('_theme:$theme');
    }
    
    if (language != null) {
      buffer.write('_lang:$language');
    }
    
    return buffer.toString();
  }

  /// Generate cache key for content with settings
  static String forContent(String content, {
    String? fontFamily,
    double? fontSize,
    String? theme,
    String? language,
  }) {
    final contentHash = MarkdownBlock.generateHash(content);
    return forBlock(
      MarkdownBlock(
        type: MarkdownBlockType.paragraph,
        content: content,
        startLine: 0,
        endLine: 0,
        hash: contentHash,
      ),
      fontFamily: fontFamily,
      fontSize: fontSize,
      theme: theme,
      language: language,
    );
  }
} 