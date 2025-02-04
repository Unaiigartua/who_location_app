enum Environment {
  dev,
  prod,
}

class AppConfig {
  static Environment environment = Environment.dev;

  static String get apiBaseUrl {
    switch (environment) {
      case Environment.dev:
        return 'http://192.168.1.21:5001';
      case Environment.prod:
        return 'https://your-production-server.com';
    }
  }

  static String get wsBaseUrl {
    switch (environment) {
      case Environment.dev:
        return 'ws://192.168.1.21:5001';
      case Environment.prod:
        return 'wss://your-production-server.com';
    }
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
  // 用于调试的配置
  // Debug configuration
  static bool get enableLogging => environment == Environment.dev;
}
