class AppConfig {
  AppConfig._();

  static late String flavor;
  static late bool enableLog;
  static late String baseUrl;

  static void init({
    required String flavor,
    required bool enableLog,
    required String baseUrl,
  }) {
    AppConfig.flavor = flavor;
    AppConfig.enableLog = enableLog;
    AppConfig.baseUrl = baseUrl;
  }
}
