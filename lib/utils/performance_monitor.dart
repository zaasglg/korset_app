import 'dart:collection';

/// Performance monitoring utility for API calls and app performance
class PerformanceMonitor {
  static PerformanceMonitor? _instance;
  
  final Map<String, List<Duration>> _requestTimes = {};
  final Map<String, int> _requestCounts = {};
  final Map<String, int> _errorCounts = {};
  final Map<String, DateTime> _lastRequestTimes = {};
  final Queue<PerformanceMetric> _recentMetrics = Queue();
  
  static const int _maxMetricsHistory = 100;
  static const Duration _slowRequestThreshold = Duration(seconds: 3);

  PerformanceMonitor._();

  factory PerformanceMonitor() {
    return _instance ??= PerformanceMonitor._();
  }

  /// Start timing a request
  Stopwatch startTiming(String endpoint) {
    final stopwatch = Stopwatch()..start();
    _lastRequestTimes[endpoint] = DateTime.now();
    return stopwatch;
  }

  /// Record request completion
  void recordRequest(String endpoint, Duration duration, {bool isError = false}) {
    // Update request times
    _requestTimes.putIfAbsent(endpoint, () => []).add(duration);
    
    // Update counters
    _requestCounts[endpoint] = (_requestCounts[endpoint] ?? 0) + 1;
    if (isError) {
      _errorCounts[endpoint] = (_errorCounts[endpoint] ?? 0) + 1;
    }

    // Add to recent metrics
    final metric = PerformanceMetric(
      endpoint: endpoint,
      duration: duration,
      timestamp: DateTime.now(),
      isError: isError,
      isSlow: duration > _slowRequestThreshold,
    );
    
    _recentMetrics.add(metric);
    
    // Keep only recent metrics
    while (_recentMetrics.length > _maxMetricsHistory) {
      _recentMetrics.removeFirst();
    }

    // Log slow requests
    if (duration > _slowRequestThreshold) {
      print('PerformanceMonitor: Slow request detected - $endpoint took ${duration.inMilliseconds}ms');
    }
  }

  /// Get average response time for an endpoint
  Duration? getAverageResponseTime(String endpoint) {
    final times = _requestTimes[endpoint];
    if (times == null || times.isEmpty) return null;
    
    final totalMs = times.fold<int>(0, (sum, duration) => sum + duration.inMilliseconds);
    return Duration(milliseconds: (totalMs / times.length).round());
  }

  /// Get request count for an endpoint
  int getRequestCount(String endpoint) {
    return _requestCounts[endpoint] ?? 0;
  }

  /// Get error count for an endpoint
  int getErrorCount(String endpoint) {
    return _errorCounts[endpoint] ?? 0;
  }

  /// Get error rate for an endpoint (0.0 to 1.0)
  double getErrorRate(String endpoint) {
    final total = getRequestCount(endpoint);
    if (total == 0) return 0.0;
    
    final errors = getErrorCount(endpoint);
    return errors / total;
  }

  /// Get last request time for an endpoint
  DateTime? getLastRequestTime(String endpoint) {
    return _lastRequestTimes[endpoint];
  }

  /// Get performance statistics for an endpoint
  EndpointStats? getEndpointStats(String endpoint) {
    final times = _requestTimes[endpoint];
    if (times == null || times.isEmpty) return null;

    times.sort((a, b) => a.compareTo(b));
    
    final count = times.length;
    final min = times.first;
    final max = times.last;
    final median = times[count ~/ 2];
    final p95Index = ((count - 1) * 0.95).round();
    final p95 = times[p95Index];
    
    final totalMs = times.fold<int>(0, (sum, duration) => sum + duration.inMilliseconds);
    final average = Duration(milliseconds: (totalMs / count).round());

    return EndpointStats(
      endpoint: endpoint,
      requestCount: getRequestCount(endpoint),
      errorCount: getErrorCount(endpoint),
      errorRate: getErrorRate(endpoint),
      averageResponseTime: average,
      minResponseTime: min,
      maxResponseTime: max,
      medianResponseTime: median,
      p95ResponseTime: p95,
      lastRequestTime: getLastRequestTime(endpoint),
    );
  }

  /// Get overall performance summary
  PerformanceSummary getPerformanceSummary() {
    final allEndpoints = {..._requestTimes.keys, ..._requestCounts.keys};
    final endpointStats = <EndpointStats>[];
    
    int totalRequests = 0;
    int totalErrors = 0;
    final allDurations = <Duration>[];
    
    for (final endpoint in allEndpoints) {
      final stats = getEndpointStats(endpoint);
      if (stats != null) {
        endpointStats.add(stats);
        totalRequests += stats.requestCount;
        totalErrors += stats.errorCount;
        
        final times = _requestTimes[endpoint];
        if (times != null) {
          allDurations.addAll(times);
        }
      }
    }

    Duration? overallAverage;
    if (allDurations.isNotEmpty) {
      final totalMs = allDurations.fold<int>(0, (sum, duration) => sum + duration.inMilliseconds);
      overallAverage = Duration(milliseconds: (totalMs / allDurations.length).round());
    }

    final slowRequests = _recentMetrics.where((m) => m.isSlow).length;
    final recentErrors = _recentMetrics.where((m) => m.isError).length;

    return PerformanceSummary(
      totalRequests: totalRequests,
      totalErrors: totalErrors,
      overallErrorRate: totalRequests > 0 ? totalErrors / totalRequests : 0.0,
      overallAverageResponseTime: overallAverage,
      endpointStats: endpointStats,
      slowRequestsCount: slowRequests,
      recentErrorsCount: recentErrors,
      monitoringPeriod: _getMonitoringPeriod(),
    );
  }

