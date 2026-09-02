/// Configuración centralizada de la aplicación.
class AppConfig {
  /// Pasa la clave en compilación: --dart-define=GEMINI_API_KEY=tu_clave
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '.env',
  );
}
