import 'package:flutter/foundation.dart';

class AppConstants {
  AppConstants._();

  static const String appName = 'Pergunte à Gnosis';

  static String get apiBaseUrl {
    const envUrl = String.fromEnvironment('API_URL');
    if (envUrl.isNotEmpty) {
      return envUrl.endsWith('/') ? envUrl : '$envUrl/';
    }
    if (kReleaseMode) {
      return 'https://gnosis-chat-api-971574732695.southamerica-east1.run.app/api/v1/';
    }
    if (kIsWeb) {
      return 'http://localhost:8000/api/v1/';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000/api/v1/';
    }
    // Por padrão no iOS/iPhone, aponta para o backend remoto de produção no Cloud Run
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