  /// Get recent slow requests
  List<PerformanceMetric> getSlowRequests({int limit = 10}) {
    return _recentMetrics
        .where((m) => m.isSlow)
        .take(limit)
        .toList()
        .reversed
        .toList();
  }

  /// Get recent errors
  List<PerformanceMetric> getRecentErrors({int limit = 10}) {
    return _recentMetrics
        .where((m) => m.isError)
        .take(limit)
        .toList()
        .reversed
        .toList();
  }

  /// Get monitoring period
  Duration _getMonitoringPeriod() {
    if (_recentMetrics.isEmpty) return Duration.zero;
    
    final oldest = _recentMetrics.first.timestamp;
    final newest = _recentMetrics.last.timestamp;
    return newest.difference(oldest);
  }

  /// Clear all performance data
  void clear() {
    _requestTimes.clear();
    _requestCounts.clear();
    _errorCounts.clear();
    _lastRequestTimes.clear();
    _recentMetrics.clear();
  }

  /// Export performance data as JSON
  Map<String, dynamic> exportData() {
    return {
      'summary': getPerformanceSummary().toJson(),
      'slowRequests': getSlowRequests().map((m) => m.toJson()).toList(),
      'recentErrors': getRecentErrors().map((m) => m.toJson()).toList(),
      'exportTime': DateTime.now().toIso8601String(),
    };
  }
}

/// Performance metric for a single request
class PerformanceMetric {
  final String endpoint;
  final Duration duration;
  final DateTime timestamp;
  final bool isError;
  final bool isSlow;

  PerformanceMetric({
    required this.endpoint,
    required this.duration,
    required this.timestamp,
    required this.isError,
    required this.isSlow,
  });

  Map<String, dynamic> toJson() => {
    'endpoint': endpoint,
    'duration': duration.inMilliseconds,
    'timestamp': timestamp.toIso8601String(),
    'isError': isError,
    'isSlow': isSlow,
  };
}

/// Statistics for a specific endpoint
class EndpointStats {
  final String endpoint;
  final int requestCount;
  final int errorCount;
  final double errorRate;
  final Duration averageResponseTime;
  final Duration minResponseTime;
  final Duration maxResponseTime;
  final Duration medianResponseTime;
  final Duration p95ResponseTime;
  final DateTime? lastRequestTime;

  EndpointStats({
    required this.endpoint,
    required this.requestCount,
    required this.errorCount,
    required this.errorRate,
    required this.averageResponseTime,
    required this.minResponseTime,
    required this.maxResponseTime,
    required this.medianResponseTime,
    required this.p95ResponseTime,
    this.lastRequestTime,
  });

  Map<String, dynamic> toJson() => {
    'endpoint': endpoint,
    'requestCount': requestCount,
    'errorCount': errorCount,
    'errorRate': errorRate,
    'averageResponseTime': averageResponseTime.inMilliseconds,
    'minResponseTime': minResponseTime.inMilliseconds,
    'maxResponseTime': maxResponseTime.inMilliseconds,
    'medianResponseTime': medianResponseTime.inMilliseconds,
    'p95ResponseTime': p95ResponseTime.inMilliseconds,
    'lastRequestTime': lastRequestTime?.toIso8601String(),
  };
}

/// Overall performance summary
class PerformanceSummary {
  final int totalRequests;
  final int totalErrors;
  final double overallErrorRate;
  final Duration? overallAverageResponseTime;
  final List<EndpointStats> endpointStats;
  final int slowRequestsCount;
  final int recentErrorsCount;
  final Duration monitoringPeriod;

  PerformanceSummary({
    required this.totalRequests,
    required this.totalErrors,
    required this.overallErrorRate,
    this.overallAverageResponseTime,
    required this.endpointStats,
    required this.slowRequestsCount,
    required this.recentErrorsCount,
    required this.monitoringPeriod,
  });

  Map<String, dynamic> toJson() => {
    'totalRequests': totalRequests,
    'totalErrors': totalErrors,
    'overallErrorRate': overallErrorRate,
    'overallAverageResponseTime': overallAverageResponseTime?.inMilliseconds,
    'endpointStats': endpointStats.map((s) => s.toJson()).toList(),
    'slowRequestsCount': slowRequestsCount,
    'recentErrorsCount': recentErrorsCount,
    'monitoringPeriod': monitoringPeriod.inMilliseconds,
  };
}

/// Global performance monitor instance
final performanceMonitor = PerformanceMonitor();