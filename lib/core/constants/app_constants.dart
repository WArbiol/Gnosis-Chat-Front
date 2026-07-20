import 'package:flutter/foundation.dart';

class AppConstants {
  AppConstants._();

  static const String appName = 'Gnosis Chat';

  static String get apiBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000/api/v1/';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000/api/v1/';
    }
    // Para testar no iPhone, precisamos usar o IP do Mac na rede Wi-Fi local
    return 'http://192.168.15.200:8000/api/v1/';
  }

  static const Duration apiTimeout = Duration(seconds: 30);

  static const int maxQueryLength = 2000;

  static const Map<String, int> questionLimits = {
    'free': 3,
    'basic': 100,
    'premium': 1000,
  };
}
