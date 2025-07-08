import 'dart:async';

/// Performance monitoring utility for markdown rendering
class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  final List<PerformanceMetric> _metrics = [];
  final List<StreamController<PerformanceMetric>> _listeners = [];

  /// Record a performance metric
  void recordMetric(PerformanceMetric metric) {
    _metrics.add(metric);
    
    // Keep only last 100 metrics to avoid memory bloat
    if (_metrics.length > 100) {
      _metrics.removeAt(0);
    }
    
    // Notify listeners
    for (final controller in _listeners) {
      if (!controller.isClosed) {
        controller.add(metric);
      }
    }
  }

  /// Start timing an operation
  PerformanceTimer startTimer(String operationName) {
    return PerformanceTimer(operationName, this);
  }

  /// Get performance statistics
  PerformanceStatistics getStatistics() {
    if (_metrics.isEmpty) {
      return PerformanceStatistics.empty();
    }

    final parseMetrics = _metrics.where((m) => m.type == MetricType.parsing).toList();
    final renderMetrics = _metrics.where((m) => m.type == MetricType.rendering).toList();
    final cacheMetrics = _metrics.where((m) => m.type == MetricType.caching).toList();

    return PerformanceStatistics(
      totalOperations: _metrics.length,
      averageParseTime: _calculateAverage(parseMetrics),
      averageRenderTime: _calculateAverage(renderMetrics),
      averageCacheTime: _calculateAverage(cacheMetrics),
      maxParseTime: _calculateMax(parseMetrics),
      maxRenderTime: _calculateMax(renderMetrics),
      minParseTime: _calculateMin(parseMetrics),
      minRenderTime: _calculateMin(renderMetrics),
      recentMetrics: _metrics.take(10).toList(),
    );
  }

  /// Listen to performance metrics
  Stream<PerformanceMetric> get metricsStream {
    final controller = StreamController<PerformanceMetric>.broadcast();
    _listeners.add(controller);
    return controller.stream;
  }

  /// Clear all metrics
  void clear() {
    _metrics.clear();
  }

  /// Get performance report as string
  String getPerformanceReport() {
    final stats = getStatistics();
    
    final buffer = StringBuffer();
    buffer.writeln('=== Performance Report ===');
    buffer.writeln('Total Operations: ${stats.totalOperations}');
    buffer.writeln('');
    buffer.writeln('Parsing Performance:');
    buffer.writeln('  Average: ${stats.averageParseTime.toStringAsFixed(2)}ms');
    buffer.writeln('  Min: ${stats.minParseTime.toStringAsFixed(2)}ms');
    buffer.writeln('  Max: ${stats.maxParseTime.toStringAsFixed(2)}ms');
    buffer.writeln('');
    buffer.writeln('Rendering Performance:');
    buffer.writeln('  Average: ${stats.averageRenderTime.toStringAsFixed(2)}ms');
    buffer.writeln('  Min: ${stats.minRenderTime.toStringAsFixed(2)}ms');
    buffer.writeln('  Max: ${stats.maxRenderTime.toStringAsFixed(2)}ms');
    buffer.writeln('');
    buffer.writeln('Cache Performance:');
    buffer.writeln('  Average: ${stats.averageCacheTime.toStringAsFixed(2)}ms');
    buffer.writeln('');
    buffer.writeln('Recent Operations:');
    for (final metric in stats.recentMetrics) {
      buffer.writeln('  ${metric.operationName}: ${metric.duration.toStringAsFixed(2)}ms');
    }
    
    return buffer.toString();
  }

  double _calculateAverage(List<PerformanceMetric> metrics) {
    if (metrics.isEmpty) return 0.0;
    final total = metrics.fold<double>(0.0, (sum, m) => sum + m.duration);
    return total / metrics.length;
  }

  double _calculateMax(List<PerformanceMetric> metrics) {
    if (metrics.isEmpty) return 0.0;
    return metrics.fold<double>(0.0, (max, m) => m.duration > max ? m.duration : max);
  }

  double _calculateMin(List<PerformanceMetric> metrics) {
    if (metrics.isEmpty) return 0.0;
    return metrics.fold<double>(double.infinity, (min, m) => m.duration < min ? m.duration : min);
  }
}

/// Performance timer for measuring operation duration
class PerformanceTimer {
  PerformanceTimer(this.operationName, this.monitor) : _stopwatch = Stopwatch()..start();

  final String operationName;
  final PerformanceMonitor monitor;
  final Stopwatch _stopwatch;
  bool _stopped = false;

  /// Stop the timer and record the metric
  void stop({MetricType? type, Map<String, dynamic>? metadata}) {
    if (_stopped) return;
    
    _stopwatch.stop();
    _stopped = true;
    
    final metric = PerformanceMetric(
      operationName: operationName,
      duration: _stopwatch.elapsedMicroseconds / 1000.0, // Convert to milliseconds
      timestamp: DateTime.now(),
      type: type ?? MetricType.other,
      metadata: metadata ?? {},
    );
    
    monitor.recordMetric(metric);
  }
}

/// Performance metric data
class PerformanceMetric {
  const PerformanceMetric({
    required this.operationName,
    required this.duration,
    required this.timestamp,
    required this.type,
    required this.metadata,
  });

  /// Name of the operation
  final String operationName;
  
  /// Duration in milliseconds
  final double duration;
  
  /// When the metric was recorded
  final DateTime timestamp;
  
  /// Type of metric
  final MetricType type;
  
  /// Additional metadata
  final Map<String, dynamic> metadata;

  @override
  String toString() {
    return 'PerformanceMetric(operation: $operationName, duration: ${duration.toStringAsFixed(2)}ms, type: $type)';
  }
}

/// Types of performance metrics
enum MetricType {
  parsing,    // Markdown parsing operations
  rendering,  // Widget rendering operations
  caching,    // Cache operations
  other,      // Other operations
}

/// Performance statistics summary
class PerformanceStatistics {
  const PerformanceStatistics({
    required this.totalOperations,
    required this.averageParseTime,
    required this.averageRenderTime,
    required this.averageCacheTime,
    required this.maxParseTime,
    required this.maxRenderTime,
    required this.minParseTime,
    required this.minRenderTime,
    required this.recentMetrics,
  });

  factory PerformanceStatistics.empty() {
    return const PerformanceStatistics(
      totalOperations: 0,
      averageParseTime: 0.0,
      averageRenderTime: 0.0,
      averageCacheTime: 0.0,
      maxParseTime: 0.0,
      maxRenderTime: 0.0,
      minParseTime: 0.0,
      minRenderTime: 0.0,
      recentMetrics: [],
    );
  }

  final int totalOperations;
  final double averageParseTime;
  final double averageRenderTime;
  final double averageCacheTime;
  final double maxParseTime;
  final double maxRenderTime;
  final double minParseTime;
  final double minRenderTime;
  final List<PerformanceMetric> recentMetrics;
}

/// Global performance monitor instance
final performanceMonitor = PerformanceMonitor(); 