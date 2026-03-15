/// Environment-specific configuration
enum Environment { dev, staging, prod }

class AppConfig {
  final Environment environment;
  final String baseUrl;
  final String appName;
  final bool enableLogging;

  const AppConfig._({
    required this.environment,
    required this.baseUrl,
    required this.appName,
    required this.enableLogging,
  });

  static const dev = AppConfig._(
    environment: Environment.dev,
    baseUrl: 'http://localhost:8080',
    appName: 'Hisobnoma Dev',
    enableLogging: true,
  );

  static const staging = AppConfig._(
    environment: Environment.staging,
    baseUrl: 'https://staging-api.hisobnoma.com',
    appName: 'Hisobnoma Staging',
    enableLogging: true,
  );

  static const prod = AppConfig._(
    environment: Environment.prod,
    baseUrl: 'https://api.hisobnoma.com',
    appName: 'Hisobnoma',
    enableLogging: false,
  );

  bool get isDev => environment == Environment.dev;
  bool get isStaging => environment == Environment.staging;
  bool get isProd => environment == Environment.prod;

  /// Current active configuration — set in main.dart
  static AppConfig _current = dev;
  static AppConfig get current => _current;
  static set current(AppConfig config) => _current = config;

  /// Initialize from environment string
  static AppConfig fromString(String env) {
    switch (env.toLowerCase()) {
      case 'prod':
      case 'production':
        return prod;
      case 'staging':
        return staging;
      default:
        return dev;
    }
  }
}
