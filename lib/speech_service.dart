import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechService {
  final FlutterTts _flutterTts = FlutterTts();
  final stt.SpeechToText _speechToText = stt.SpeechToText();

  bool _isSpeaking = false;
  bool _isListening = false;

  bool get isSpeaking => _isSpeaking;
  bool get isListening => _isListening;

  SpeechService() {
    _initTts();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("es-EC");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.45);

    _flutterTts.setStartHandler(() => _isSpeaking = true);
    _flutterTts.setCompletionHandler(() => _isSpeaking = false);
    _flutterTts.setErrorHandler((_) => _isSpeaking = false);
  }

  /// Lee el escenario y opciones en voz alta
  Future<void> readScenario({
    required String title,
    required String description,
    required List<String> opciones,
  }) async {
    await stop();
    final textoCompleto = '''
    Caso: $title. 
    $description. 
    Opción A: ${opciones[0]}. 
    Opción B: ${opciones[1]}. 
    Opción C: ${opciones[2]}.
    ''';
    await _flutterTts.speak(textoCompleto);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
    _isSpeaking = false;
  }

  /// Escucha la voz del usuario para seleccionar opción
  Future<void> listenResponse({
    required Function(String text) onResult,
    required Function(bool listening) onStateChange,
  }) async {
    await stop();

    bool available = await _speechToText.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          _isListening = false;
          onStateChange(false);
        }
      },
      onError: (_) {
        _isListening = false;
        onStateChange(false);
      },
    );

    if (available) {
      _isListening = true;
      onStateChange(true);

      _speechToText.listen(
        listenOptions: stt.SpeechListenOptions(
          localeId: 'es_EC',
          listenFor: const Duration(seconds: 8),
        ),
        onResult: (result) {
          onResult(result.recognizedWords);
        },
      );
    }
  }

  Future<void> stopListening() async {
    await _speechToText.stop();
    _isListening = false;
  }

  void dispose() {
    _flutterTts.stop();
    _speechToText.stop();
  }
}