class AppConstants {
  AppConstants._();

  static const String apiBaseUrl = 'http://localhost:8000/api/v1';
  static const Duration apiTimeout = Duration(seconds: 30);

  static const int maxQueryLength = 2000;

  static const Map<String, int> interestLimits = {
    'free': 0,
    'basic': 20,
    'premium': 200,
  };

  static const Map<String, int> questionLimits = {
    'free': 3,
    'basic': 100,
    'premium': 1000,
  };
}
