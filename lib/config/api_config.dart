class ApiConfig {
  // Base URL for API
  static const String baseUrl =
      'http://127.0.0.1:8000'; // Replace with your actual API URL

  // API Endpoints
  static const String auth = '/auth';
  static const String user = '/user';
  static const String register = '/api/register';

  // API Headers
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // API Timeout Duration (in seconds)
  static const int timeoutDuration = 30;
}
