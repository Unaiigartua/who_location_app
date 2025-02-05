import 'package:flutter/foundation.dart';
import 'package:who_location_app/config/dio_config.dart';

enum Environment {
  dev,
  prod,
}

class AppConfig {
  static Environment environment = Environment.dev;

  // Add variable to store custom URL
  static String? _customApiBaseUrl;
  static String? _customWsBaseUrl;

  static String get apiBaseUrl {
    if (_customApiBaseUrl != null) {
      return _customApiBaseUrl!;
    }
    switch (environment) {
      case Environment.dev:
        return 'http://192.168.1.21:5001';
      case Environment.prod:
        return 'https://your-production-server.com';
    }
  }

  static String get wsBaseUrl {
    if (_customWsBaseUrl != null) {
      return _customWsBaseUrl!;
    }
    switch (environment) {
      case Environment.dev:
        return 'ws://192.168.1.21:5001';
      case Environment.prod:
        return 'wss://your-production-server.com';
    }
  }

  // Add method to update URLs
  static void updateBaseUrls(String ip, String port) {
    _customApiBaseUrl = 'http://$ip:$port';
    _customWsBaseUrl = 'ws://$ip:$port';
    debugPrint('Updated API URL: $_customApiBaseUrl');
    debugPrint('Updated WS URL: $_customWsBaseUrl');

    // Force recreate Dio instance
    DioConfig.createDio(() {});
  }

  // API endpoints
  static String get loginEndpoint => '/api/auth/login';
  static String get registerEndpoint => '/api/auth/register';
  static String get tasksEndpoint => '/api/tasks';
  static String get syncroniceTasksEndpoint => '/api/tasks/sync';
  static String get reportsEndpoint => '/api/reports';
  static String get wsEndpoint => '/ws';
  static String get deleteUserEndpoint => '/api/auth/users';
  static String get listReportsEndpoint => '/api/reports';
  static String get downloadReportEndpoint => '/api/reports';
  static String get deleteReportEndpoint => '/api/reports';
  static String get generateReportEndpoint => '/api/generate-report';
  // Debug configuration
  static bool get enableLogging => environment == Environment.dev;
}
