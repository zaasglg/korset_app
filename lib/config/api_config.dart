/// Legacy API Config - maintained for backward compatibility
/// New optimized config is in optimized_api_config.dart
class ApiConfig {
  // Base URL for API
  static const String baseUrl = 'https://korset.kz';

  // Alternative HTTPS URL (if available)
  static const String secureBaseUrl = 'https://korset.kz';

  // Local development URL
  static const String localUrl = 'https://korset.kz';

  // API Endpoints
  static const String auth = '/auth';
  static const String user = '/user';
  static const String register = '/api/register';

  // API Headers with optimization support
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Accept-Encoding': 'gzip, deflate',
    'User-Agent': 'KorsetApp/1.0.0',
  };

  // API Timeout Duration (in seconds)
  static const int timeoutDuration = 30;

  // Get appropriate base URL based on environment
  static String getBaseUrl({bool useSecure = false, bool useLocal = false}) {
    if (useLocal) return localUrl;
    if (useSecure) return secureBaseUrl;
    return baseUrl;
  }

  // Cache settings for backward compatibility
  static const Duration defaultCacheDuration = Duration(minutes: 5);
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 1);
}
