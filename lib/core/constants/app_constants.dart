class AppConstants {
  AppConstants._();

  static const String appName = 'Pergunte à Gnosis';

  static String get apiBaseUrl {
    const envUrl = String.fromEnvironment('API_URL');
    if (envUrl.isNotEmpty) {
      return envUrl.endsWith('/') ? envUrl : '$envUrl/';
    }
    // Por padrão em todas as plataformas (Web, iOS, Android), aponta para o backend deployado no Cloud Run
    return 'https://gnosis-chat-api-971574732695.southamerica-east1.run.app/api/v1/';
  }

  static const Duration apiTimeout = Duration(minutes: 5);

  static const int maxQueryLength = 2000;

  static const Map<String, int> questionLimits = {
    'free': 3,
    'basic': 100,
    'premium': 1000,
  };
}
