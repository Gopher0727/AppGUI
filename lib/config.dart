class AppConfig {
  AppConfig._();

  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://localhost:9000',
  );
}
