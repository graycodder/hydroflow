import 'package:firebase_core/firebase_core.dart';

enum Environment { staging, production }

class AppConfig {
  final Environment environment;
  final String appTitle;
  final String baseUrl; // Placeholder for future API usage
  final String firebaseDatabaseUrl;
  final FirebaseOptions firebaseOptions;

  AppConfig({
    required this.environment,
    required this.appTitle,
    required this.baseUrl,
    required this.firebaseDatabaseUrl,
    required this.firebaseOptions,
  });

  static AppConfig? _instance;

  static void setConfig(AppConfig config) {
    _instance = config;
  }

  static AppConfig get instance {
    if (_instance == null) {
      throw Exception('AppConfig not initialized. Call setConfig first.');
    }
    return _instance!;
  }

  bool get isStaging => environment == Environment.staging;
  bool get isProduction => environment == Environment.production;
}
