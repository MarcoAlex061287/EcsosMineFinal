import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:EcsosMine/config/app_config.dart';

class GeminiService {
  // Helper privado para configurar el modelo de Gemini
  static GenerativeModel _getModel({double temperature = 0.7}) {
    return GenerativeModel(
      model: 'gemini-pro',
      apiKey: AppConfig.geminiApiKey,
      generationConfig: GenerationConfig(
        temperature: temperature,
      ),
    );
  }

  /// Método estático para la Galería 3D Interactiva y Visor de Inspección
  static Future<String> generarRespuesta(String prompt) async {
    try {
      final model = _getModel(temperature: 0.7);
      final response = await model.generateContent([Content.text(prompt)]);
      return response.text?.trim() ?? "No se obtuvo respuesta del Tutor IA.";
    } catch (e) {
      debugPrint('Error en la consulta con Gemini: $e');
      return "Error al comunicarse con el Tutor IA: $e";
    }
  }

  /// Método para generar escenarios en formato JSON para evaluaciones
  static Future<Map<String, dynamic>?> generateScenario(int nivel) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-pro', 
        apiKey: AppConfig.geminiApiKey,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          temperature: 0.7,
        ),
      );

      final prompt = '''
Eres el docente evaluador de la asignatura "Fundamentos de la Minería I" del Instituto Superior Tecnológico Superarse.
Debes generar un caso práctico o escenario de evaluación en formato JSON basado ESTRICTAMENTE en las 4 Unidades del PEA de la asignatura:

- UNIDAD I (Generalidades): Tipos de minas, labores mineras (superficiales y subterráneas), terminología básica.
- UNIDAD II (Terminología específica): Recurso mineral vs Reserva mineral, Minerales de Mena y Ganga, terminología en labores.
- UNIDAD III (Ciclos mineros): Industria extractiva, ciclos de producción minera, secuencia productiva y equipos.
- UNIDAD IV (Métodos de explotación): Explotación a cielo abierto vs subterránea, selección del método, sistemas operativos, tipos de yacimientos en Ecuador.

Dificultad actual: Nivel $nivel de 5.
Semilla de aleatoriedad: ${DateTime.now().microsecondsSinceEpoch}

Devuelve ÚNICAMENTE un objeto JSON estricto con la siguiente estructura:
{
  "unit": "Unidad a la que pertenece el caso",
  "title": "Título corto del caso",
  "description": "Planteamiento técnico del problema en la operación minera",
  "option_a": "Primera alternativa",
  "option_b": "Segunda alternativa",
  "option_c": "Tercera alternativa",
  "correct_option": 0,
  "feedback": "Justificación técnica fundamentada según la teoría minera"
}
''';

      final response = await model.generateContent([Content.text(prompt)]);

      if (response.text != null && response.text!.isNotEmpty) {
        return jsonDecode(response.text!) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Error al generar escenario en IA - Gemini: $e');
    }
    return null;
  }

  /// Método para obtener retroalimentación cuando un estudiante comete un error
  static Future<String> getFeedback({
    required String role,
    required int nivel,
    required String tituloCaso,
    required String opcionSeleccionada,
    required String opcionCorrecta,
    String? feedbackLocal,
  }) async {
    try {
      final prompt = '''
Eres el "Profe Teo" del IST Superarse. El alumno cometió un error.
- Rol: $role
- Nivel Actual: $nivel
- Caso: "$tituloCaso"
- Selección incorrecta: "$opcionSeleccionada"
- Opción correcta: "$opcionCorrecta"

Genera una explicación breve, técnica y pedagógica (máximo 3 oraciones) de por qué falló y por qué la opción correcta es la adecuada.
''';

      final model = _getModel(temperature: 0.5);
      final response = await model.generateContent([Content.text(prompt)]);
      return response.text?.trim() ??
          feedbackLocal ??
          'La opción correcta según normativa técnica es: "$opcionCorrecta".';
    } catch (e) {
      debugPrint('Error al obtener retroalimentación de IA - Gemini: $e');
      return feedbackLocal ??
          'La opción correcta según normativa técnica es: "$opcionCorrecta".';
    }
  }
}